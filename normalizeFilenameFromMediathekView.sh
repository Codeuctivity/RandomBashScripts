#!/bin/bash

VLC="/usr/bin/cvlc"
SOURCE="/home/htpc/Videos/Sortieren/Mediathekview"

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

cd $SOURCE
for file in * ; do mv -v "$file" "$(echo $file | sed 's/_/ /g')" ; done


for f in *.mp4; do   

	echo "${f}" | sed 's/\-[0-9]//g'
done

