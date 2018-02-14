#!/bin/bash

#variables
program_name=$(basename "$0" | sed 's/.sh//g');
script_dir=$(dirname "$0");

#parms
analysis_date=$(date +"%Y%m%d");
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
analysis_date=$(date -d "$analysis_date" +"%Y%m%d");
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
notes_folder="/home/bstidham/svn/bstidham/Notes/PFI/Daily Journal";
note_date_sun=$(date -d "$analysis_date - $(date -d "$analysis_date" +"%w") days" +"%Y%m%d");
note_date_mon=$(date -d "$note_date_sun + 1 days" +"%Y%m%d");
note_date_tue=$(date -d "$note_date_sun + 2 days" +"%Y%m%d");
note_date_wed=$(date -d "$note_date_sun + 3 days" +"%Y%m%d");
note_date_thu=$(date -d "$note_date_sun + 4 days" +"%Y%m%d");
note_date_fri=$(date -d "$note_date_sun + 5 days" +"%Y%m%d");
note_date_sat=$(date -d "$note_date_sun + 6 days" +"%Y%m%d");

note_src_file_sun="$note_date_sun - Sun.md"
note_title_sun="$note_date_sun - Sun"
note_src_file_mon="$note_date_mon - Mon.md"
note_title_mon="$note_date_mon - Mon"
note_src_file_tue="$note_date_tue - Tue.md"
note_title_tue="$note_date_tue - Tue"
note_src_file_wed="$note_date_wed - Wed.md"
note_title_wed="$note_date_wed - Wed"
note_src_file_thu="$note_date_thu - Thu.md"
note_title_thu="$note_date_thu - Thu"
note_src_file_fri="$note_date_fri - Fri.md"
note_title_fri="$note_date_fri - Fri"
note_src_file_sat="$note_date_sat - Sat.md"
note_title_sat="$note_date_sat - Sat"

temp_sun="$temp_dir/sun.md";
temp_mon="$temp_dir/mon.md";
temp_tue="$temp_dir/tue.md";
temp_wed="$temp_dir/wed.md";
temp_thu="$temp_dir/thu.md";
temp_fri="$temp_dir/fri.md";
temp_sat="$temp_dir/sat.md";

temp_text="$temp_dir/text.txt"

temp_db="$temp_dir/tmp.db";
temp_sql="$temp_dir/tmp.sql";
temp_results="$temp_dir/results.txt";

#print variables
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "temp_dir" "$temp_dir"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "analysis_date" "$analysis_date"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "note_date_sun" "$note_date_sun"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "note_date_mon" "$note_date_mon"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "note_date_tue" "$note_date_tue"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "note_date_wed" "$note_date_wed"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "note_date_thu" "$note_date_thu"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "note_date_fri" "$note_date_fri"; fi
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: %s: %s\n" "$program_name" "note_date_sat" "$note_date_sat"; fi

#copy file to temp
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Copying Notes files to temp\n" "$program_name"; fi
cat "$notes_folder/$note_src_file_sun" | tr -d '\r' > "$temp_sun";
cat "$notes_folder/$note_src_file_mon" | tr -d '\r' > "$temp_mon";
cat "$notes_folder/$note_src_file_tue" | tr -d '\r' > "$temp_tue";
cat "$notes_folder/$note_src_file_wed" | tr -d '\r' > "$temp_wed";
cat "$notes_folder/$note_src_file_thu" | tr -d '\r' > "$temp_thu";
cat "$notes_folder/$note_src_file_fri" | tr -d '\r' > "$temp_fri";
cat "$notes_folder/$note_src_file_sat" | tr -d '\r' > "$temp_sat";

i=-1;
note_titles=("$note_title_sun" "$note_title_mon" "$note_title_tue" "$note_title_wed" "$note_title_thu" "$note_title_fri" "$note_title_sat" );
for tmp_note in "$temp_sun" "$temp_mon" "$temp_tue" "$temp_wed" "$temp_thu" "$temp_fri" "$temp_sat"; do
	i=$(($i+1));
	echo "$tmp_note";
	printf "%s\n" "${note_titles[$i]}" >> "$temp_text";
	cat "$tmp_note" | grep -E '^(#+ M[0-9]|TSTime:|TSProject)' | sed 's/^#\+ //g' >> "$temp_text";
done

