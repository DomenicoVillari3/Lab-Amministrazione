#!/bin/bash

#Var utili 
ISCSI_TARGET="iqn.2024-01.example.com:lun1" 
ISCSI_PORTAL="192.168.128.232" #ip tgt
MOUNT_POINT="/mnt"
CONFIG_FILE="/etc/rsnapshot.conf"
DEVICE="/dev/sdc" 


sudo iscsiadm --mode node --targetname $ISCSI_TARGET --portal $ISCSI_PORTAL --logout


sudo iscsiadm --mode node --targetname $ISCSI_TARGET --portal $ISCSI_PORTAL --login
login_status = $?
sleep 5

# Mount sulla partizione ISCSI
sudo mount $DEVICE $MOUNT_POINT

if $login_status -ne 0; then
    echo "errore nella connessione al server iscsi."
else 
    # Verifica mount
    if mount | grep $MOUNT_POINT > /dev/null; then

        #esecuzione del backup
        sudo rsnapshot -c $CONFIG_FILE sync

        sleep 5

        #umount
        sudo umount $MOUNT_POINT

        sudo iscsiadm --mode node --targetname $ISCSI_TARGET --portal $ISCSI_PORTAL --logout

        echo  "backup terminato il $(date +"%d-%m-%Y %H:%M")"
    else
        echo "Errore: il file system non è stato montato correttamente."
    fi
fi
