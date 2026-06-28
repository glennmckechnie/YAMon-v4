#!/bin/sh
# start.sh
#showEcho="yes"

##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# sets up iptables entries; crontab entries, etc.
# run: /opt/YAMon4/start.sh
# History
# 2026-06-19: add recovery code when rebooted. On the off chance that the data/* files are still
# 		valid (dated correctly) they will be copied back to /tmp/yamon rather than lost.
# 2026-06-09: add current/ for Als intro.php files (that cause all sorts of problems for local installs!)
# 2026-06-05: Add _domain, _doLocalFiles to config4.0.js for index.html use.
# 	      add df -h to logs (free disk space), add errorThrown to cover for empty
# 2026-05-22: 4.0.8 - added backup recovery routine activated via pause.sh (see includes/start-stop.sh)
# 2026-05-19: rejig AddSoftLink to ignore existing directories as well as deal with existing symlinks
# 2025-02: symlink yamon4.0.html to index.html
# 2020-01-26: 4.0.7 - create tmpLastSeen if it does not exist; fixed users_created error
#                   - changed name of StartCronJobs to StartScheduledJobs (to better account for cron vs cru)
#                   - add symlink for _wwwURL if it does not already exist
# 2020-01-03: 4.0.6 - added logging to WriteConfigFile; changed logic to create js directory in SetWebDirectories
# 2019-12-23: 4.0.5 - added symlink for latest-log & day-log
# 2019-11-24: 4.0.4 - no changes (yet)
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

CreateUsersFile()
{
	#wget http://usage-monitoring.com/current/getDevices.php?k=29e315558d333f4ae3845f02a7edd8d0 -U "YAMon-Setup" -Oq "${tmplog}devices.txt"
	Send2Log "CreateUsersFile: Creating empty users file: $_usersFile" 2
	echo "var users_version=\"$_version\"
var users_created=\"$_ds $_ts\"
var users_updated=\"\"
//MAC -> Groups

//MAC -> IP
" > $_usersFile
}

SetWebDirectories()
{
	WriteConfigFile(){
		local cfgPath="${_wwwPath}js/config${_version%\.*}.js"
		Send2Log "WriteConfigFile: $cfgPath" 1 "${0##$d_baseDir/} : WriteConfigFile : Line Number ${LINENO}"
		local configComnt="// added to fix blocking 'undefined errorThrown' in remote script"
		local configStart="window.errorThrown = typeof window.errorThrown !== 'undefined' ? window.errorThrown : '';"
		local configVars='_installed,_updated,_router,_firmwareName,_version,_file_version,_html_version,_firmware,_dbkey,_updateTraffic,_ispBillingDay,_wwwData,_domain,_doLocalFiles'

		>"$cfgPath" #empty the file

		IFS=$','
		echo "$configComnt"  >> "$cfgPath"
		echo "$configStart"  >> "$cfgPath"
			Send2Log "WriteConfigFile: $configCmnt, $configStart" 4 "${0##$d_baseDir/} : WriteConfigFile : Line Number ${LINENO}"
		for vn in $configVars ; do
			eval vv=\"\$$vn\"
			Send2Log "WriteConfigFile: $vn -> $vv" 1 "${0##$d_baseDir/} : WriteConfigFile : Line Number ${LINENO}"
			echo "var $vn = \"$vv\"" >> "$cfgPath"
		done
	}
	AddSoftLink(){
		Send2Log "AddSoftLink: ln -snf $1 -> $2" 1 "${0##$d_baseDir/} : AddSoftLinkq : Line Number ${LINENO}"
		# stop creating recursive directories! and move on if it is a directory.
		# also redo the www link - regardless
		if [ "$2" = "/www${_wwwURL}" ]; then
			[ -L "$2" ] && rm -fv -- "$2"
			ln -snf -- "$1" "$2"
		elif [ ! -d "$2" ]; then
			[ -L "$2" ] && rm -fv -- "$2"
			ln -snf -- "$1" "$2"
		fi
		Send2Log "ln -snf -- $1 $2"
	}
	Send2Log "SetWebDirectories : start Main" 1  "${0##$d_baseDir/} : SetWebDirectories : Line Number ${LINENO}"
	# _wwwPath:/tmp/www/  _wwwURL:/yamon  d_baseDir:/opt/YAMon4
	# /tmp/www/yamon /www/yamon
	[ -d "${_wwwPath}files" ] || mkdir -p "${_wwwPath}files"
	AddSoftLink "${_wwwPath%/}" "/www${_wwwURL}"
	chmod -R a+rX "${_wwwPath}"
	# /opt/YAMon4/www/css /tmp/www/css
	AddSoftLink "${d_baseDir}/www/css" "${_wwwPath}css"
	AddSoftLink "${d_baseDir}/www/images" "${_wwwPath}images"
	# add js path using our local files
	AddSoftLink "${d_baseDir}/www/js" "${_wwwPath}js"
	AddSoftLink "${d_baseDir}/www/current" "${_wwwPath}current"
	AddSoftLink "${d_baseDir}/daily-bu" "${_wwwPath}files/daily-bu"
	AddSoftLink "${d_baseDir}/data" "${_wwwPath}files/data"
	AddSoftLink "/tmp${_wwwURL}" "${_wwwPath}files/yamon"
	[ "$_wwwData" == 'data3/' ] && _wwwData=''
	AddSoftLink "${_path2data%/}" "${_wwwPath}${_wwwData:-data4}"
	AddSoftLink "${_path2logs%/}" "${_wwwPath}logs"
	AddSoftLink "$tmplogFile" "${_wwwPath}logs/latest-log.html"
	AddSoftLink "${_path2logs}${_ds}.html" "${_wwwPath}logs/day-log.html"
	#FIXME
	# inclusion of various indexX.html
	#AddSoftLink "${d_baseDir}/www/yamon${_version%\.*}.html" "${_wwwPath}${_webIndex:-index.html}"
	AddSoftLink "${d_baseDir}/www/yamon4.0.html" "${_wwwPath}index4.html"
	AddSoftLink "${d_baseDir}/www/yamon4.0.7.html" "${_wwwPath}index7.html"
	AddSoftLink "${d_baseDir}/www/yamon4.0.8.html" "${_wwwPath}index.html"

	WriteConfigFile
	set +v +x
	# sleep 30
}

