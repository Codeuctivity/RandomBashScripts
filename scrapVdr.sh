#!/bin/bash

#vlc worked much more reliable than mplayer, ffmpeg or vdr2jpeg with streams recorded by open7x0
VLC="/usr/bin/cvlc"
VDR2JPEG="~/vdr2jpeg-0.2.0/vdr2jpeg"
FFMPEG="/usr/bin/avconv"
MPLAYER="/usr/bin/mplayer"
IMGUSE="VDR2JPEG"

VDRREC="/home/htpc/Videos/Videorecorder"
NFOFILE="00.nfo"
NOTFOUNDINIMDBLIST="/home/htpc/notFoundInImdb.log"

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

  echo "${TITEL}:"

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
       rm 001.nfo
    fi
  else
    NFOFILE="001.nfo"
    if [ -f "00.nfo" ];then
       rm 00.nfo
    fi

  fi
  if [ ! -f $NFOFILE ];then
     echo "creating database infos ..."
     #IMDBID=$(curl -G 'http://www.imdb.com/find' --data-urlencode "q=${TITEL}" --data-urlencode "s=tt" --data-urlencode "exact=true" | tidy -quiet -asxml -numeric -utf8 -file /dev/null | grep /title/ | grep -oP "tt\d{7}" | head -1)
	IMDBID=$(curl -G 'http://www.imdb.com/find' --data-urlencode "q=${TITEL}" --data-urlencode "s=tt" | tidy -quiet -asxml -numeric -utf8 -file /dev/null | grep /title/ | grep -oP "tt\d{7}" | head -1)
     echo "<movie>"                     			> $NFOFILE
     echo "<title>$TITEL</title>"            			>> $NFOFILE
     echo "<plot>$DAUER min: $INHALT</plot>"    		>> $NFOFILE
   if [ -z "$IMDBID" ];then
     echo "<thumb>$DVDTHUMBABSOLUTEPATH</thumb>"		>> $NFOFILE
     echo "$TITEL not found on IMDB.com ($VDRDIR)"
     echo "$TITEL not found on IMDB.com ($VDRDIR)" >> $NOTFOUNDINIMDBLIST
     #curl -G 'http://www.imdb.com/find' --data-urlencode "q=${TITEL}" --data-urlencode "s=tt" | tidy -quiet -asxml -numeric -utf8 -file /dev/null >> $NOTFOUNDINIMDBLIST
   fi   
  echo "<credits>VDR</credits>"              		>> $NFOFILE
     echo "<director></director>"               >> $NFOFILE
     echo "<aired>$AIRED</aired>"               >> $NFOFILE
     echo "<runtime>$DAUER min</runtime>"       >> $NFOFILE
     echo "<actor></actor>"                     >> $NFOFILE
     echo "</movie>"                  		>> $NFOFILE
   if [ ! -z "$IMDBID" ];then
     echo "http://www.imdb.com/title/$IMDBID/"	>> $NFOFILE
     if [ -f "thumb.jpg" ];then
       rm thumb.jpg
     fi
   fi
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
       echo "creating DVD thumbnails vlc in $VDRDIR..."
       $VLC --no-audio --video-filter scene -V dummy --scene-width=$DVD_YRES --scene-format=jpeg --scene-replace --scene-ratio 24 --start-time=$DVDOFFSETSEC --run-time 1 --scene-path=$VDRDIR $VIDEOFILE vlc://quit  
       if [ -f scene.jpeg ];then       
	mv  scene.jpeg $DVDTHUMB
       fi
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
