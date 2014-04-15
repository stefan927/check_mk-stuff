for socket in $(ls /var/run/php5-fpm-*.socket); do
	ps_socket=$(echo $socket | sed -e 'sX/X Xg' | awk '{print $3}' | sed -e 's/php5-fpm-//g' -e 's/.socket//g')
	ps=$(ps aux | grep "${ps_socket}" | grep -v grep | wc -l)
	if [ $ps -gt 0 ]; then
		# fetch status as json via cgi
		status=$(\
			SCRIPT_NAME=/php-status \
			SCRIPT_FILENAME=/php-status \
			QUERY_STRING=json \
			REQUEST_METHOD=GET \
			cgi-fcgi -bind -connect $socket \
		)

		# create readable json format
		json_readable=$(\
		echo "$status" \
		| sed -e '1,4d' -e 's/[{}]/''/g' \
		| awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' \
		| sed -e 's/"//g' -e 's/ /_/g' \
		)

		Pool=$(echo "$json_readable" | grep "^pool:")
		Pool=${Pool//pool:}
		Uptime=$(echo "$json_readable" | grep "^start_since:")
		Uptime=${Uptime//start_since:}
		AcceptedConn=$(echo "$json_readable" | grep "^accepted_conn:")
		AcceptedConn=${AcceptedConn//accepted_conn:}
		ActiveProcesses=$(echo "$json_readable" | grep "^active_processes:")
		ActiveProcesses=${ActiveProcesses//active_processes:}
		TotalProcesses=$(echo "$json_readable" | grep "^total_processes:")
		TotalProcesses=${TotalProcesses//total_processes:}
		IdleProcesses=$(echo "$json_readable" | grep "^idle_processes:")
		IdleProcesses=${IdleProcesses//idle_processes:}
		MaxActiveProcesses=$(echo "$json_readable" | grep "^max_active_processes:")
		MaxActiveProcesses=${MaxActiveProcesses//max_active_processes:}
		MaxChildrenReached=$(echo "$json_readable" | grep "^max_children_reached:")
		MaxChildrenReached=${MaxChildrenReached//max_children_reached:}
		ListenQueue=$(echo "$json_readable" | grep "^listen_queue:")
		ListenQueue=${ListenQueue//listen_queue:}
		ListenQueueLen=$(echo "$json_readable" | grep "^listen_queue_len:")
		ListenQueueLen=${ListenQueueLen//listen_queue_len:}
		MaxListenQueue=$(echo "$json_readable" | grep "^max_listen_queue:")
		MaxListenQueue=${MaxListenQueue//max_listen_queue:}
	
		Output="0 php_${Pool} Idle=${IdleProcesses};|Busy=${ActiveProcesses};|MaxProcesses=${MaxActiveProcesses};|MaxProcessesReach=${MaxChildrenReached};|Queue=${ListenQueue};|MaxQueueReach=${MaxListenQueue};|QueueLen=${ListenQueueLen} OK - Busy/Idle ${ActiveProcesses}/${IdleProcesses} (max: ${MaxActiveProcesses}, reached: ${MaxChildrenReached}), Queue ${ListenQueue} (len: ${ListenQueueLen})"
		echo $Output
	else
                Uptime="0"
                AcceptedConn="0"
                ActiveProcesses="0"
                TotalProcesses="0"
                IdleProcesses="0"
                MaxActiveProcesses="0"
                MaxChildrenReached="0"
                ListenQueue="0"
                ListenQueueLen="0"
                MaxListenQueue="0"

                Output="0 php_${ps_socket} Idle=${IdleProcesses};|Busy=${ActiveProcesses};|MaxProcesses=${MaxActiveProcesses};|MaxProcessesReach=${MaxChildrenReached};|Queue=${ListenQueue};|MaxQueueReach=${MaxListenQueue};|QueueLen=${ListenQueueLen} OK - Busy/Idle ${ActiveProcesses}/${IdleProcesses} (max: ${MaxActiveProcesses}, reached: ${MaxChildrenReached}), Queue ${ListenQueue} (len: ${ListenQueueLen})"
                echo $Output
	fi
done
