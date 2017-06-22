#!/bin/sh
# This file will be in /init_functions.sh inside the initramfs.

mount_subpartitions()
{
	for i in /dev/mmcblk*; do
		case "$(kpartx -l "$i" 2> /dev/null | wc -l)" in
			2)
				echo "mount subpartitions of $i"
				kpartx -afs "$i"
				break
				;;
			*)
				continue
				;;
		esac
	done
}

find_root_partition()
{
	DEVICE=$(blkid | grep "crypto_LUKS" | tail -1 | cut -d ":" -f 1)

	if [ -z "$DEVICE" ]; then
		DEVICE=$(blkid | grep "pmOS_root" | tail -1 | cut -d ":" -f 1)
	fi

	log "info" "root partition is $DEVICE"

	echo $DEVICE
}

unlock_root_partition()
{
	while ! [ -e /dev/mapper/root ]; do
		partition="$(find_root_partition)"
		if [ -z "$partition" ]; then
			echo "Could not find cryptsetup partition."
			echo "Maybe you need to insert the sdcard, if your device has"
			echo "any? Trying again in one second..."
			sleep 1
		else
			cryptsetup luksOpen "$partition" root
		fi
	done
}

# $1: path to ppm.gz file
show_splash()
{
	gzip -c -d "$1" > /tmp/splash.ppm
	fbsplash -s /tmp/splash.ppm
}