#extract page titles and headers
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Extracting page titles and headers\n" "$program_name"; fi
printf "CREATE TABLE Preload (PreloadID INTEGER PRIMARY KEY AUTOINCREMENT, LN INTEGER NOT NULL, T TEXT NOT NULL, V TEXT NOT NULL);\n" > "$temp_sql";
printf "BEGIN TRANSACTION;\n" >> "$temp_sql";
cat "$temp_text" | grep -Pna --text -e "(^[0-9]{8} - [a-zA-Z]{3}|^M[0-9]{7} - .+|^TSTime:.+|^TSProject:.+)" | awk -F ':' '{ printf "INSERT INTO Preload (LN, T, V) VALUES (%s, TRIM(\47%s\47), TRIM(\47%s\47));\n", $1, $2, $3 }' >> "$temp_sql";
printf "COMMIT;\nBEGIN TRANSACTION;\n" >> "$temp_sql";
printf "CREATE TABLE DayHeader (DayHeaderID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, Title TEXT NOT NULL, DDD TEXT NOT NULL, LNFloor INTEGER NOT NULL, LNCeiling INTEGER NULL);\n" >> "$temp_sql";
printf "WITH C1 AS (
	SELECT * 
	FROM Preload d
	WHERE d.T GLOB '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9] - [a-zA-z][a-z][a-z]'
)
INSERT INTO DayHeader (LNFloor, Title, DDD, LNCeiling)
SELECT c1.LN LNFloor
	 , c1.T
	 , SUBSTR(c1.T, -3, 3)
	 , (
	       SELECT MIN(c2.LN)
		   FROM C1 c2
		   WHERE c2.LN > c1.LN
	   ) LNCeiling
FROM C1 c1;\n" >> "$temp_sql";
printf "
CREATE TABLE Entry (
      EntryID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT
    , DayHeaderID INTEGER NOT NULL
    , DDD TEXT NOT NULL
    , H1PreloadID INTEGER NOT NULL
    , H1 TEXT NOT NULL
    , TSTimePreloadID DECIMAL(9,2) NOT NULL
    , TSTime NUMERIC NOT NULL
    , TSProjPreloadID INTEGER NOT NULL
    , TSProject TEXT NOT NULL);
INSERT INTO Entry (DayHeaderID, DDD, H1PreloadID, H1, TSTimePreloadID, TSTime, TSPROJPreloadID, TSProject)
SELECT dh.DayHeaderID, dh.DDD, h1.PreloadID, h1.T, tstime.PreloadID, tstime.V, tsproj.PreloadID, tsproj.V
FROM DayHeader dh
JOIN Preload h1
	ON  h1.LN >= dh.LNFloor
	AND (dh.LNCeiling IS NULL OR h1.LN < dh.LNCeiling)
	AND h1.T GLOB 'M[0-9][0-9][0-9][0-9][0-9][0-9][0-9] - *'
JOIN Preload tstime 
	ON  tstime.T = 'TSTime'
	AND tstime.PreloadID = h1.PreloadID + 1
	AND tstime.V <> '0'
JOIN Preload tsproj 
	ON  tsproj.T = 'TSProject'
	AND tsproj.PreloadID = tstime.PreloadID + 1
;\n" >> "$temp_sql";
printf "COMMIT;\n" >> "$temp_sql";
printf "SELECT '{\"TSProject\": \"' ||
       d2.TSProject ||
	   '\", \"Days\": {' ||
	   d2.Days ||
	   '}}' Project
FROM (
	SELECT d1.TSProject
		 , GROUP_CONCAT('\"' || d1.DDD || '\": {\"TSTotalTime\": ' || d1.TSTotalTime || ', \"H1s\": \"' || d1.H1s || '\"}', ', ') Days
	FROM (
		SELECT e.TSProject
			 , e.DayHeaderID
			 , e.DDD
			 , SUM(e.TSTime) TSTotalTime
			 , GROUP_CONCAT(e.H1, ', ') H1s
		FROM Entry e
		GROUP BY e.TSProject, e.DDD
	) d1
	GROUP BY d1.TSProject
	ORDER BY d1.DayHeaderID
) d2
\n" >> "$temp_sql";
printf "{\"TSProjects\": [\n" >> "$temp_results";
rn=0;
sqlite3 "$temp_db" < "$temp_sql" | while read TSProject; do >> "$temp_results";
	rn=$((rn+1));
	if [[ $rn > 1 ]]; then
		printf ", " >> "$temp_results";
	fi
	printf "$TSProject\n" >> "$temp_results";
done
printf "]\n" >> "$temp_results";
printf ",\"Stats\": {" >> "$temp_results";
printf "SELECT '\"Days\": {' || GROUP_CONCAT('\"' || e.DDD || '\": {\"TSTotalTime\": ' || e.TSTotalTime || '}', ',') || '}' || ', \"TSTotalTime\": ' || (SELECT SUM(e2.TSTime) FROM Entry e2) || '}}\n'
FROM (SELECT e.DDD
	       , SUM(e.TSTime) TSTotalTime
	  FROM Entry e
	  GROUP BY e.DDD) e
;\n" >> "$temp_dir/tmp2.sql";
sqlite3 "$temp_db" < "$temp_dir/tmp2.sql" >> "$temp_results";
cp -r "$temp_dir" "bstidham/Desktop";
