sourceroot="/home/htpc/Videos/Sortieren/SerienTs"
destination="/home/htpc/Videos/Sortieren/Serien"
backupdir=/mnt/hddvolume/deleteme

if [ "$1" = "-only1stAudioTrack" ];then
  echo "using only the first mp3 audio track ..."
elif [ -n "$1" ];then
  echo "  Usage:"
  echo "  $0"
  echo "      - or -"
  echo "  $0 -only1stAudioTrack"
  exit 0
fi

IFS=$'\n'
cd "$sourceroot"
for f in $(find $sourceroot -name '*.ts' -type f) ; do 
	echo "$f"

	#read -n 1 -s	
	TSDIR=$(dirname "$f")
        cd "$TSDIR"
	ABSOLUTEPATHTOTSFILE="$source$f"
	SERIENAME=$(basename "$TSDIR")
	FILENAMETS=$(basename "$f")	
# try to fix the broken file with following commands_
	#	projectx Bronson.ts -out ./fixed/
	mkdir fixed
	projectx "$ABSOLUTEPATHTOTSFILE" -out ./fixed/
	# creates a mpgp
	#	mplex -f 8 -o Bronson1.mpg Bronson.m2v Bronson.mp2 Bronson\[1\].mp2
	# creates a mkv - better choose:
	# 	mkvmerge Bronson.m2v Bronson.mp2 -o Bronson.mkv
	rm "./fixed/${FILENAMETS%.ts}_log.txt"
		#if [ -f "./fixed/${f%.ts}.ac3" ];then
       		#	mkvmerge "./fixed/${f%.ts}.m2v" "./fixed/${f%.ts}.mp2" "./fixed/${f%.ts}.ac3" -o "${f%.ts}.mkv"
		#else
		#	mkvmerge "./fixed/${f%.ts}.m2v" "./fixed/${f%.ts}.mp2" -o "${f%.ts}.mkv" 
		#fi

	mkvmerge "./fixed/"* -o "${f%.ts}.mkv" 
	mv "$f" "$backupdir"
	if [ -f "$destination/${f%.ts}.mkv" ];then
		echo "$f" ist doppelt
		echo "$f" ist doppelt > "$destination/TsToMkv2.log" 
		#read -n 1 -s
	else
		mv "${f%.ts}."* "$destination"
	fi
	rm -R fixed
#use this to set a default audiostream:
#find . -name "*.mkv" -exec mkvpropedit {} --edit track:a1 --set flag-default=0 --edit track:a2 --set flag-default=1 \;

done

