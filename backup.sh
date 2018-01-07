nice -n 18 rsync -aP --exclude-from=rsync-homedir-excludes.txt /home/htpc/ /media/htpc/Samsung/backupHome  --delete-before --copy-dirlinks | tee ~/backupHome.log
#exclude
#/home/htpc/.dbus
#/home/htpc/.cache/dconf

#nice -n 18 rsync -av /home/htpc/Videos/ /media/htpc/Samsung/backupVideo  --delete-before --copy-dirlinks
#nice -n 18 rsync -av "/home/htpc/VirtualBox VMs" /media/htpc/Samsung/backupVirtualBox  --delete-before --copy-dirlinks
#nice -n 18 rsync -av /home/htpc/Games /media/htpc/Samsung/backupGames  --delete-before --copy-dirlinks
#nice -n 18 rsync -av /home/htpc/Musik /media/htpc/Samsung/backupMusik  --delete-before --copy-dirlinks
