#!/bin/sh
# DEVELOPMENT DEBUG STRIPPED
# Glenn McKechnie - modified 16/06/26 10:30

##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# wraps things up at the end of each day
# run: by cron
# History
# 2026-06-17: Subtle bug in GetField broke sed statements. Recode to add updated string
# 	switch between active '0' and '1' fixed. Delete entries older than 30 days (user
# 	configurable in config.file
# 	_usebydate='30' # Check age of user.js entries, delete after 30 days (the default value)
# 2026-05-22: 4.0.8 - no changes
# 2020-01-26: 4.0.7 - no changes
# 2020-01-03: 4.0.6 - no changes
# 2019-12-23: 4.0.5 - no changes
# 2019-11-24: 4.0.4 - added '2>/dev/null ' to tar call to prevent spurious messages in the logs
# 2019-06-18: development starts on initial v4 release
#
##########################################################################
#	:>'/tmp/TEST/Send2Log.txt'
SsSend2Log(){
	echo "$1" >> '/tmp/TEST/Send2Log.txt'
}


GgGetField(){
	#returns just the first match... duplicates are ignored
	local result=$(echo "$1" | grep -io -m1 "$2\":\"[^\"]\{1,\}" | cut -d\" -f3)
	echo "$result"
	[ -n "$resul_t" ] && { Send2Log  "GetField: line/l_lastseenEntry --> ${1}" ; Send2Log "result  --> ${result}" ;  echo "$result" ; return ; }
	#[ -n "$result" ] && {Send2Log  "GetField: $2=$result in $1 0 ${0##$d_baseDir/} : GetField : Line Number ${LINENO}" && echo "$result" ; return ; }
	[ -z "$result" ] && [ -z "$1" ] && { \
	Send2Log  "GetField: field $2 not found because the search string was empty $1 1 ${0##$d_baseDir/} : GetField: Line Number ${LINENO}" \
	; echo "$result" ; return ; \
	}
	[ -z "$result" ] && { Send2Log "GetField: field '$2' not found in '$1' 1 ${0##$d_baseDir/} : GetField : Line Number ${LINENO};" ; echo "$result" ; }
}


UuUsersJSUpdated(){
	#echo -e  "UsersJSUpdated: users_updated changed to '$_ds $_ts'" 2 "${0##$d_baseDir/} : UsersJSUpdated : Line Number ${LINENO}"
	sed -i "s~users_updated=\"[^\"]\{0,\}\"~users_updated=\"$_ds $_ts\"~" "usersTest-updated.js"
	return

	}

DeactiveIdleDevices(){
	local _activeIPs=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep '"active":"1"')
	# GetField: id='70:8b:cd:c9:63:d8-192.168.1.254' in `mac2ip({ "id":"70:8b:cd:c9:63:d8-192.168.1.254", "name":"intAsus", "active":"1", "added":"2026-05-19 17:48:27", "updated":"" })
	# -->     id 70:8b:cd:c9:63:d8-192.168.1.254
	# -->     l_lastseen 2026-06-16 10:28:01
	local l_lastseenEntry=''
	[ -f "lastseen.js" ] && l_lastseenEntry=$(cat 'lastseen.js' | grep -e "^lastseen({.*})$")
	IFS=$'\n'
	Send2Log "DeactiveIdleDevices - _activeIPs" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number-${LINENO}"
	for line in $_activeIPs ; do
		# update timestamp on active entries that match with last-seen entries
		[ -z "$line" ] && continue
		#  -->     line = mac2ip({ "id":"70:8b:cd:c9:63:d8-192.168.1.254", "name":"intAsus", "active":"1", "added":"2026-05-19 17:48:27", "updated":"" })
		local l_id=$(GetField "$line" 'id')
		local l_lastseen=$(GetField $(echo "$l_lastseenEntry" | grep "$l_id") "last-seen")

		t_date="$(printf '%s' "$l_lastseen" | cut -d' ' -f1)"
		t_time="$(printf '%s' "$l_lastseen" | cut -d' ' -f2)"
		# l_result=$(printf '%s' "$line" | sed -e "s~\"active\":\"[^\"]*\"~\"active\":\"1\"~"  -e "s~\"updated\":\"[^\"]*\"~\"updated\":\"$t_date\" \"$t_time\"~")
		l_result=$(printf '%s' "$line" |  sed "s|\"updated\":\"[^\"]*\"|\"updated\":\"$l_lastseen\"|")
		sed -i "s~$line~$l_result~" "$_usersFile"
		# Now deactivate anything not flagged in last-seen entries
		if [ -z "$l_lastseen" ] ; then
			Send2Log "l_lastseen is empty ?${l_lastseen}? l_id is $l_id in the line (${line})"
			# supplied by shared.sh
			#_ds=$(date +"%Y-%m-%d")
			#_ts=$(date +"%T")
			l_result=$(printf '%s' "$line" | sed -e "s|\"active\":\"[^\"]*\"|\"active\":\"0\"|"  -e "s|\"updated\":\"[^\"]*\"|\"updated\":\"$_ds $_ts\"|")
			#Send2Log "DEACTIVATE --> _ds -> $_ds : _ts -> $_ts : l_result --> $l_result"
			sed -i "s~$line~$l_result~" "$_usersFile"
			Send2Log "DeactiveIdleDevices: $l_id set to inactive (based upon users.js)" 1 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number-${LINENO}"
			local changes1=1
		fi
	done
	[ -z "$changes1" ] && Send2Log "DeactiveIdleDevices: no active devices deactivated" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number-${LINENO}"

	local _inActiveIPs=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep '"active":"0"')
	#Send2Log " _inActiveIPs --> $_inActiveIPs"
	# reactivate inactive entries (using last-seen as the flag)
	Send2Log "DeactiveIdleDevices - lastseen" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number-${LINENO}"
	for line in $l_lastseenEntry ; do
		[ -z "$line" ] && continue
		local l_id=$(GetField "$line" 'id')
		local l_waitingList=$(echo "$_inActiveIPs" | grep "$l_id")
		Send2Log "id -> $l_id : l_waitingList -> $l_waitingList"
		if [ -n "$l_waitingList" ] ; then
			l_activateLine=$(echo "${l_waitingList/\"active\":\"0\"/\"active\":\"1\"}")
			sed -i "s~$l_waitingList~$l_activateLine~" "$_usersFile"
		#	Send2Log "\t ---> sed -i s~$l_waitingList~$l_activateLine~"
			Send2Log "DeactiveIdleDevices: $l_id set to active (based upon lastseen.js)" 1 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number-${LINENO}"
			local changes2=1
		fi
	done

	for line in $_inActiveIPs ; do
		# tag inactive entries that are past their use-by-date. "updated":"DELETE"
		#  -->     line = mac2ip({ "id":"70:8b:cd:c9:63:d8-192.168.1.254", "name":"intAsus", "active":"1", "added":"2026-05-19 17:48:27", "updated":"" })
		[ -z "$line" ] && continue
		local l_id=$(GetField "$line" 'id')
		added=$(printf '%s' "$line" | sed -n 's/.*"added":"\([^"]*\)".*/\1/p')
		updated=$(printf '%s' "$line" | sed -n 's/.*"updated":"\([^"]*\)".*/\1/p')
		now_epoch=$(date +%s)
		# order matters, updated takes precedence, added is the benchmark, null is the 'skip it' alternative.
		Send2Log " update -> $updated  added -> $added "
		# try updated then added; set added_epoch empty on failure; ignore early date errors
		added_epoch=$(date -d "$updated" +%s 2>/dev/null) || \
		added_epoch=$(date -d "$added"   +%s 2>/dev/null) || \
		added_epoch=
		[ -n "$added_epoch" ] && [ $(( (now_epoch - added_epoch) / 86400 )) -ge ${_usebydate:-30} ] && { Send2Log "delete this $line"; \
			l_deleteLine=$(echo "${line/\"updated\":\"*\"/\"updated\":\"DELETE\"}") ; \
			sed -i "s~$line~$l_deleteLine~" "$_usersFile"; \
			Send2Log "DeactiveIdleDevices: tag lines for deletion" 1 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number-${LINENO}"; }
	done
	# Simple copy routing to dump any lines tagged with 'DELETE' in the updated field.
	tmp=$(mktemp) || exit 1
	while IFS= read -r l; do
		active=$(printf '%s' "$l" | sed -n 's/.*"updated":"\([^"]*\)".*/\1/p')
		# skip non-matching lines
		[ "$active" = "DELETE" ] || { printf '%s\n' "$l" >>"$tmp"; continue; }
	done <"$_usersFile"
	chmod 0644 "$tmp"
	mv "$tmp" "$_usersFile"

	[ -z "$changes2" ] && Send2Log "DeactiveIdleDevices: no deactived devices activated" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number-${LINENO}"
	[ -n "$changes1" ] || [ -n "$changes2" ] && UsersJSUpdated
}
d_baseDir=$(cd "$(dirname "$0")" && pwd)
source "${d_baseDir}/includes/shared.sh"
source "${d_baseDir}/includes/dailytotals.sh"

