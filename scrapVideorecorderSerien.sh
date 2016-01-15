#!/bin/bash

#vlc worked much more reliable than mplayer, ffmpeg or vdr2jpeg with streams recorded by open7x0
VLC="/usr/bin/cvlc"
VDR2JPEG="~/vdr2jpeg-0.2.0/vdr2jpeg"
FFMPEG="/usr/bin/avconv"
MPLAYER="/usr/bin/mplayer"
IMGUSE="VDR2JPEG"

VDRREC="/home/htpc/Videos/Videorecorder/Serie"
TVFILE="../../tvshow.nfo"
NFOFILE="00.nfo"

DVDTHUMB="thumb.jpg"
DVDOFFSETVDR="100"
DVDOFFSETSEC="500"
DVD_XRES="1280"
DVD_YRES="720"

CHECKRUNNING=$(/bin/pidof -x $0|wc -w)

if [ $CHECKRUNNING -gt 2 ];then
  echo "$CHECKRUNNING"
  echo "scanvdr already running ..."
  exit 0
fi

if [ "$1" = "-new" ];then
  echo "regenerating all nfo files ..."
	find $VDRREC -name "*.nfo" -exec rm {} \;
elif [ "$1" = "-newall" ];then
  echo "regenerating all files ..."
  find $VDRREC -name "*.jpg" -exec rm {} \;
  find $VDRREC -name "*.nfo" -exec rm {} \;
elif [ -n "$1" ];then
  echo "  Usage:"
  echo "  $0"
  echo "      - or -"
  echo "  $0 -new"
  echo "      - or -"
  echo "  $0 -newall"
  exit 0
fi


