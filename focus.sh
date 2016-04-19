#!/bin/bash
# Pablo Opazo
# Focus, an attempt to debug myself

function print_elapsed_time {
	ELAPSED_TIME=$( echo -ne $final_date )
	echo -ne "Time elapsed $ELAPSED_TIME"
}

function log_entry {
	OF="$HOME/.focus/log.csv"
	echo 'How productive was the session? (0-5)'
	read PR
	DATE=$(date +"%d/%m/%Y")
	TIME=$(date +"%H:%M:%S")
	DOW=$(date +"%u")
	cat  <<- EOF >> $OF
	$PR,$DATE,$DOW,$TIME,$ELAPSED_TIME
	EOF

	echo "Exiting, Bye!"
}

function focus_bootstrap_folder {
	if [[ ! -d "$HOME/.focus" ]]; then
	    mkdir "$HOME/.focus"
	fi
}

function focus_bootstrap_files {
	focus_bootstrap_folder

	if [[ ! -f "$HOME/.focus/log.csv" ]];then
		touch "$HOME/.focus/log.csv"
	fi

	if [[ ! -f "$HOME/.focus/sites.txt" ]]; then
		touch "$HOME/.focus/sites.txt"
	fi
}

function host_template () 
{
	OF="$HOME/.focus/restricted_hosts_file"
	touch $OF
	if [[ $1 =~ 'www.' ]]; then 
		cat  <<- EOF >> $OF

		127.0.0.1   $1
		::0         $1
		127.0.0.1   ${1//'www.'}
		::0         ${1//'www.'}
		EOF

	else
		cat  <<- EOF >> $OF

		127.0.0.1   $1
		::0         $1
		EOF

	fi 
}

# TODO Plotting
#function plot_log {
#	export width=`stty size | cut -d " " -f2`; export height=`stty size | cut -d " " -f1`-10; cat $HOME/.focus/log.csv | sed "s/ /T/" | gnuplot -e "set terminal dumb $width $height; set autoscale; set title \"Weekly productivity plot\"; set xdata time; set timefmt \"%Y-%m-%dT%H:%M:%S\"; set xlabel \"time\"; set ylabel \"productivity\"; plot '-' using 1:2 with lines"
#}

function restrict_hosts {
	while read site
	do
		host_template $site
	done < "$HOME/.focus/sites.txt"
	cp /etc/hosts "$HOME/.focus/clean_host_file"
    cat "$HOME/.focus/restricted_hosts_file" >> /etc/hosts 
}

function exit_callback {
	cp "$HOME/.focus/clean_host_file" /etc/hosts  
}

trap 'print_elapsed_time; log_entry; exit_callback; exit 0' SIGINT SIGQUIT

# Entry point

if [[ $EUID != 0 ]]; then
    echo "Please run focus as root"
    exit 1
else
	if [[ $1 = 'up' ]];then
		echo 'Starting focus'
		focus_bootstrap_files
		restrict_hosts
		SUDO_USER=$(who am i | awk '{print $1}')
		#sudo -u $SUDO_USER google-chrome 'https://www.brain.fm/app#!/player/35' > /dev/null
		firefox-trunk -private-window 'https://www.brain.fm/app#!/player/35' > /dev/null 2>&1 &
		pkill 'skype'
			
		echo "Time on focus"
		date1=$(date +%s) 
		while true; do 
		    final_date="$(date -u --date @$((`date +%s` - $date1)) +%H:%M:%S)\r";
		    echo -ne $final_date
		done
		
	elif [[ $# = 0 ]]; then
		echo "Please input something"		
	else
		while getopts ":a:r:" opt; do
		  case $opt in
		    a)
		      echo "-a was triggered, Parameter: $OPTARG" >&2
		      ;;
		    r)
		      echo "-r was triggered, Parameter: $OPTARG" >&2
		      ;;
		    \?)
		      echo "Invalid option: -$OPTARG" >&2
		      exit 1
		      ;;
		    :)
		      echo "Option -$OPTARG requires an argument." >&2
		      exit 1
		      ;;
		  esac
	
		done
	fi					
fi
