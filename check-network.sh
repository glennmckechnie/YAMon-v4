#!/bin/sh

##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# checks arp & ip for new devices and/or ip changes on the network
# run: by cron
# History
# 2026-06-09: Fix case logic which bites on occasion?,
# 		minor tweaks to CheckMacIP4Duplicates().
# 2026-05-22: 4.0.8 - no changes
# 2020-03-20: 4.0.8 - from 4.0.8 ---  for mac addresses to lowercase
# 2020-01-26: 4.0.7 - added check for error in Check4UpdatesInReports results
#                   - moved GetDeviceGroup to shared.sh
# 2020-01-03: 4.0.6 - only check dmesg if _logNoMatchingMac==1
# 2019-12-23: 4.0.5 - no changes (yet)
# 2019-11-24: 4.0.4 - added Check4UpdatesInReports to sync group names with reports
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

d_baseDir=$(cd "$(dirname "$0")" && pwd)
source "${d_baseDir}/includes/shared.sh"
source "${d_baseDir}/includes/start-stop.sh"

FunctionUsage "Starting" 2 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"
Send2Log "Checking the network for new devices" 1 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"
_IPCmd='ip neigh show'

# The following statement is upper case specific and that's not going to always work.
excluding='FAILED,STALE,INCOMPLETE,00:00:00:00:00:00' # excludes listed entries from the results
arpResults=$(cat /proc/net/arp | grep "^[1-9]"| tr "[A-Z]" "[a-z]")
#$(IndentList "$iplist")"
Send2Log "Checking the network - arpResults $(IndentList "$arpResults")" 1 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"
#echo -e "\narpResults"
#echo "$arpResults"
# switch '-i' to enforce case insenstivity
arpList=$(echo "$arpResults" | grep -Eiv "(${excluding//,/|})" | awk '{ print $4,$1 }')
Send2Log "Checking the network - arpList $(IndentList " $arpList")" 1 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"
#echo -e "\narpList"
#echo "$arpList"
[ -n "$arpList" ] && Send2Log "Check4NewDevices: arpList: $(IndentList "$arpList")" 4 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"

ipResults=$($_IPCmd | tr "[A-Z]" "[a-z]") # a hack for firmware variants which do not include the full ip command (so `ip neigh show` does not return valid info)
Send2Log "Checking the network - ipResults $(IndentList "$ipResults")" 1 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"
#echo -e "\nipResults"
#echo "$ipResults"
# switch '-i' to enforce case insenstivity
ipList=$(echo "$ipResults" | grep -Eiv "(${excluding//,/|})" | awk '{ print $5,$1 }')
Send2Log "Checking the network - ipList $(IndentList "$ipList")" 1 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"
#echo -e "\nipList"
#echo "$ipList"
#[ -n "$ipList" ] && Send2Log "Check4NewDevices: ipList: $(IndentList "$ipList")" 0 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"

#exit 0


