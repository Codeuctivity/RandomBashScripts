#!/bin/bash

#this script recursive rename recordings created by vdr (001.vdr ... info.vdr) to an xbmc/Kodi format (seriename - episodetile.ts)
VLC="/usr/bin/cvlc1"
VDRREC="/home/htpc/Videos/Sortieren/SerieVdr"
CONVERTEDTARGETDIRECTORY="/home/htpc/Videos/Sortieren/SerienTs"
PROBLEMLOGFILE="/home/htpc/Videos/Sortieren/renamlog.log"
CHECKRUNNING=$(/bin/pidof -x $0|wc -w)

	if [ $CHECKRUNNING -gt 2 ];then
		echo "$CHECKRUNNING"
		echo "scanvdr already running ..."
		exit 0
	fi


	if [ -n "$1" ];then
		echo "  Usage:"
		exit 0
	fi


	for i in $(find $VDRREC -name "info.vdr" -type f)
	do
	VDRDIR=$(dirname $i)
VDRINFO=$(basename $i)
	cd $VDRDIR

#use  "iconv -f ISO-8859-1 -t UTF-8 <file>"  to convert encoding (open7x0 uses ISO-8859-1 in my old version), you can use "cat" instead on your utf8 system

	if [ ! -f "001.vdr" ];then
		echo "$VDRDIR Seems to be broken (no 001.vdr found)" | tee -a "$PROBLEMLOGFILE"
	else
		if [ -f $VDRINFO ];then
		AIRED=$(basename $VDRDIR | awk -F'.' '{print $1}')
		DAUER=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^E " | awk '{print $4/60}' | awk -F'.' '{print $1}')
		TITEL=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^T " | sed "s/^T //")	
		INHALT=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^D " | sed "s/^D //")
		KURZTEXT=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^S " | sed "s/^S //")
		if [ -z "$KURZTEXT" ];then
			KURZTEXT="$TITEL"
		fi
                legalTargetDir=$(tr -s '/' '_' <<<"$TITEL")
		if [ ! -f "$CONVERTEDTARGETDIRECTORY/$legalTargetDir" ];then
			mkdir "$CONVERTEDTARGETDIRECTORY/$legalTargetDir"
		fi
		TARGETFILENAME="$TITEL - [$AIRED] - $KURZTEXT"
		legalFilenameOfTitle=$(tr -s '/' '_' <<<"$TARGETFILENAME")
		echo "LegalFilename $legalFilenameOfTitle"  
		DVDTHUMBABSOLUTEPATH="$CONVERTEDTARGETDIRECTORY/$legalTargetDir/$legalFilenameOfTitle.jpg"
		NFOFILE="$CONVERTEDTARGETDIRECTORY/$legalTargetDir/$legalFilenameOfTitle.nfo"
		TARGETTS="$CONVERTEDTARGETDIRECTORY/$legalTargetDir/$legalFilenameOfTitle.ts"
		VDRMETADATA="$CONVERTEDTARGETDIRECTORY/$legalTargetDir/$legalFilenameOfTitle.txt"
		TIMERINFO=$(iconv -f ISO-8859-1 -t UTF-8 info.vdr | grep "^@ " | sed "s/^@ //")
		if [ ! -z "$TIMERINFO" ];then
			echo $TIMERINFO > tmp.xml
			CHANNEL=$(echo 'cat /epgsearch/channel/text()' | xmllint --nocdata --shell tmp.xml | grep -oP '(\d+) - ([A-Z\d\w\s])+' | sed 's/^\([0-9]\+\) - //')
			SEARCHTIMER=$(xmllint --xpath  "//epgsearch/searchtimer/text()" tmp.xml) 
			rm tmp.xml
		fi
	fi


	if [ ! -f "$NFOFILE" ];then
	echo "${TITEL}: $KURZTEXT"
	cp info.vdr "$VDRMETADATA"
	COUNTREC=$(find .. -name "*.rec" | wc -l)
	COUNTRECTS=$(find .. -name "*.ts" | wc -l)
	let COUNTREC=COUNTREC+COUNTRECTS

	HTEXT=$(find .. -name $VDRINFO | sort -n | xargs cat | grep "^S " | sed "s/^S //")

	if [ -z "$HTEXT" ];then
		HTEXT="$DAUER min: $INHALT"
	elif [ "$COUNTREC" = "1" ];then
		HTEXT="[ ${HTEXT} ]
		$DAUER min: $INHALT"
	fi

	echo "creating database infos ..."
	echo "<episodedetails>"                     			> "$NFOFILE"
	echo "<title>$KURZTEXT</title>"            			>> "$NFOFILE"
	echo "<plot>$DAUER min: $INHALT</plot>"    		>> "$NFOFILE"
	#echo "<thumb>$TITEL.jpg</thumb>"				>> "$NFOFILE"
	if [ ! -z "$CHANNEL" ];then
		echo "<tag>Channel $CHANNEL</tag>"    		>> "$NFOFILE"
		echo "<credits>$CHANNEL</credits>"    	>> "$NFOFILE"
		else
		echo "<credits>VDR</credits>"              >> "$NFOFILE"
	fi
	if [ ! -z "$SEARCHTIMER" ];then
		echo "<tag>Suchtimer $SEARCHTIMER</tag>"    		>> "$NFOFILE"    
	fi   
	echo "<director></director>"               >> "$NFOFILE"
	echo "<aired>$AIRED</aired>"               >> "$NFOFILE"
	echo "<runtime>$DAUER min</runtime>"       >> "$NFOFILE"
	echo "<actor></actor>"                     >> "$NFOFILE"
	echo "</episodedetails>"                  		>> "$NFOFILE"
#gets biggest file of directory
	VIDEOFILE=`ls --sort=size | head -1`
	if [ -f $VLC ];then
		if [ ! -f "$DVDTHUMBABSOLUTEPATH" ];then
			echo "creating DVD thumbnails vlc in $VDRDIR..."
			$VLC --no-audio --video-filter scene -V dummy --scene-width=$DVD_YRES --scene-format=jpeg --scene-replace --scene-ratio 24 --start-time=$DVDOFFSETSEC --run-time 1 --scene-path="$VDRDIR" "$VIDEOFILE" vlc://quit  
			if [ -f scene.jpeg ];then
				mv  scene.jpeg "$DVDTHUMBABSOLUTEPATH"
			fi
		fi
	fi
	if [ ! -f "$TARGETTS" ];then
		cat 00*.vdr >> "$TARGETTS"
	fi
	else
		echo "$NFOFILE can not be created - it does already exits" | tee -a "$PROBLEMLOGFILE"
	fi
	fi
	if [ -f "tidy-errors.txt" ];then
		rm tidy-errors.txt
	fi
	done
