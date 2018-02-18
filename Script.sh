#!/bin/bash

# parms
analysis_date=$(date +"%Y%m%d");
verbosity=1;
debug_copy_temp="false";
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
        "-dct"|"--debug_copy_temp" )
            ((i++));
            debug_copy_temp="$next_arg";;
    esac
done
analysis_date=$(date -d "$analysis_date" +"%Y%m%d");
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Analysis Date: %s\n" "$program_name" "$analysis_date"; fi 
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Verbosity: %s\n" "$program_name" "$verbosity"; fi 
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Debug Copy Temp: %s\n" "$program_name" "$debug_copy_temp"; fi 

# variables
program_name=$(basename "$0" | sed 's/.sh//g');
script_dir=$(dirname "$0");


#trap catch
function trap_fn() {
  if [ -d "$debug_copy_temp" ]; then 
    if [[ $verbosity -ge 1 ]]; then printf "DEBUG: %s: Copying temp folder to \"%s\"\n" "$program_name" "$debug_copy_temp"; fi
    cp -r "$temp_dir" "$debug_copy_temp";
  fi
    if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Removing temp directory\n" "$program_name"; fi
    rm -r "$temp_dir";
}
trap trap_fn exit;

#make temp folders
if [[ $verbosity -ge 1 ]]; then printf "INFO: %s: Preparing temporary folder\n" "$program_name"; fi
TMPDIR="${TMPDIR:-/tmp/}";
temp_dir=$(mktemp -d "${TMPDIR:-/tmp/}${program_name}.XXXXXXXXXX");

# section 1