Check4NewDevices(){
	
	FindRefMAC(){
		Send2Log "FindRefMAC: $i $m" 0 "${0##$d_baseDir/} : FindRefMAC : Line Number-${LINENO}"
		
		local fm=$(echo "$macIPList" | grep "\b${i//\./\\.}\b")
		local nm=$(echo "$fm" | wc -l)
		[ -z "$fm" ] && nm=0
		if [ "$nm" -eq "1" ] ; then
			local rm=$(echo "$fm" | cut -d' ' -f1)
			Send2Log "FindRefMAC: MAC changed from $m to $rm" 1 "${0##$d_baseDir/} : FindRefMAC : Line Number-${LINENO}"
			echo "$rm"
			return
		elif [ "$nm" -eq "0" ] ; then
			Send2Log "FindRefMAC: no matching entry for $i in $macIPFile... checking $tmpLastSeen" 1 "${0##$d_baseDir/} : FindRefMAC : Line Number-${LINENO}"
			local fm=''
			[ -f "$tmpLastSeen" ] && fm=$(cat "$tmpLastSeen" | grep -e "^lastseen({.*})$" | grep "\b${i//\./\\.}\b" | grep -v "$_generic_mac")
			local nm=$(echo "$fm" | wc -l)
			[ -z "$fm" ] && nm=0 
			if [ "$nm" -eq "1" ] ; then 
				local rm=$(echo "$(GetField "$fm" 'id')" | cut -d'-' -f1)
				Send2Log "FindRefMAC: MAC changed from $m to $rm in $tmpLastSeen" 1 "${0##$d_baseDir/} : Main start : Line Number-${LINENO}"
				echo "$rm"
				return
			fi
		fi
		
		Send2Log "FindRefMAC: $nm matching entries for $i / $m in $macIPFile & $tmpLastSeen... replaced $m with $_generic_mac" 2 "${0##$d_baseDir/} : FindRefMAC : Line Number-${LINENO}"
		echo "$_generic_mac"

		echo -e "$_ts: $nd\n\tIP: $(echo "$arpResults" | grep "\b$i\b") \n\tarp: $(echo "$ipResults" | grep "\b$i\b" )" >> "${tmplog}bad-mac.txt"
	}
	
	local macIPList=$(cat "$macIPFile" | grep -Ev "^\s{0,}$")

	#Send2Log "Check4NewDevices: starting macIPList--> $(IndentList "$macIPList")" 0 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
	local currentIPList=$(echo "$macIPList" | tr "\n" '|')
	currentIPList=${currentIPList%|}
	local combinedIPArp=$(echo -e "$ipList\n$arpList" | grep -Ev "^\s{0,}$" | sort -u)
	local newIPList=$(echo "$combinedIPArp" | grep -Ev "$currentIPList")
	[ -z "$currentIPList" ] && newIPList=$combinedIPArp

	#Send2Log "Check4NewDevices: currentIPList: $(IndentList "$currentIPList")" 0 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
	
	# add the YAMon entries of dmesg into the logs to see where the unmatched data is coming from (and then clear dmesg)
	[ "${_logNoMatchingMac:-0}" -eq "1" ] && local dmsg=$(dmesg -c | grep YAMon)
	if [ -z "$newIPList" ] ; then
		Send2Log "Check4NewDevices: no new devices... checking that all IP addresses exist in iptables" 4 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
		local ipsFromARP=$(cat /proc/net/arp | grep "^[1-9]" | grep -Ev "(${excluding//,/|})" | awk '{ print $1 }' | sort)
		local iptablesList=$(iptables -L YAMONv40 -vnx | awk '{ print $8 }' | grep -v '0.0.0.0' | sort | grep "^[1-9]" | tr "\n" '|')
		iptablesList="${iptablesList%|}"
		iptablesList="${iptablesList//|/$|}"
		iptablesList="${iptablesList//\./\\.}"

		unmatchedIPs=$(echo "$ipsFromARP" | grep -Ev "${iptablesList%|}")
		for nip in $unmatchedIPs ; do
			local mac=$(GetMACbyIP "$nip")
			local groupName=$(GetDeviceGroup "$mac" "$nip")
			Send2Log "Check4NewDevices: $nip ($mac / $groupName) is missing in iptables" 2 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
			CheckIPTableEntry "$nip" "$groupName"
		done
				
		[ -n "$dmsg" ] && Send2Log "Check4NewDevices: Found YAMon entries in dmesg" 2 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
		IFS=$'\n'
		for line in $dmsg
		do
			#to-do parse lines for MAC & IP
			Send2Log "check-network.sh: dmesg --> $line" 2 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
		done
	else
		#Send2Log "Check4NewDevices: found new IPs: $(IndentList "$newIPList")" 1 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"

		IFS=$'\n'
		local re_mac='([a-f0-9]{2}:){5}[a-f0-9]{2}'
		for nd in $newIPList
		do
			[ -z "$nd" ] && return
			local m=$(echo $nd | cut -d' ' -f1)
			local i=$(echo $nd | cut -d' ' -f2)
			Send2Log "check-network: new device=$nd  ;  ip=$i  ; mac=$m" 1 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
			if [ -z "$(echo "$m" | grep -Ei "$re_mac")" ] ; then 
				Send2Log "Check4NewDevices: Bad MAC --> \n\tIP: $(echo "$arpResults" | grep "\b$i\b") \n\tarp: $(echo "$ipResults" | grep "\b$i\b" )" 2 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
				local rm=$(FindRefMAC)
				newIPList=$(echo "$newIPList" | sed -e "s~$nd~$rm $i~g" | grep -Ev "$currentIPList")
				m=$rm
			fi
			CheckMAC2IPinUserJS "$m" "$i"
			local groupName=$(GetDeviceGroup "$m" "$i")
			CheckMAC2GroupinUserJS "$m" "$groupName"
			CheckIPTableEntry "$i" "$groupName"
			macIPList=$(echo "$macIPList" | grep -v "\b${i//\./\\.}\b")
		done

		[ -z "$newIPList" ] && return
		
		Send2Log "Check4NewDevices: the following new devices were found: $(IndentList "$newIPList")" 1 "${0##$d_baseDir/} : Check4NewDevices : Line Number-${LINENO}"
		echo -e "$macIPList\n$newIPList" | grep -Ev "^\s{0,}$" > "$macIPFile"

	fi
}
ORGCheckMacIP4Duplicates(){
	local macIPList=$(cat "$macIPFile")
	local dups=$(echo -e "$macIPList" | awk '{print $2}' | awk ' { tot[$0]++ } END { for (i in tot) if (tot[i]>1) print tot[i],i } ')
	local combinedIPArp=$(echo -e "$ipList\n$arpList" | grep -Ev "^\s{0,}$" | sort -u)
	[ -z "$dups" ] && Send2Log "CheckMacIP4Duplicates: no duplicate entries in $macIPFile" 1 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}" && return
	IFS=$'\n'
	for line in $dups
	do
		local ip=$(echo "$line" | awk '{ print $2}')
		Send2Log "CheckMacIP4Duplicates: $ip has duplicate entries in $macIPFile" 2 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}"
		macIPList=$(echo -e "$macIPList" | grep -v "${ip//\./\\.}")
		local activeID=$(echo "$combinedIPArp" | grep "${ip//\./\\.}")
		if [ -n "$activeID" ] ; then 
			Send2Log "CheckMacIP4Duplicates: re-added activeID \`$activeID\`" 2 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}"
			macIPList="$macIPList\n$activeID"
		else
			Send2Log "CheckMacIP4Duplicates: no active matches for \`$ip\` in arp & ip lists" 2 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}"
		fi
	done
	echo -e "$macIPList" > "$macIPFile"
}

