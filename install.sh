#!/bin/sh
# Glenn McKechnie - modified 01/02/25 
#
# The original installer is still available as install-original.sh
# Use it if you want, but what you fetch won't be what's
# in this repo
#
# With Al's absence from his site and development seemingly dead
# in the water, the original installer had stopped working.  Using
# it overwrote any workarounds applied locally
# That installer has been tweaked and should work for others - I've
# tested it and it work for me ! 

# Al has his code up on github, the logical thing was to start
# with that; and here it is. Use the new install.sh to install this
# repos code as 

d_baseDir=$(cd "$(dirname "$0")" && pwd)

#YAMON='/opt/YAMon4/'

echo "
********************************************************
       Welcome to this Github YAMon installer

This is a forked version of YAMon with modifications
to NOT fetch from the original developers site. See:...
       https://usage-monitoring.com/install

The original installer has been fixed and works as it did
before the site changes. It is still available here but as
it fetches the same files as in this repo then consider it
usable but redundant (and will work only while the parent 
site remains up)

It has been renamed as install-original.sh. Use it if you
 want, but the files you fetch won't be what's in this repo

For old, but still relevant installation tips & tricks, see 
       https://usage-monitoring.com/installv4.php

 Please report any issues from this repo as github issues 
 Via this link ...
     https://github.com/glennmckechnie/YAMon-v4

********************************************************
 "
echo "Would you like to install YAMon on your router?"
tries=0
readstr="Either
	- hit <enter> or \`y\` for yes, or \`n\` for no: "
while true; do
	read -p "$readstr" resp

	if [ -z "$resp" ] || [ "$resp" == 'y' ] || [ "$resp" == 'Y' ] ; then
		break
	elif [ "$resp" == 'n' ] || [ "$resp" == 'N' ] ; then
		echo "
*** Cancelling installation...  Hopefully you'll try again!
"
		exit 0
	else
		readstr="
	Only \`y\` or \`n\` are permitted!
	Please try again: "
	fi
done

echo "

Please specify the fully qualified path to your
installation directory - currently it is at  \`$d_baseDir\`
Accepting the default (/opt/YAMon4) is preferred but that
may not be possible depending on you routers configuration
If you must change it then take note of any odd issues with paths.

"
tries=0
readstr="	Either
	- hit <enter> to accept \`$d_baseDir\`, or
	- optionally (but not recomended) type your
	  preferred installation location: "
while true; do
	read -p "$readstr" resp
	resp="${resp:-$d_baseDir}"
	d_baseDir="${resp%%/}/" # ensure the path ends with a single /
	#echo "d_baseDir: $d_baseDir"
	p2c=$(dirname "$d_baseDir")
	[ -z "${p2c%/}" ] && p2c="$d_baseDir"
	#echo "$p2c: $(ls -laL "$p2c" | grep ' .$' | awk '{print $1}')"
	
	if [ -z "$(ls -laL  "$p2c" | grep ' .$' | awk '{print $1}' | grep 'w')" ] ; then
		echo -e "\n    *** Un-oh... You do not have write permissions in '$p2c'!\n"
	elif [ -d "$d_baseDir" ] ; then
		break
	else
		mkdir -p "$d_baseDir"
		[ -d "$d_baseDir" ] && break
		echo -e "\n    *** The installation directory could not be created?!?\n"
	fi
	readstr="    Please try again: "
	tries=$(($tries + 1))
	if [ "$tries" -eq "3" ] ; then
		echo -e "\n\n*** Hmmm... three tries and still not working...\nPlease check the installation requirements and try again.\nSend screenshots, etc. to questions@usage-monitoring.com."
		exit 0
	fi
done

echo "
**************************************
Installing YAMon...
"

chmod +x "$d_baseDir"
[ -d "${d_baseDir}data" ] && chmod -R 666 "${d_baseDir}data"
sleep 1

_enableLogging=1
_log2file=1
_loglevel=0


source "${d_baseDir}setup4.0.8.sh"

exit 0

# param='verify'
echo -e "	
If we had downloaded the YAMon4 files from
the original site then we would have run a
comparison test, to check there integrity

As we are using the modified files from this
repo, they would not match and would appear to fail
those md5sum checks.  Rest assured they are good!

 So, skip it and move on to the next step...

               *******

  Running the new github setup file.



	"
sleep 5
#[ ! -z "$bCanClear" ] && clear
