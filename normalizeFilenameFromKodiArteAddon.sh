#!/bin/bash

VLC="/usr/bin/cvlc"
# destination where kodi addon arte7+ saved the mp4s
SOURCE="/home/htpc/Videos/Sortieren/arte"
# destination wher kode scraps new videos
DESTINATION="/home/htpc/Videos/Filme/VonArte/automatedSorted"
# 
ARCHIVE="/home/htpc/Videos/Sortieren/arte/archive"
CHECKRUNNING=$(/bin/pidof -x $0|wc -w)

if [ $CHECKRUNNING -gt 2 ];then
  echo "$CHECKRUNNING"
  echo "noramlization already running ..."
  exit 0
fi

if [ -n "$1" ];then
#  echo "  Usage: - no parameter allowed"
  exit 0
fi

foundNewFile=false

cd $SOURCE
for file in *.mp4 ; do 
foo="$(echo $file | sed 's/_/ /g' |  cut -d ' ' -f 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20)"
concatedDestination="$DESTINATION/$foo"
archiveDestination="$ARCHIVE/$foo"
if [ ! -f "$concatedDestination" ];then
  echo Creating hardlink from "$file" to "$concatedDestination"
  ln "$file" "$concatedDestination"
  foundNewFile=true
  if [ ! -f "$archiveDestination" ];then
   mv -v "$file" "$archiveDestination"
  else
   echo "$file" can not be archived - file already exists 
  fi
else
  echo "$concatedDestination" already exists for "$file"
fi
done

#create code metainfo files with tiny media manager http://www.tinymediamanager.org/site/blog/command-line-arguments/
#i think you have to configure it once with /tinyMediaManager.sh before this will work

if [ "$foundNewFile" = true ] ; then
    ~/tiny\ media\ manager/tinyMediaManagerCMD.sh -update -scrapeNew
fi