CheckMacIP4Duplicates(){
	local macIPList combinedIPArp dups line ip activeID
	macIPList=$(<"$macIPFile")
	dups=$(printf '%s\n' "$macIPList" | awk 'NF{tot[$2]++} END{for(i in tot) if(tot[i]>1) print tot[i],i}')
	combinedIPArp=$(printf '%s\n%s\n' "$ipList" "$arpList" | awk 'NF' | sort -u)
	[ -z "$dups" ] && Send2Log "CheckMacIP4Duplicates: no duplicate entries in $macIPFile" 1 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}" && return
	for line in $dups ; do
		ip=$(printf '%s' "$line" | awk '{print $2}')
		Send2Log "CheckMacIP4Duplicates: $ip has duplicate entries in $macIPFile" 2 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}"
		macIPList=$(printf '%s\n' "$macIPList" | awk -v ip="$ip" '$2!=ip')
		activeID=$(printf '%s\n' "$combinedIPArp" | awk -v ip="$ip" '$2==ip {print; exit}')
		if [ -n "$activeID" ]; then
			Send2Log "CheckMacIP4Duplicates: re-added activeID \`$activeID\`" 2 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}"
			macIPList=$(printf '%s\n%s' "$macIPList" "$activeID")
		else
			Send2Log "CheckMacIP4Duplicates: no active matches for \`$ip\` in arp & ip lists" 2 "${0##$d_baseDir/} : CheckMacIP4Duplicates : Line Number-${LINENO}"
		fi
	done
	# atomic commit
	printf '%s\n' "$macIPList" > "$macIPFile.tmp" && mv "$macIPFile.tmp" "$macIPFile"
}

Check4UpdatesInReports(){
	Send2Log "Check4UpdatesInReports: " 0 "${0##$d_baseDir/} : CUIReports : Line Number-${LINENO}"
	local url="www.usage-monitoring.com/current/Check4UpdatesInReports.php?db=$_dbkey"
	local dst="$tmplog/updates.txt"
	local prototol='http://'
	local security_protocol=''
	wget "$prototol$url" $security_protocol -qO "$dst"
	IFS=$';'
	local updates=$(cat $dst | sed -e "s~[{}]~~g")
	[ -z "$updates" ] && Send2Log "Check4UpdatesInReports: No updates from the reports" 2 "${0##$d_baseDir/} : CUIReports : Line Number-${LINENO}"
	for entry in $updates ; do
		[ -z "$entry" ] && continue
		if [ -n "$(echo "$entry" | grep "^Error")" ] ; then
			Send2Log "Check4UpdatesInReports: Error in download --> $entry" 1 "${0##$d_baseDir/} : CUIReports : Line Number-${LINENO}"
		else
			local mac=$(echo $entry | cut -d',' -f1)
			local group=$(echo $entry | cut -d',' -f2)
			Send2Log "Check4UpdatesInReports: mac->$mac & group -> $group" 2 "${0##$d_baseDir/} : CUIReports : Line Number-${LINENO}"
			Send2Log "Check4UpdatesInReports: checking $mac / $group" 1 "${0##$d_baseDir/} : CUIReports : Line Number-${LINENO}"
			CheckMAC2GroupinUserJS $mac $group
		fi
	done
}

if [ -n "$_dbkey" ] ; then
	Check4UpdatesInReports
	SetAccessRestrictions
fi

Check4NewDevices

CheckMacIP4Duplicates

FunctionUsage "Finished" 2 "${0##$d_baseDir/} : Main - end : Line Number-${LINENO}"
