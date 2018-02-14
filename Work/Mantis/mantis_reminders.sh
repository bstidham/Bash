script_dir=$(dirname "${BASH_SOURCE[0]}");
while true
do
	clear;
	mr_tmp_mtime=0;
	mr_tmp_agemin=30;
	if [ -f "${script_dir}/mr.tmp" ]; 
	then 
		mr_tmp_mtime=$(date +"%Y-%m-%d %H:%M" -d "$(stat -c %y "${script_dir}/mr.tmp")");
		mr_tmp_agemin=$(((`date +%s`-`date +%s -d "$mr_tmp_mtime"`)/30));
	fi
	if [ $mr_tmp_agemin -ge 30 ]; 
	then 
		echo "refreshing reminders file";
		sqlcmd -S SQLPROD01 -E -d CTWP_Prod -h-1 -m 1 -s "|" -Q "$(cat "${script_dir}/mantis_reminders.sql")" > "${script_dir}/mr.tmp";
	fi
	mr_tmp_mtime=$(date +"%Y-%m-%d %H:%M" -d "$(stat -c %y "${script_dir}/mr.tmp")");
	mr_tmp_nextrefreshtime=$(date +"%H:%M" -d "${mr_tmp_mtime}:00 -500+30 minutes");
	clear;
	echo -e "\E[1;32m Mantis - Reminders\E[0m (${mr_tmp_mtime}-${mr_tmp_nextrefreshtime})";
	cat "${script_dir}/mr.tmp" | sed 's/[ ]\{2,\}//g' | awk  -F"|" '{sub(/\r/,""); printf "%1$c[1;94m %9$2d %3$s (%4$s) [%2$s]: %5$s %1$c[0m \n %1$c[1;100m   - %6$s (%8$s|%10$s): %1$c[0m %7$s \n", 27, $1, $2, $3, $4, $5, $6, $7, -(NR - 11), $8}'
	while [ $mr_tmp_agemin -lt 30 ];
	do 
		mr_tmp_agemin=$(((`date +%s`-`date +%s -d "$mr_tmp_mtime"`)/30));
		#sleep 1m;
		read -t 30 cmd;
		case $cmd in
			[Rr]* )
				mr_tmp_agemin=30;
				rm "${script_dir}/mr.tmp";
				;;
		esac
	done
	sleep 2s;
done
