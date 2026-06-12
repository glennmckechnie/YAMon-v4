#!/bin/sh

tmpfile="backupYAMon4_sh-$(date +%Y%m%d%H%M%S)"

baseDir='/opt/YAMon4'
file1='/www/yamon'
file2="${baseDir}/config.file"
file3="${baseDir}/includes/paths.sh"
dir1="/tmp/yamon"
dir2="/tmp/www"
delay='20'
clear
echo
echo -e " This is a backup script to preserve all files in /opt/YAMon4\n and its related directories, it follows any symlinks and\n\t preserves the files found there."
echo
df -h
echo
echo -e " This script is best run from a mounted drive, rather than the\n\t    '/' filesystem (that includes /opt/YAMon4).\n\n Check the free space, especially for the overlay filesystem.\n\t"
while [ ${delay} -ge 0 ]; do
  printf "\r    Sleeping for %2d seconds - Ctrl-C to exit now" "$delay"
  if [ ${delay} -eq 0 ]; then
    break
  fi
   sleep 1
   delay=$((delay - 1))
 done

(tar -hcf - "$baseDir" "$dir1" "$dir2" ; tar -cf - "$file1" )| gzip -9 > $tmpfile.tar.gz
# not working
#( tar -hcf - "$dir1" "$dir2" 2>tar1.err ; tar -cf - "$file2" "$file3" 2>tar2.err ) | ( tee >(gzip -9 > "$tmpfile.tar.gz") | tar tvf - )

ls -al $tmpfile.tar.gz

mkdir $tmpfile || { echo "Cannot create $tmpfile" ; exit 1; }

gzip -dc "$tmpfile.tar.gz" | tar xvf - -C "$tmpfile"

mv "$tmpfile.tar.gz" "$tmpfile"

cp -- "$0" "$tmpfile/" || { echo "copying backup script failed"; exit 1; }

# A True clean up. Gutsy without checking first!
#[ -L "$file1" ] && rm -fv -- "$file1"
#[ -L "$dir2" ] && rm -fv -- "$dir2"
#mv "$dir1" "{$dir1-$tmpfile}"

exit 0
