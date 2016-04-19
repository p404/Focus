#!/bin/bash
# Pablo Opazo
# Focus, an attempt to debug myself

function print_elapsed_time () {
	ELAPSED_TIME=$( echo -ne $final_date )
	echo -ne "Time elapsed $ELAPSED_TIME"
}

function log_entry () {
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

function focus_bootstrap_folder () {
	if [[ ! -d "$HOME/.focus" ]]; then
	    mkdir "$HOME/.focus"
	fi
}

function focus_bootstrap_files () {
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

function restrict_hosts () {
	while read site
	do
		host_template $site
	done < "$HOME/.focus/sites.txt"
	cp /etc/hosts "$HOME/.focus/clean_host_file"
    cat "$HOME/.focus/restricted_hosts_file" >> /etc/hosts 
}

function remove_site () {
	while read site 
	do
		if [[ $1 = $site ]];then
			sed -i "/$1/d" "$HOME/.focus/sites.txt" 
		fi
    done < "$HOME/.focus/sites.txt"
}

function add_site () {
	# TODO Multiple arguments
	while read site 
	do
		if [[ $1 = $site ]];then
			echo "$1 is already on the blacklist" >&2
			exit 1
		fi
    done < "$HOME/.focus/sites.txt" 
    
    echo $1 >> "$HOME/.focus/sites.txt"
    echo "$1 added to the blacklist" 
}

function print_help () {
	cat <<- DOC
	Usage: focus [options]
	    up                      Start the focus session
	    list                    List blacklisted sites
	    plot                    Displays a plot within the last 10 sessions
	    -a  "www.facebook.com"  Add sites to the blacklist      
	    -r  "www.facebook.com"  Remove sites from the blacklist
	DOC
}

function exit_callback () {
	cp "$HOME/.focus/clean_host_file" /etc/hosts  
}

trap 'print_elapsed_time; log_entry; exit_callback; exit 0' SIGINT SIGQUIT

# TODO Plotting
#function plot_log {
#	export width=`stty size | cut -d " " -f2`; export height=`stty size | cut -d " " -f1`-10; cat $HOME/.focus/log.csv | sed "s/ /T/" | gnuplot -e "set terminal dumb $width $height; set autoscale; set title \"Weekly productivity plot\"; set xdata time; set timefmt \"%Y-%m-%dT%H:%M:%S\"; set xlabel \"time\"; set ylabel \"productivity\"; plot '-' using 1:2 with lines"
#}

# Entry point

if [[ $EUID != 0 ]]; then
    echo "Please run focus as root" >&2
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

	elif [[ $1 = 'list' ]]; then
		echo 'List of blacklisted sites:'
		cat "$HOME/.focus/sites.txt"
		exit 0
		
	elif [[ $# = 0 ]]; then
		echo "Please input something" >&2
		print_help
		exit 1		
	else
		while getopts ":a:r:h" opt; do
		  case $opt in
		    a)
		      # Ugly TODO: Send an array to the function?
			  for value in $OPTARG
			  do
			  		add_site $value 	 
			  done
		      ;;
		    r)
			  # Ugly TODO: Send an array to the function?
			  for value in $OPTARG
			  do
			  		remove_site $value 	 
			  done
		      ;;
		     h)
			  print_help
			  exit 0
			  ;;
		    \?)
		      echo "Invalid option: -$OPTARG" >&2
		      print_help
		      exit 1
		      ;;
		    :)
		      echo "Option -$OPTARG requires an argument" >&2
		      print_help
		      exit 1
		      ;;
		  esac
	
		done
	fi					
fi
