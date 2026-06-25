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
# 2026-06-17: Subtle bug in GetField broke sed statements. Recode to add "updated" string
# 	delete duplicates (rare), switch between active '0' and '1' (fixed). Delete entries
# 	older than 30 days which is user configurable in config.file and setup4.0.8.sh
# 	_usebydate='30' # Check age of user.js entries, delete after 30 days (the default value)
# 2026-05-22: 4.0.8 - no changes
# 2020-01-26: 4.0.7 - no changes
# 2020-01-03: 4.0.6 - no changes
# 2019-12-23: 4.0.5 - no changes
# 2019-11-24: 4.0.4 - added '2>/dev/null ' to tar call to prevent spurious messages in the logs
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

DeactiveIdleDevices(){
	local _activeIPs=$(cat "$_usersFile" | sort | grep -e "^mac2ip({.*})$" | grep '"active":"1"')
	# GetField: id='70:8b:cd:c9:63:d8-192.168.1.254' in `mac2ip({ "id":"70:8b:cd:c9:63:d8-192.168.1.254", "name":"intAsus", "active":"1", "added":"2026-05-19 17:48:27", "updated":"" })
	# -->     id 70:8b:cd:c9:63:d8-192.168.1.254
	# -->     l_lastseen 2026-06-16 10:28:01
	local l_lastseenEntry=''
	[ -f "$_lastSeenFile" ] && l_lastseenEntry=$(cat "$_lastSeenFile" | grep -e "^lastseen({.*})$")
	IFS=$'\n'
	Send2Log "DeactiveIdleDevices - check _activeIPs against lastseen" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"
	for line in $_activeIPs ; do
		# update timestamp on active entries that match with last-seen entries
		[ -z "$line" ] && continue
		local l_id=$(GetField "$line" 'id')
		local l_lastseen=$(GetField $(echo "$l_lastseenEntry" | grep "$l_id") "last-seen")
		# Is it a duplicate line - rare - (via sort)?
		if [ "$l_id" = "$l_lastid" ] ; then
			l_result=$(printf '%s' "$line" |  sed "s|\"updated\":\"[^\"]*\"|\"updated\":\"DELETE\"|")
			local changes3=1;
		else
		# or a valid line that just needs updating?
			l_result=$(printf '%s' "$line" |  sed "s|\"updated\":\"[^\"]*\"|\"updated\":\"$l_lastseen\"|")
		fi
		local l_lastid=$l_id
		sed -i "s~$line~$l_result~" "$_usersFile"

		# Now deactivate anything not flagged in last-seen entries
		# We won't delete them until usebydate is passed.
		if [ -z "$l_lastseen" ] ; then
			# just deactivate this line, leave expiry to usebydate logic.
			Send2Log "l_lastseen is empty ?${l_lastseen}? l_id is $l_id within (${line})"
			l_result=$(printf '%s' "$line" | sed -e "s|\"active\":\"[^\"]*\"|\"active\":\"0\"|"  -e "s|\"updated\":\"[^\"]*\"|\"updated\":\"$_ds $_ts\"|")
			sed -i "s~$line~$l_result~" "$_usersFile"
			Send2Log "DeactiveIdleDevices: $l_id set to inactive (based upon users.js)" 1 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"
			local changes1=1
		fi
	done
	[ -z "$changes1" ] && Send2Log "DeactiveIdleDevices: no active devices deactivated" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"

	local _inActiveIPs=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep '"active":"0"')
	# reactivate any inactive entries (using last-seen as the flag)
	Send2Log "DeactiveIdleDevices - check _inactiveIPs against lastseen" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"
	for line in $l_lastseenEntry ; do
		[ -z "$line" ] && continue
		local l_id=$(GetField "$line" 'id')
		local l_waitingList=$(echo "$_inActiveIPs" | grep "$l_id")
		Send2Log "id -> $l_id : l_waitingList -> $l_waitingList"
		if [ -n "$l_waitingList" ] ; then
			l_activateLine=$(echo "${l_waitingList/\"active\":\"0\"/\"active\":\"1\"}")
			sed -i "s~$l_waitingList~$l_activateLine~" "$_usersFile"
			Send2Log "DeactiveIdleDevices: $l_id set to active (based upon lastseen.js)" 1 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"
			local changes2=1
		fi
	done
	[ -z "$changes2" ] && Send2Log "DeactiveIdleDevices: no deactived devices activated" 0 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"

	for line in $_inActiveIPs ; do
		# tag inactive entries that are past their use-by-date. ("updated":"DELETE")
		[ -z "$line" ] && continue
		local l_id=$(GetField "$line" 'id')
		added=$(printf '%s' "$line" | sed -n 's/.*"added":"\([^"]*\)".*/\1/p')
		updated=$(printf '%s' "$line" | sed -n 's/.*"updated":"\([^"]*\)".*/\1/p')
		now_epoch=$(date +%s)
		# order matters, updated takes precedence, "added" is the benchmark, null is the 'skip it' alternative.
		# try "updated" then "added"; set added_epoch empty on failure; ignore early date errors
		added_epoch=$(date -d "$updated" +%s 2>/dev/null) || \
		added_epoch=$(date -d "$added"   +%s 2>/dev/null) || \
		added_epoch=
		[ -n "$added_epoch" ] && [ $(( (now_epoch - added_epoch) / 86400 )) -ge ${_usebydate:-30} ] && \
			l_deleteLine=$(printf '%s\n' "$line" | sed 's/"updated":"[^"]*"/"updated":"DELETE"/'); \
			{ Send2Log "Tag this $l_deleteLine for deletion - old and inactive" 4 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"; \
			sed -i "s~$line~$l_deleteLine~" "$_usersFile"; \
			local changes3=1;
			}
	done

	if [ -n "$changes3" ] ; then
		# parse and ignore any lines tagged with 'DELETE' in the updated field.
		tmp=$(mktemp) || exit 1
		l_lastid=''
		while IFS= read -r line; do
			inact_dated=$(printf '%s' "$line" | sed -n 's/.*"updated":"\([^"]*\)".*/\1/p')
			# skip non-matching lines
			[ "$inact_dated" = "DELETE" ] || { printf '%s\n' "$line" >>"$tmp"; continue; }
		done <"${_usersFile}"
		chmod 0644 "$tmp"
		mv "$tmp" "$_usersFile"
		Send2Log "DeactiveIdleDevices: Deleted old & unused lines" 1 "${0##$d_baseDir/} : DeactiveIdleDevices : Line Number ${LINENO}"
	fi
	# just to update the users.js page header.
	[ -n "$changes1" ] || [ -n "$changes2" ] || [ -n "$changes3" ] && UsersJSUpdated
}