for i in $(find $VDRREC -name "info.*" -type f)
do
  VDRDIR=$(dirname $i)
  VDRINFO=$(basename $i)
  DVDTHUMBABSOLUTEPATH=${VDRDIR}/${DVDTHUMB}
  cd $VDRDIR

   #use  "iconv -f ISO-8859-1 -t UTF-8 <file>"  to convert encoding (open7x0 uses ISO-8859-1 in my old version), you can use "cat" instead on your utf8 system

  if [ -f $VDRINFO ];then
     AIRED=$(basename $VDRDIR | awk -F'.' '{print $1}')
     DAUER=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^E " | awk '{print $4/60}' | awk -F'.' '{print $1}')
     TITEL=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^T " | sed "s/^T //")
     INHALT=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^D " | sed "s/^D //")
     KURZTEXT=$(iconv -f ISO-8859-1 -t UTF-8 $VDRINFO | grep "^S " | sed "s/^S //")
     if [ -z "$KURZTEXT" ];then
          KURZTEXT="$TITEL"
     fi
  fi

  echo "${TITEL}: ${KURZTEXT}"

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

  #nfo file name must be 00.nfo for stacking
  if [ -f "002.vdr" ];then
    NFOFILE="00.nfo"
    if [ -f "001.nfo" ];then
       echo "001.nfo entfernt und durch 00.nfo ersetzt"
       rm 001.nfo
    fi
  else
    NFOFILE="001.nfo"
    if [ -f "00.nfo" ];then
	echo "00.nfo entfernt und durch 001.nfo ersetzt"  
	rm 00.nfo
    fi

  fi

  #00.nfo oder 001.nfo ersetllen
  if [ ! -f $NFOFILE ];then
     echo "creating database infos ..."
     echo "<episodedetails>"                     		> $NFOFILE
     echo "<title>$KURZTEXT</title>" 				>> $NFOFILE
     echo "<plot>$DAUER min: $INHALT</plot>"    		>> $NFOFILE
   if [ -z "$IMDBID" ];then
     echo "<thumb>$DVDTHUMBABSOLUTEPATH</thumb>"		>> $NFOFILE
   fi   
     echo "<rating></rating>"                   		>> $NFOFILE
     echo "<season></season>"                   		>> $NFOFILE
     echo "<episode></episode>"                 		>> $NFOFILE
     echo "<credits>VDR</credits>"              		>> $NFOFILE
     echo "<director></director>"              			>> $NFOFILE
     echo "<aired>$AIRED</aired>"               		>> $NFOFILE
     echo "<runtime>$DAUER min</runtime>"       		>> $NFOFILE
     echo "<actor></actor>"                     		>> $NFOFILE
     echo "</episodedetails>"                   >> $NFOFILE
  fi

  #tvshow.nfo erstellen
  if [ ! -f $TVFILE ];then
     	echo "New tvshow !"
	IMDBID=$(curl -G 'http://thetvdb.com/index.php' --data-urlencode "seriesname=${TITEL}" --data-urlencode 'fieldlocation=2' --data-urlencode 'language=14' --data-urlencode 'genre=' --data-urlencode 'year=' --data-urlencode 'network=' --data-urlencode 'zap2it_id=' --data-urlencode 'tvcom_id=' --data-urlencode 'imdb_id=' --data-urlencode 'order=translation' --data-urlencode 'addedBy=' --data-urlencode 'searching=Search' --data-urlencode 'tab=advancedsearch' | tidy -quiet -asxml -numeric -utf8 -file /dev/null | grep tab=series  | grep -oP "id=\d+" | head -1)
	echo "<tvshow>"								> $TVFILE
    	echo "<title>$TITEL</title>" 						>> $TVFILE
    	echo "<showtitle>$TITEL</showtitle>" 					>> $TVFILE
	echo "</tvshow>"							>> $TVFILE
   if [ ! -z "$IMDBID" ];then
	echo "Found TVShow in online db http://thetvdb.com/index.php?tab=series&$IMDBID"     
	echo "http://thetvdb.com/index.php?tab=series&$IMDBID"	>> $TVFILE
   fi
  else
     	echo "tvshow already exists!"
  fi
  #gets biggest file of directory
  VIDEOFILE=`ls --sort=size | head -1`
 if [ -z "$IMDBID" ];then
  if [ -f $VDR2JPEG ] && [ "$IMGUSE" = "VDR2JPEG" ] && [ "$VDRINFO" = "info.vdr" ] && [ -f "info.vdr" ] && [ -f "index.vdr" ];then

     if [ ! -f $DVDTHUMB ];then
       echo "creating DVD thumbnails vdr2jpeg ..."
       $VDR2JPEG -x $DVD_XRES= -y $DVD_YRES -f $DVDOFFSETVDR -r .
       mv 000${DVDOFFSETVDR}.jpg $DVDTHUMB
     fi
  elif [ -f $VLC ];then
     if [ ! -f $DVDTHUMB ];then
       echo "creating DVD thumbnails vlc ..."
       #$VLC --video-filter scene -V dummy --scene-width=$DVD_YRES --scene-format=jpeg --scene-replace --scene-ratio 24 --start-time=60 --stop-time=61 --scene-path=$VDRDIR $VIDEOFILE vlc://quit
       $VLC --no-audio --video-filter scene -V dummy --scene-width=$DVD_YRES --scene-format=jpeg --scene-replace --scene-ratio 24 --start-time=$DVDOFFSETSEC --run-time 1 --scene-path=$VDRDIR $VIDEOFILE vlc://quit  
       mv  scene.jpeg $DVDTHUMB
     fi
  elif [ -f $MPLAYER ];then

     if [ ! -f $DVDTHUMB ];then
       echo "creating DVD thumbnails mplayer ..."
       $MPLAYER -msglevel all=-1 -nosound -vo jpeg -frames 1 -sb $DVDOFFSETVDR $VIDEOFILE

       if [ ! -f 00000001.jpg ];then
	echo fallback1
	$MPLAYER -msglevel all=-1 -nosound -vo jpeg -frames 1 -ss 100 $VIDEOFILE
       fi

       if [ ! -f 00000001.jpg ];then
	echo fallback2
	$MPLAYER -msglevel all=-1 -nosound -vo jpeg -frames 1 -ss 10 $VIDEOFILE
       fi
       if [ -f 00000001.jpg ];then
	mv 00000001.jpg $DVDTHUMB
       fi
     fi

  elif [ -f $FFMPEG ];then

     if [ ! -f $DVDTHUMB ];then
       echo "creating DVD thumbnails ffmpeg / avconv ..."
       $FFMPEG -i $VIDEOFILE -itsoffset $DVDOFFSETSEC -s ${DVD_XRES}x${DVD_YRES} -f image2 -vframes 1 -y temp.jpg
       mv temp.jpg $DVDTHUMB
     fi

  fi
 fi
	if [ -f "tidy-errors.txt" ];then
	  rm tidy-errors.txt
     	fi
  echo "---"
done
