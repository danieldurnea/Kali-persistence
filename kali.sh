#!/bin/bash

if [ -z "$1" ] # check if arg1 is empty string
then
  echo "Usage: sudo $0 <kali_linux_iso_file>"
  exit 1
elif [ ! -e "$1" ] # check file exists
then
  echo "Cannot find file: $1"
  exit 2
else
  ISO="$1"
fi

read -p "Enter USB Flash Drive(ex: /dev/sdb): " DEVICE

if [ -z "$DEVICE" -o ! -e "$DEVICE" ]
then
  echo "Cannot find Device: $DEVICE"
  exit 3
elif [[ $DEVICE = "/dev/sda" ]]
then
  echo "Will not install on Internal Hard Disk: $DEVICE"
  exit 4
else
  # confirm before proceeding
  read -p "Confirm $ISO installation on $DEVICE (y/n)?: " ANS

  if [[ $ANS != "y" ]]
  then
    exit 5
  fi

  partitions=$(sudo mount | grep $DEVICE | cut -d' ' -f1)
  for partition in "$partitions"
  do
    sudo umount $partition 2> /dev/null
  done
fi

# writing the iso creates 2 partitions
echo; echo "Writing $ISO to $DEVICE ..."
sudo dd bs=1M if=$ISO of=$DEVICE oflag=direct status=progress && sync
echo;

# write persistence to partition 3
PERSISTENCE=3
START=$(du -B1000000 $ISO | cut -f1)
END=$(lsblk --noheadings --nodeps --bytes --output SIZE $DEVICE)
END=$(($END/1000000))

echo; echo "Making Persistenct Volume on ${DEVICE}${PERSISTENCE} from $START to $END ..."
sudo parted $DEVICE mkpart primary $START $END
sync; echo;

sudo mkfs.ext3 -L persistence ${DEVICE}${PERSISTENCE}
sudo mkdir -p /mnt/kali
sudo mount ${DEVICE}${PERSISTENCE} /mnt/kali
sudo sh -c "echo '/ union' > /mnt/kali/persistence.conf"
sync; sync;

sudo umount ${DEVICE}${PERSISTENCE}
sudo rm -rf /mnt/kali

echo; sudo fdisk -l $DEVICE
exit 0
