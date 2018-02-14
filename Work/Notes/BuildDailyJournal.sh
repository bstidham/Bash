#!/bin/bash

#variables
program_name=$(basename "$0" | sed 's/.sh//g');
script_dir=$(dirname "$0");

#parms
analysis_date=$(date +"%Y-%m-%d");
verbosity=1;
args=("$@");
for (( i = 0; i < $#; i++ )); do
	arg="${args[$i]}";
	next_arg="${args[$(($i+1))]}";
	case "$arg" in
		"-ad"|"--analysis_date" )
			((i++));
			analysis_date="$next_arg";;
		"-v"|"--verbosity" )
			((i++));
			verbosity="$next_arg";;
	esac
done
analysis_date=$(date -d "$analysis_date" +"%Y-%m-%d");
verbosity=1;
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Analysis Date: %s\n" "$program_name" "$analysis_date"; fi 
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Verbosity: %s\n" "$program_name" "$verbosity"; fi 

#trap catch
function trap_fn() {
	if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Removing temp directory\n" "$program_name"; fi
	rm -r "$temp_dir";
}
trap trap_fn exit;

#make temp folders
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Preparing temporary folder\n" "$program_name"; fi
TMPDIR="${TMPDIR:-/tmp/}";
temp_dir=$(mktemp -d "${TMPDIR:-/tmp/}${program_name}.XXXXXXXXXX");

#variables
base_dir="BASE_DIR HERE";
tsk_file="RECURRING TASKCOASCH FILE HERE";
xsl_extractnoteheaders_file="$script_dir/tskExtractNoteHeaders.xsl";
tmp_db="$temp_dir/app.db";
tmp_taskheaders_sql="$temp_dir/taskheaders.sql";
tmp_taskheaders_md="$temp_dir/taskheaders.md";
notefile_today="$(date -d "$analysis_date" +"%Y%m%d - %a.md")";
notefile_last="$( find "$base_dir" -type f -iname \?\?\?\?\?\?\?\?\ -\ \?\?\?.md -printf "%f\n" | grep -v "$notefile_today" | sort -r | grep -n '' | grep '^1:' | sed 's/^1://')";

#print variables
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "tsk_file" "$tsk_file"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "xsl_extractnoteheaders_file" "$xsl_extractnoteheaders_file"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "notefile_today" "$notefile_today"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "notefile_last" "$notefile_last"; fi

printf "CREATE TABLE task_header (TaskID VARCHAR(40) NOT NULL, Subject VARCHAR(200) NOT NULL, DueDate DATETIME NOT NULL, Description VARCHAR(8000) NOT NULL);\n" > "$tmp_taskheaders_sql";
xsltproc -stringparam analysis_date "$analysis_date" "$xsl_extractnoteheaders_file" "$tsk_file" >> "$tmp_taskheaders_sql";
printf "SELECT TRIM(TRIM(th.Description, CHAR(13) || CHAR(10)), CHAR(10)) || CHAR(13) || CHAR(10) Description
FROM task_header th
WHERE th.DueDate < date('$analysis_date', '+1 day')
ORDER BY th.DueDate, th.Subject\n" "$analysis_date" >> "$tmp_taskheaders_sql";
sqlite3 "$tmp_db" < "$tmp_taskheaders_sql" > "$tmp_taskheaders_md";
taskheaders="$(cat "$tmp_taskheaders_md" | tr '\n' "\\n" | tr '\r' "\\r" | tr '\\' "\\\\")";

cat "$base_dir/$notefile_last" | sed 's/TSTime: [0-9.]*/TSTime: 0/g' | sed 's/* \[X\] break/* [ ] break/g' | sed -e '/# Recurring/,/# Monitoring/c\# Recurring%recurring%\r\n# Monitoring' > "$temp_dir/notefile_last.md";
pwdb="$(pwd)";
cd "$temp_dir";
awk '{print >out}; /%recurring%/{out="02.md"}' out="01t.md" "notefile_last.md";
date -d "$analysis_date" +"%Y%m%d - %a" > "01.md";
tail -n +2 "01t.md" | sed 's/%recurring%//' >> "01.md";
cat "01.md" "taskheaders.md" "02.md" > notefile_today.md;
cd "$pwdb";

#backup
if [ -e "$base_dir/$notefile_today" ]; then
	if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Backing up old today file\n" "$program_name"; fi
	notefile_today_backup="${notefile_today}.$(date +"%Y%m%d%H%M%S").bak";
	mv "$base_dir/$notefile_today" "$base_dir/$notefile_today_backup";
fi
cp "$temp_dir/notefile_today.md" "$base_dir/$notefile_today";

# cp -r "$temp_dir" "/home/bstidham/bstidham/Desktop";
