#!/bin/sh
# If you need a licence, consider it GPL'd
# Glenn McKechnie - modified 12/06/26 15:16
# Script to backup a working installation of YAMon4. Working because it will follow
# symlinks to the temporary directories and archive the files found within. It converts
# the symlinks to convential names (inodes).

backupLocation="/mnt/nvme0n1/backupYAMon4/"
baseDir='/opt/YAMon4'
file1='/www/yamon'
file2="${baseDir}/config.file"
file3="${baseDir}/includes/paths.sh"
dir1="/tmp/yamon"
dir2="/tmp/www"
delay='25'
delay2='10'

clear
date
	echo -e "\n This is a backup script to preserve all files in /opt/YAMon4\n and its related directories, it follows any symlinks and\n\t preserves the files found there."
	echo -e "\n This script is best run from a mounted drive, rather than the\n    '/' filesystem (that includes /opt/YAMon4).\n Check the free space, especially for the overlay filesystem.\n\t"

df -h
echo -e "\nChanging to the 'backup Location' - make sure it exists!"
if [ ! -d "${backupLocation}" ] ; then
	echo -e "\nCannot find the backup location. Edit this file and check the 1st line"
	exit 1
else
	cd "${backupLocation}"
	echo -e "\n Using ${backupLocation} as the backup Location.\n"
	df -h .
fi

if [ $# -ne '2' ] ; then
	echo -e "\nTwo arguments are required..."
	echo -e "1.) A meaningful name to add to the saved filename"
	echo -e "2.) A decison whether to unpack the resulting tarball"
	echo -e "    into its named directory. 'yes' or 'no'\n"
	echo -e "\tUsage:- $0 added_name yes\n"
	exit 1
fi
	tmpfile="backupYAMon4_sh-${1}-$(date +%Y%m%d%H%M%S)"
echo -e "\nThe archive filename will be ${tmpfile}"
#	tmpfile="backupYAMon4_sh-$(date +%Y%m%d%H%M%S)"
if [ "$2" == 'yes' ] ; then
	echo -e "\nThe option 'yes' has been passed to the script so the archive\n will be unpacked into ${backupLocation}/${tmpfile}"
else
	echo -e "\nThe 2nd option indicates the archive will remain compressed\n\t${tmpfile}.tar.gz"
fi

echo -e "\nIt will create the file named\n\t ${tmpfile}"
echo
	while [ ${delay} -ge 0 ]; do
	printf "\r    Sleeping for %2d seconds - Ctrl-C to exit now" "$delay"
		if [ ${delay} -eq 0 ]; then
		    break
		fi
	sleep 1
	delay=$((delay - 1))
	done
echo -e "\n-------------Archiving----------------"

	# Make the archive...
	tar -hcf  "${tmpfile}.tar.gz" "$baseDir"  2>/dev/null
	pwd
	ls -al "${tmpfile}.tar.gz"
	date

if [ $2 == 'yes' ] ; then
	# Unpack the archive
	echo -e "\nUnpacking tarball into backup directory\n\t ${backupLocation}/${tmpfile}\n"
	echo -e " Check the contents and ensure they are what you want\n"
	echo
		while [ ${delay2} -ge 0 ]; do
			printf "\r    Sleeping for %2d seconds - Ctrl-C to exit now" "$delay"
			if [ ${delay2} -eq 0 ]; then
			    break
			fi
			sleep 1
			delay=$((delay2 - 1))
		done
		echo -e "\n-----------------------------"
	mkdir "$tmpfile" || { echo "Cannot create $tmpfile" ; exit 1; }

	gzip -dc "$tmpfile.tar.gz" | tar xf - -C "$tmpfile"

	mv "${tmpfile}.tar.gz" "$tmpfile"

	cp -- "$0" "${tmpfile}/" || { echo "copying backup script failed"; exit 1; }

	cd "$tmpfile/"
fi
exit 0

# A True clean up. Gutsy without checking first!
#[ -L "$file1" ] && rm -fv -- "$file1"
#[ -L "$dir2" ] && rm -fv -- "$dir2"
#mv "$dir1" "{$dir1-$tmpfile}"
date
exit 0