[ -n "$1" ] && _ds="$1"
sleep 75 # wait until all tasks for the day should've been completed... may have to adjust this value

Send2Log "End of day: $_ds" 1 "${0##$d_baseDir/} : Main : Line Number-${LINENO}"
Send2Log "End of day: copy $hourlyDataFile --> $_path2CurrentMonth" 0  "${0##$d_baseDir/} : Main : Line Number-${LINENO}"
cp "$hourlyDataFile" "$_path2CurrentMonth"

#Calculate the daily totals
Send2Log "End of day: tally the traffic for the day and update the monthly file" 0 "${0##$d_baseDir/} : Main : Line Number-${LINENO}"
CalculateDailyTotals ## no param --> implies value of _ds

Send2Log "End of day: backup files as required" 0 "${0##$d_baseDir/} : Main : Line Number-${LINENO}"
cp "$tmplogFile" "$_path2logs"

[ "$_doDailyBU" -eq "1" ] && tar -cf "${_path2bu}bu-${_ds}.tar.gz" $_usersFile $tmpLastSeen $(find -L ${d_baseDir} | grep "$_ds") 2>/dev/null && Send2Log "End of day: archive date specific   files to '${_path2bu}bu-${_ds}.tar.gz'" 0 "${0##$d_baseDir/} : Main : Line Number-${LINENO}"

rm $(find "$tmplog" | grep "$_ds") #delete the date specific files
cp "${_usersFile}" "${_usersFile%.js}-${_ds}-${_ts}.js"
Send2Log  "Copying ${_usersFile} to ${_usersFile%.js}-${_ds}-${_ts}.js" 1 "${0##$d_baseDir/} : Main : Line Number-${LINENO}"

DeactiveIdleDevices

FunctionUsage "Finished" 0 "${0##$d_baseDir/} : Main : Line Number-${LINENO}"
