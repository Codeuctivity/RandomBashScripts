#!/bin/bash
OLD="<title></title>"
DPATH="/home/htpc/Videos/Serien/Tele-Akademie"

find "$DPATH" -name "*.nfo" -type f -print0 | while read -d $'\0' file
do	
	#read -n 1 -s
	VDRINFO=$(basename "$file")
  	if [ "$VDRINFO" == "tvshow.nfo" ]; then
  		echo "excluded tvshow.nfo"
 	else

        #http://stackoverflow.com/questions/12456031/string-variable-in-a-regular-expression-in-bash
	# parsing episode out of filename 
	# format "Serie - [Date] - episodename.nfo"
	#CorrectedEpisodeName="<title>$(echo "$VDRINFO done" | sed -n 's/.*\] - \(.*\)\.nfo.*/\1/p')</title>"
	# format "Serie - nxmm - Episode.nfo"
	# CorrectedEpisodeName="<title>$(echo "$VDRINFO done" | sed -n 's/.*[0-9]x[0-9][0-9] - \(.*\)\.nfo.*/\1/p')</title>"
#https://forum.ubuntuusers.de/topic/problem-mit-sed-3/
	sed -i "s#$OLD#$CorrectedEpisodeName#g" "$file"
	echo $CorrectedEpisodeName
	echo "$VDRINFO done"
	fi
done

