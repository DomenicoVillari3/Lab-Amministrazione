#!/bin/bash

# Var utili 
ISCSI_TARGET="iqn.2024-01.example.com:lun1" 
ISCSI_IP="192.168.128.232" # ip tgt
MOUNT_POINT="/mnt"
CONFIG_FILE="/etc/rsnapshot.conf"

# Logout da iSCSI con reindirizzamento su stderr
sudo iscsiadm --mode node --targetname $ISCSI_TARGET --portal $ISCSI_IP --logout > /dev/null 2>&1

# Login  iSCSI
sudo iscsiadm --mode node --targetname $ISCSI_TARGET --portal $ISCSI_IP --login > /dev/null 2>&1
#recupera stato di ritorno dell'ultimo comando
login_status=$?
sleep 3

#definizione del disco (sdc o sdd) 
DEVICE="/dev/"
DEVICE+=$(lsblk -n --output NAME | grep -E '^sd[c,d]$')



# Verifica se il login è riuscito (0 se è andato a buon fine)
if [ $login_status -ne 0 ]; then
    echo "Errore nella connessione al server iSCSI alle $(date +"%d-%m-%Y %H:%M")"
    exit 1
else 
    # Mount sulla partizione ISCSI
    sudo mount $DEVICE $MOUNT_POINT
    #stato di uscita del mount 
    mount_status=$?

    # Verifica se il mount è riuscito
    if [ $mount_status -ne 0 ]; then
        echo "Errore: il file system non è stato montato correttamente alle $(date +"%d-%m-%Y %H:%M")"
        exit 1
    else
        # Esecuzione del backup
        sudo rsnapshot -c $CONFIG_FILE sync
        sleep 3

        # Umount
        sudo umount $MOUNT_POINT
        sudo iscsiadm --mode node --targetname $ISCSI_TARGET --portal $ISCSI_IP --logout > /dev/null 2>&1

        echo "Backup terminato il $(date +"%d-%m-%Y %H:%M")"
        
    fi
fi
