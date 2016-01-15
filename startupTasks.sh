rm ~/Videos/New-*.m3u
~/Vdr2XbmcSyncScripts/scrapVideorecorderSerien.sh > ~/syncVideorecorder.log
~/Vdr2XbmcSyncScripts/scrapVideorecorderKinder.sh >> ~/syncVideorecorder.log
~/Vdr2XbmcSyncScripts/scrapVdr.sh >> ~/syncVideorecorder.log
# 192.168.1.4 is the adress of an open7x0.org based device
# the transfer rate is limited to ~500kb/s to prevent performance issues while recording (i think the box has something like 66MHz)
# source and destinationpath have to changed to fit in your environment
nice -n 18 lftp ftp://root:l1nux@192.168.1.4 -e "set net:limit-total-rate 519430:519430 && set file:charset utf8 && set ftp:charset iso8859-1 && mirror --continue --verbos --exclude /.+\.del/$ --exclude quer/ --exclude Zeit_im_Bild/ --exclude ECO/ --exclude ZIB_Magazin/ --exclude Eco/ --exclude 10_vor_10/ --loop /var/media/disk-volume-0/video /home/htpc/Videos/Videorecorder && exit"  >> ~/syncVideorecorder.log 2>&1 &
xbmc -fs &