d_baseDir=$(cd "$(dirname "$0")" && pwd)
source "${d_baseDir}/includes/shared.sh"
source "${d_baseDir}/includes/dailytotals.sh"

[ -n "$1" ] && _ds="$1"
sleep 75 # wait until all tasks for the day should've been completed... may have to adjust this value

Send2Log "End of day: $_ds" 1 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
Send2Log "End of day: copy $hourlyDataFile --> $_path2CurrentMonth" 0  "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
cp "$hourlyDataFile" "$_path2CurrentMonth"

#Calculate the daily totals
Send2Log "End of day: tally the traffic for the day and update the monthly file" 0 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
CalculateDailyTotals ## no param --> implies value of _ds

Send2Log "End of day: backup files as required" 0 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
cp "$tmplogFile" "$_path2logs"

if [ "$_doDailyBU" -eq 1 ]; then
  if tar -cf "${_path2bu}bu-${_ds}.tar.gz" \
      "$_usersFile" "$tmpLastSeen" \
       $(find -L "$d_baseDir" -type d -path "*/files/*" -prune -o -type f -name "*${_ds}*" -print |grep -v 'files') 2>/dev/null ; \
       rc=$?
  then
    Send2Log "End of day: archive date specific files to '${_path2bu}bu-${_ds}.tar.gz'" \
      0 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
  else
    Send2Log "End of day: archive FAILED (${rc}) for '${_path2bu}bu-${_ds}.tar.gz}'" \
      1 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
  fi
fi

# now archived so delete the date specific files
rm $(find "$tmplog" | grep "$_ds")
cp "${_usersFile}" "${_path2CurrentMonth}users-${_ds}-${_ts}.js"
Send2Log  "Copying ${_usersFile} to ${_path2CurrentMonth}users-${_ds}-${_ts}.js" 1 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"

DeactiveIdleDevices

FunctionUsage "Finished" 0 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
