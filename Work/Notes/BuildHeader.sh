#!/bin/bash

# variables 1
script_dir=$(dirname "${BASH_SOURCE[0]}");
home_dir=$(echo ~);
projectid_left_0_padding=7;

# arguments
projectid=$(echo "$1" | sed 's/–/-/g' | sed -rn 's/^[^1-9]*([0-9]+).*/\1/p');
projectid_padded=$(printf "%0${projectid_left_0_padding}d" "$projectid");
projectsubject=$(echo "$1" | sed -rn 's/^[^1-9]*[0-9]+ *[:-] *(.*)/\1/p');

# tsproject
IFSB="$IFS"; IFS=',';
for a in $(echo "$projectsubject" | cut -d'-' -f1); do
  search_arg=" - ${a}-$(echo "$projectsubject" | cut -d'-' -f2-)";
  tsproject=$(sqlite3 -noheader "${script_dir}/Notes.db" \
            "SELECT IFNULL(NULLIF(TSProject, '') || ', ', '') || IFNULL(NULLIF(stpm.Project, ''), '? • ?') Project 
             FROM (SELECT '${search_arg}' Summary
                        , '${tsproject}' TSProject
                        , 'A' ASC_Active) p 
             LEFT JOIN SummaryToProjectMap stpm 
                 ON p.Summary LIKE stpm.SummaryMask
                 AND stpm.ActivityStatusCode = p.ASC_Active;");
done
IFS="$IFSB";
printf "INFO: %s: %s: %s\n" "$program_name" "tsproject" "$tsproject";

# variables 2
# $home_dir (/home/username)
# $script_dir 
# $projectid
# $projectid_padded
# $projectsubject
# $tsproject (timesheet project)
project_fs_folder="PROJECT_FS_FOLDER HERE";
project_ssms_folder="PROJECT_SSMS_FOLDER HERE";
project_ssms_template_name="PROJECT_SSMS_TEMPLATE_NAME HERE";
project_svn_folder="PROJECT_SVN_FOLDER HERE";
header="# $projectid_padded - $projectsubject\r\n\
[Project](PROJECT TRACKING URL HERE)\r\n\
[Project Folder](file://PROJECT_FS_FOLDER_FWDSSLASH HERE)\r\n\
[Progress](file://PROJECT_FS_FOLDER_FWDSSLASH HERE/Progress.md)\r\n\
[Event Log](file://PROJECT_FS_FOLDER_FWDSSLASH HERE/Event Log.md)\r\n\
[Design](file://PROJECT_FS_FOLDER_FWDSSLASH HERE/Design.md)\r\n\
[SVN](SVN_URL HERE)\r\n\
TSTime: 0\r\n\
TSProject: $tsproject\r\n\
TSStartDate: ?\r\n\
Requester: ?";

# print variables
printf "INFO: %s: %s: %s\n" "$program_name" "projectid_left_0_padding" "$projectid_left_0_padding";
printf "INFO: %s: %s: %s\n" "$program_name" "projectid" "$projectid";
printf "INFO: %s: %s: %s\n" "$program_name" "projectid_padded" "$projectid_padded";
printf "INFO: %s: %s: %s\n" "$program_name" "projectsubject" "$projectsubject";
printf "INFO: %s: %s: %s\n" "$program_name" "project_fs_folder" "$project_fs_folder";
printf "INFO: %s: %s: %s\n" "$program_name" "project_ssms_folder" "$project_ssms_folder";
printf "INFO: %s: %s: %s\n" "$program_name" "project_ssms_template_name" "$project_ssms_template_name";
printf "INFO: %s: %s: %s\n" "$program_name" "project_svn_folder" "$project_svn_folder";
printf "INFO: %s: %s: %s\n" "$program_name" "header" "$header";

# copy to clipboard
echo -e $header | sed 's/\%1/*/g' | sed 's/\%2/-/g' | sed 's/\%3/+/g' > /dev/clipboard;

# create folders and template files
if [[ "$tsproject" != "? • ?" ]]; then
  if [ ! -d "$project_fs_folder" ]; then
    mkdir "$project_fs_folder";
    echo "$project_fs_folder created";
  fi
  if [ ! -e "$project_fs_folder/Event Log.md" ]; then
    cp "$script_dir/templates/Event Log.template" "$project_fs_folder/Event Log.md";
    echo "$project_fs_folder/Event Log.md created";
  fi
  if [ ! -e "$project_fs_folder/Design.md" ]; then
    cp "$script_dir/templates/Design.template" "$project_fs_folder/Design.md";
    echo "$project_fs_folder/Design.md created";
  fi
  if [ ! -e "$project_fs_folder/Progress.md" ]; then
    cp "$script_dir/templates/Progress - Development.template" "$project_fs_folder/Progress.md";
    echo "$project_fs_folder/Progress.md created";
  fi
  if [ ! -d "$project_svn_folder" ]; then
    mkdir "$project_svn_folder";
    echo "$project_svn_folder created";
  fi
  if [ ! -d "$project_ssms_folder" ]; then
      if [[ ! -d "$project_ssms_folder" ]]; then
          mkdir -p "$project_ssms_folder";
      fi
      project_ssms_folder_name=$(echo "$project_ssms_folder" | rev | cut -d'/' -f1 | rev);
      cp -r "$script_dir/templates/$project_ssms_template_name" "$project_ssms_folder/$project_ssms_folder_name";
      mv "$project_ssms_folder/$project_ssms_folder_name/$project_ssms_template_name.ssmssln" "$project_ssms_folder/$project_ssms_folder_name/$project_ssms_folder_name.ssmssln";
      chmod -R 750 "$project_ssms_folder";
      echo "$project_ssms_folder created";
  fi
fi
