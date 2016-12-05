#rm ~/Videos
#ln -s /mnt/e923891b-fec0-40f5-bb2e-df9df88718fb/Videos ~/Videos
#rm ~/Videos/New-*.m3u
#deletes empty directories
find /home/htpc/Videos/Videorecorder -empty -type d -delete
~/Vdr2XbmcSyncScripts/scrapVideorecorderSerien.sh > ~/scrapVideorecorder.log
~/Vdr2XbmcSyncScripts/scrapVideorecorderKinder.sh >> ~/scrapVideorecorder.log
~/Vdr2XbmcSyncScripts/scrapVdr.sh >> ~/scrapVideorecorder.log
# 192.168.1.4 is the adress of an open7x0.org based device
# the transfer rate is limited to ~500kb/s to prevent performance issues while recording (i think the box has something like 66MHz)
# source and destinationpath have to changed to fit in your environment

#killall lftp
#echo "Start Syncing Vdr $(date)" >> ~/syncVideorecorder.log 
#Syncing with open7x0 stopped - next line commented
#nice -n 18 lftp ftp://root:l1nux@192.168.1.4 -e "set net:limit-total-rate 519430:519430 && set file:charset utf8 && set ftp:charset iso8859-1 && mirror --older-than='now-1days' --Remove-source-files --continue --verbos --exclude /.+\.del/$ --exclude quer/ --exclude Zeit_im_Bild/ --exclude ECO/ --exclude ZIB_Magazin/ --exclude Eco/ --exclude 10_vor_10/ --loop /var/media/disk-volume-0/video /home/htpc/Videos/Videorecorder && exit"  >> ~/syncVideorecorder.log 2>&1 &

kodi -fs &
mkdir /media/htpc/Samsung/backupHome
nice -n 18 rsync -av /home/htpc/ /media/htpc/Samsung/backupHome  --delete-before &> ~/backupHome.log &
mkdir /media/htpc/Samsung/backupVideo
nice -n 18 rsync -av /home/htpc/Videos/ /media/htpc/Samsung/backupVideo  --delete-before &> ~/backupVideo.log &
mkdir /media/htpc/Samsung/backupGames
nice -n 18 rsync -av /home/htpc/Games/ /media/htpc/Samsung/backupGames  --delete-before &> ~/backupGames.log &
mkdir /media/htpc/Samsung/backupVirtualBox 
nice -n 18 rsync -av /home/htpc/VirtualBox\ VMs/ /media/htpc/Samsung/backupVirtualBox  --delete-before &> ~/backupVbox.log &
mkdir /media/htpc/Samsung/backupMusik 
nice -n 18 rsync -av /home/htpc/Musik/ /media/htpc/Samsung/Musik  --delete-before &> ~/backupMusik.log &