d_baseDir=$(cd "$(dirname "$0")" && pwd)
source "${d_baseDir}/includes/version.sh"
source "$d_baseDir/strings/title.inc"

echo -E "$_s_title"

# re-run to get a fresh paths.sh
"${d_baseDir}/setPaths.sh"

tmplog='/tmp/yamon/'
[ -d "$tmplog" ] || mkdir -p "$tmplog"


source "${d_baseDir}/includes/shared.sh"
source "${d_baseDir}/includes/setupIPChains.sh"
source "${d_baseDir}/includes/paths.sh"

FunctionUsage "Start" 1 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"

[ -f "$_lastSeenFile" ] || touch "$_lastSeenFile"
[ -f "$tmpLastSeen" ] || touch "$tmpLastSeen"

source "${d_baseDir}/includes/start-stop.sh"

echo -E "$_s_title" # echo the title again so it appears in the log file too :-)

[ -d "$_path2logs" ] || mkdir -p "$_path2logs"
[ -d "$_path2data" ] || mkdir -p "$_path2data"
[ -d "$_path2bu" ] || mkdir -p "$_path2bu"
[ -d "$_path2CurrentMonth" ] || mkdir -p "$_path2CurrentMonth"

[ ! -f "$hourlyDataFile" ] && [ -f "${_path2CurrentMonth}hourly_${_ds}.js" ] && cp "${_path2CurrentMonth}hourly_${_ds}.js" "${tmplog}"
[ ! -f "$hourlyDataFile" ] && echo -e "var hourly_created=\"${_ds} ${_ts}\"\nvar hourly_updated=\"${_ds} ${_ts}\"\n" > "$hourlyDataFile"


ln -snf "$tmplog" "$d_baseDir"
> "$macIPFile" # create and/or empty the MAC IP list files

[ ! -f "$hourlyDataFile" ] &&  [ ! -f "${_path2CurrentMonth}hourly_${_ds}.js" ] && cp "${_path2CurrentMonth}hourly_${_ds}.js" "$hourlyDataFile"

if [ -f "$_lastSeenFile" ] ; then
	cp "${_lastSeenFile}" "$tmpLastSeen"
	# next is optional. More for diagnostics / debug
	cp "$_lastSeenFile" "${_path2CurrentMonth}lastseen-debug-${_ds}-${_ts}.js}"
fi

[ -z "$1" ] && rebootOrStart='Script Restarted' || rebootOrStart='Server Rebooted'
#if [ -z "$1" ]; then
#	# plain 'sh start.sh' or '/etc/init.d/yamon4 boot'
#	rebootOrStart='Script Restarted'
#else
#	# reboot message from '/etc/init.d/yamon start' (restart)
#	rebootOrStart='Server Rebooted'
#	cp "${_path2CurrentMonth}${hourlyDataFile##/}" "$hourlyDataFile"  >/dev/null 2>&1
#	cp "$_lastSeenFile" "$tmpLastSeen"  >/dev/null 2>&1
#	cp "${_path2CurrentMonth}${rawtraffic_hr##/}" "$rawtraffic_hr"  >/dev/null 2>&1
#	#cp "${rawtraffic_day}" "/tmp/yamon/${rawtraffic_day##*$_path2CurrentMonth}"  >/dev/null 2>&1
#	cp  "$rawtraffic_day" "${tmpLastSeen%/*}/${rawtraffic_day##*/}"  >/dev/null 2>&1
#fi


echo -e "//$rebootOrStart" >> "$hourlyDataFile"
Send2Log "YAMon:: $rebootOrStart" 2 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
Send2Log "YAMon:: version $_version	_loglevel: $_loglevel" 1 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
if [ -f "$_usersFile" ] ; then
	if [ -z "$(cat "$_usersFile" | grep "^var users_updated")" ] ;  then
		Send2Log "Start: touch users_updated in $_usersFile" 2 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
		ucl=$(cat "$_usersFile" | grep "^var users_created")
		sed -i "s~$ucl~$ucl\nvar users_updated=\"\"~" "$_usersFile"
	fi
	# Despite uprev.sh being run, this doesn't get updated - nor will it ever.
	# not worth checking - just replace it.
	sed -i "s~users_version=\"[^\"]\{0,\}\"~users_version=\"$_version\"~" "$_usersFile"
else
	CreateUsersFile
fi
SetupIPChains # in /includes/setupIPChains.sh
AddNetworkInterfaces # in /includes/setupIPChains.sh

AddActiveDevices
# FIXME to be sure , to be sure. redundant?
_file_version="${_version%.*}"
_html_version="${_version%.*}"
SetWebDirectories

# restore any existing and current backup files
_backup=${d_baseDir}/data/yamon-$(date +%Y%m%d)

if [ -d "${_backup}" ] ; then
	cp -af "${_backup}/." "$tmplog/"
	Send2Log "Copied contents of ${_backup} back to $tmplog" 0 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
else
	Send2Log "Nothing to restore ${_backup}: doesn't exist" 0 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
fi

"${d_baseDir}/new-day.sh"
"${d_baseDir}/new-hour.sh"
"${d_baseDir}/check-network.sh"

CheckIntervalFiles

StartScheduledJobs

FunctionUsage "Finished" 1 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
