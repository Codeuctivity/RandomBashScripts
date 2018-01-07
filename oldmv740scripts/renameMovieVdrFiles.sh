#!/bin/bash

#this script recursive rename recordings created by vdr (001.vdr ... info.vdr) to an xbmc/Kodi format (movietitle.ts and movititle.nfo)
VLC="/usr/bin/cvlc"
VDRREC="/home/htpc/Videos/Videorecorder"
CONVERTEDTARGETDIRECTORY="/home/htpc/Videos/Sortieren/FilmeTs"
NOTFOUNDINIMDBLIST="/home/htpc/Videos/Sortieren/notFoundInImdb.log"
PROBLEMLOGFILE="/home/htpc/Videos/Sortieren/renamlog.log"
NFOFILE="00.nfo"
# thumbnail - sekunden
DVDOFFSETSEC="100"
CHECKRUNNING=$(/bin/pidof -x $0|wc -w)

if [ $CHECKRUNNING -gt 2 ];then
  echo "$CHECKRUNNING"
  echo "converter already running ..."
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
     legalFilenameOfTitle=$(tr -s '/' '_' <<<"$TITEL")
     echo "LegalFilename $legalFilenameOfTitle"
     DVDTHUMBABSOLUTEPATH="$CONVERTEDTARGETDIRECTORY/$legalFilenameOfTitle.jpg"
     NFOFILE="$CONVERTEDTARGETDIRECTORY/$legalFilenameOfTitle.nfo"
     TARGETTS="$CONVERTEDTARGETDIRECTORY/$legalFilenameOfTitle.ts"
     VDRMETADATA="$CONVERTEDTARGETDIRECTORY/$legalFilenameOfTitle.txt"
     INHALT=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^D " | sed "s/^D //")
     KURZTEXT=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^S " | sed "s/^S //")
     if [ -z "$KURZTEXT" ];then
         KURZTEXT="$TITEL"
     fi
     TIMERINFO=$(iconv -f ISO-8859-1 -t UTF-8 info.vdr | grep "^@ " | sed "s/^@ //")
     #echo $TIMERINFO
     if [ ! -z "$TIMERINFO" ];then
       echo $TIMERINFO > tmp.xml
       #echo $TIMERINFO >> /home/htpc/tmp1.xml
       #echo "cat /epgsearch/channel/text()" | xmllint --nocdata --shell tmp.xml | grep " - "
       CHANNEL=$(echo 'cat /epgsearch/channel/text()' | xmllint --nocdata --shell tmp.xml | grep -oP '(\d+) - ([A-Z\d\w\s])+' | sed 's/^\([0-9]\+\) - //')
       #echo "cat /epgsearch/searchtimer/text()" | xmllint --nocdata --shell tmp.xml | tail -n 2 | head -1
       SEARCHTIMER=$(xmllint --xpath  "//epgsearch/searchtimer/text()" tmp.xml) 
       rm tmp.xml
     fi
  fi
	if [ ! -f "$NFOFILE" ];then
	  echo "${TITEL}:"
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
	     #IMDBID=$(curl -G 'http://www.imdb.com/find' --data-urlencode "q=${TITEL}" --data-urlencode "s=tt" --data-urlencode "exact=true" | tidy -quiet -asxml -numeric -utf8 -file /dev/null | grep /title/ | grep -oP "tt\d{7}" | head -1)
	     IMDBID=$(curl -G 'http://www.imdb.com/find' --data-urlencode "q=${TITEL}" --data-urlencode "s=tt" | tidy -quiet -asxml -numeric -utf8 -file /dev/null | grep /title/ | grep -oP "tt\d{7}" | head -1)
	     echo "<movie>"                     			> "$NFOFILE"
	     echo "<title>$TITEL</title>"            			>> "$NFOFILE"
	     echo "<plot>$DAUER min: $INHALT</plot>"    		>> "$NFOFILE"
	   if [ -z "$IMDBID" ];then
	     echo "<thumb>$TITEL.jpg</thumb>"				>> "$NFOFILE"
	     echo "<tag>Not found in IMDB</tag>"			>> "$NFOFILE"
	     echo "$TITEL not found on IMDB.com ($VDRDIR)"
	     echo "$TITEL not found on IMDB.com ($VDRDIR)" >> $NOTFOUNDINIMDBLIST
	     #curl -G 'http://www.imdb.com/find' --data-urlencode "q=${TITEL}" --data-urlencode "s=tt" | tidy -quiet -asxml -numeric -utf8 -file /dev/null >> $NOTFOUNDINIMDBLIST
	   fi
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
	     echo "</movie>"                  		>> "$NFOFILE"
	     if [ ! -z "$IMDBID" ];then
	      echo "http://www.imdb.com/title/$IMDBID/"	>> "$NFOFILE"
	      if [ -f "thumb.jpg" ];then
		rm thumb.jpg
	      fi
	     fi
	  #gets biggest file of directory
	   VIDEOFILE=`ls --sort=size | head -1`
	   if [ -z "$IMDBID" ];then
	    if [ -f $VLC ];then
	     if [ ! -f "$DVDTHUMBABSOLUTEPATH" ];then
	       echo "creating DVD thumbnails vlc in $VDRDIR..."
	       $VLC --no-audio --video-filter scene -V dummy --scene-width=$DVD_YRES --scene-format=jpeg --scene-replace --scene-ratio 24 --start-time=$DVDOFFSETSEC --run-time 1 --scene-path="$VDRDIR" "$VIDEOFILE" vlc://quit  
	       if [ -f scene.jpeg ];then
		mv  scene.jpeg "$DVDTHUMBABSOLUTEPATH"
	       fi
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
