# 192.168.1.4 is the adress of an open7x0.org based device
# the transfer rate is limited to ~500kb/s to prevent performance issues while recording (i think the box has something like 66MHz)
# source and destinationpath have to changed to fit in your environment
killall lftp
echo "Start Syncing Vdr $(date)" | tee -a ~/syncVideorecorder.log 
lftp ftp://root:l1nux@192.168.1.4 -e "set file:charset utf8 && set ftp:charset iso8859-1 && mirror --older-than='now-1days' --Remove-source-files --continue --verbos --exclude /.+\.del/$ --exclude quer/ --exclude Zeit_im_Bild/ --exclude ECO/ --exclude ZIB_Magazin/ --exclude Eco/ --exclude 10_vor_10/ --loop /var/media/disk-volume-0/video /home/htpc/Videos/Videorecorder && exit"  | tee -a ~/syncVideorecorder.log

