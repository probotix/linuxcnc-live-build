#!/bin/bash

#feed sudo password so that it doesnt prompt for it
sudo -S <<< "probotix" echo

CONFIG_NAME="PROBOTIX LinuxCNC ISO Builder"
BASE_DIR="$HOME/buster-live-build"
VERSION="1.0"
OUTPUT_DEVICE=`df | grep /media/probotix | awk '{print $1;}'` 
#OUTPUT_DEVICE='/dev/sdc'

#need to check for disk size
DISC=$(df | grep /dev/sda1)
SUBSTRING=$(echo $DISC | cut -d' ' -f5) 


#update time because sleeping Virtual box stops the clock
sudo ntpdate -s time.nist.gov
DATETIME=$(date +'%Y-%m-%d-%T')




f_header() {
	echo "  __  __  __  __  __ ___ "   
	echo " |__)|__)/  \|__)/  \ | |\_/ "
	echo " |   | \ \__/|__)\__/ | |/ \ "
	echo
}

f_prompt() {
	# usage: f_prompt question description
	cols=$(($(tput cols)-2))
	#if [ $DEBUG -eq 0 ]; then
		#clear
	#fi
	printf ' '
	printf '%*s\n' $cols '' | tr ' ' -	
	f_header
	printf '%s\n' " $CONFIG_NAME v$VERSION"
    #printf '%s\n' " TEMP: $DISC"
    printf '%s\n' " OUTPUT DEVICE: $OUTPUT_DEVICE"
    printf '%s\n' " LOCAL DISC: $SUBSTRING"
    printf '%s\n' " DATETIME: $DATETIME"
	printf ' '
	printf '%*s\n' $cols '' | tr ' ' -
	printf '%s\n' "$1"
	if [ -n "$2" ]; then
		printf "$2\n"
	fi
}




f_lb_config(){
    sudo lb config noauto \
    --linux-packages linux-image-rt \
    --debootstrap-options \
    --include=apt-transport-https,ca-certificates,openssl \
    --distribution bookworm \
    --binary-images iso-hybrid \
    --debian-installer live \
    --archive-areas main contrib non-free non-free-firmware \
    --parent-archive-areas "main contrib non-free non-free-firmware" \
    --iso-application LinuxCNC-2.9.2 \
    --iso-preparer len@probotix.com \
    --iso-volume LinuxCNC_2.9.2 \
    --image-name LinuxCNC_2.9.2 \
    --iso-publisher www.probotix.com \
    --apt-recommends true \
    --security true \
    --updates true
}

#    --apt-recommends false \
#--grub-splash

f_lb_config2(){
    sudo lb config noauto \
        --color \
        --apt-indices false \
        --apt-recommends true \
        --archive-areas "${ARCHIVE_AREAS}" \
        --binary-images iso-hybrid \
        --backports false \
        --bootloaders syslinux,grub-efi \
        --debootstrap-options "--include=ca-certificates" \
        --debconf-priority critical \
        --debian-installer live \
        --debian-installer-gui true \
        --distribution "${CODENAME}" \
        --security true \
        --zsync false \
        --bootappend-live "${BOOTAPPEND}" \
        --mirror-bootstrap "${MIRROR_URL}" \
        --mirror-chroot "${MIRROR_URL}" \
        --mirror-chroot-security "${MIRROR_SECURITY_URL}" \
        --mirror-binary "${FINAL_MIRROR_URL}" \
        --mirror-binary-security "${MIRROR_SECURITY_URL}" \
        --mirror-debian-installer "${MIRROR_URL}" \
        --memtest "memtest86+" \
        --checksums sha256 \
        "${COMPRESS_OPTS[@]}" \
-       -image-name "${LB_IMAGE_NAME}"
}

f_lb_clean(){
    sudo lb clean
}

f_lb_build(){
    sudo lb build
    #mv image.iso live-image-amd64.hybrid-$DATETIME.iso
}

f_burn_iso(){
    #to burn iso file to thumb drive
    echo "burning $iso"
    start="$(date +%s.%N)"
    sleep 1
    sudo dd bs=4M if="$iso" of="$OUTPUT_DEVICE" conv=fdatasync status=progress
    end="$(date +%s.%N )"
    diff=$(echo "$end-$start" |bc)
    time=`date -d@$diff -u +%H:%M:%S`
    echo "Total time: $time"
}

f_copy_iso_to_share(){
    cp *.iso /home/probotix/share/
}

f_mount_iso(){
    sudo umount /mnt/iso/
    echo "mounting $iso"
    sudo mount -o loop -t iso9660 $iso /mnt/iso
    sleep 1
}



while true; do
    f_prompt "What would you like to do?"
    COLUMNS=1
    select x in "Clean" "Config" "Build" "Copy ISO to Share" "Burn ISO" "Mount ISO" "Unmount ISO" "Exit"; do
	    case $x in
            "Exit" )
                exit
                break;;
            "Clean" )
                f_lb_clean
                read -p "Press enter to continue"
                break;;
		    "Config" )
			    f_lb_config
                read -p "Press enter to continue"
			    break;;
            "Build" )
			    f_lb_build
                read -p "Press enter to continue"
			    break;;
			"Copy ISO to Share" )
			    f_copy_iso_to_share
                read -p "Press enter to continue"
			    break;;
            "Mount ISO" )
                iso=$(ls  *.iso)
                f_prompt "Which version would you like to mount"
                COLUMNS=1
                select iso in $iso; do test -n "$iso" && break; echo ">>> Invalid Selection"; done
                f_mount_iso
                ls -l /mnt/iso/
                read -p "Press enter to continue"
                break;;
            "Unmount ISO" )
                sudo umount /mnt/iso/
                read -p "Press enter to continue"
                break;;
            "Burn ISO" )
                iso=$(ls *.iso)
                f_prompt "Which version would you like to burn?"
                COLUMNS=1
                select iso in $iso; do test -n "$iso" && break; echo ">>> Invalid Selection"; done
                f_burn_iso
                read -p "Press enter to continue"
                break;;
	    esac
    done
done



