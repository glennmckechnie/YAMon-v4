#!/bin/sh
##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# Copyright (c) 2025 Glenn McKechnie
# All rights reserved.
#
# various utility functions (shared between one or more scripts)
#
# History
#
# 2026-06-13: Rework ChangePath to add an "updated" tag. new-day.sh
#       FIXME fails to update it's paths why?
#             Add CalcReportSpan() for logging and debug purposes.
# 2026-06-09: Add debug switch to quieten pop-up output (Send2Log)
#	Also debug iinformation for logs pop-up on date field
#	Usage: Send2Log "message" "log level" "line number"
#	where "line number" field consists of "filename, function name, ${LINENO}"
# 2026-06-02: Create HTMLHeaders to consolidate end-of-hour.sh and new-day.sh
# 	log header duplication. Create extra debug levels with supporting code
# 	See logs.css too.
# 2026-05-22: 4.0.8 - add copy routine to preserve data files
# 2025-02-26: refine,fix typo in var length test.
# 2020-03-19: 4.0.7 - added static leases for Tomato (thx tvlz)
#	- added wait option ( -w -W1) to commands that add entries in iptables
#	- then added _iptablesWait 'cause not all firmware variants support iptables -w...
#	- combined StaticLeases_Merlin & StaticLeases_Tomato into StaticLeases_Merlin_Tomato
#	- added GetMACbyIP & GetDeviceGroup (from traffic & check-network)
# 2020-01-03: 4.0.6 - no changes
# 2019-12-23: 4.0.5 - changed loglevel of start messages in logs
# 2019-11-24: 4.0.4 - no changes (yet)
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

# debug: for development
debug='yes' # Send2Log, include supplied LINENO debug info
#debug='' # Send2Log, skip LINENO debug info

_ds=$(date +"%Y-%m-%d")
_ts=$(date +"%T")
_generic_mac="un:kn:ow:n0:0m:ac"

source "${d_baseDir}/includes/version.sh"
source "${d_baseDir}/config.file"
source "${d_baseDir}/includes/paths.sh"
source "$d_baseDir/strings/${_lang:-en}/strings.sh"


tmplog='/tmp/yamon/'
[ -d "$tmplog" ] || mkdir -p "$tmplog"
tmplogFile='/tmp/yamon/yamon.log'

# NB: showEcho can be useful!
[ -z "$showEcho" ] && exec >> $tmplogFile 2>&1 # send error messages to the log file as well!

[ -f "$_usersFile" ] && _currentUsers=$(cat "$_usersFile")

Send2Log(){
	# Usage: Send2Log "message" "log level" "line number"
	[ "${2:-0}" -lt "${_loglevel:-0}" ] && return
	# decide whether to include the pop-up LINENO information.
	if [ -z "$debug" ]; then
		l_debug_string="debug is off"
	else
		l_debug_string="${3}"
	fi
	# OLD # echo -e "<section class='ll${2:-0}'><article class='dt'>$(date +"%T")</article><article class='msg'>$1</article></section>" >> "$tmplogFile"
	echo -e "<section class='ll${2:-0}' aria-label='Log entry'><article class='dt' aria-label='Time' title='${l_debug_string}'>$(date +"%T")</article><article class='msg' aria-label='Message'>$1</article></section>" >> "$tmplogFile"
}

Send2Log "${0##$d_baseDir/} is sourcing this file (shared.sh)" 0 "${0##$d_baseDir/} : Main start : Number ${LINENO}"

IndentList(){
	echo '<ul>'
	# OLD # echo -e "$1" | grep -Ev "^\s{0,}$" | sed -e "s~^\s\{0,\}~<li>~Ig"
	echo -e "$1" | grep -Ev '^[[:space:]]*$' | sed 's~^[[:space:]]*\(.*\)$~<li>\1</li>~'
	echo '</ul>'
}


SetRenice(){
	# if firmware supports renice, set the value
	#Send2Log "SetRenice: renice 10 $$" 1
	renice 10 $$
}
NoRenice(){
	# if firmware doesn't support renice
	#Send2Log "NoRenice" 1
	return
}
$_setRenice

LogStartOfFunction(){
# unused
	Send2Log "${0##$d_baseDir/} - $1" "$2" "$3"
}

FunctionUsage(){
	#Send2Log "${0##$d_baseDir/} - $1" "$2" "$3"
	# temporary override
	Send2Log "${0##$d_baseDir/} - $1" "3" "$3"
}

CalcReportSpan(){
        local t_realhr t_realmin t_realsec t_dechr t_decmin t_interval t_delta t_carry t_strthr t_strtmin t_stamp
	t_realhr=$(echo "$_ts" | cut -d':' -f1)
	t_realmin=$(echo "$_ts" | cut -d':' -f2)
	t_realsec=$(echo "$_ts" | cut -d':' -f3)

	# improved diff calculation (cosmetic)
	t_dechr=${t_realhr#0}; t_decmin=${t_realmin#0} # octal (padded0) to decimal !
	t_delta=$(( ${t_decmin#0} - ${1}))
	t_strtmin=$(( (t_delta % 60 + 60) % 60 ))
	t_carry=$(( (t_delta - t_strtmin) / 60 ))   # negative or zero
	#t_delta=$(printf '%02d' "$t_delta")
	t_strthr=$((${t_dechr} + t_carry))
	if [ $t_strthr -lt '0' ] ;  then t_strthr='23' ; fi # adjust for hour rollback
	t_strtmin=$(printf '%02d' "${t_strtmin:-0}")

	echo "$t_strthr:$t_strtmin:$t_realsec -> $t_realhr:$t_realmin:$t_realsec"
	#t_reportSpan="$t_strthr:$t_strtmin -> $t_realhr:$t_realmin"
	#echo "${t_reportSpan}"
}

AddEntry(){
	local l_param l_value l_pathsFile l_strUpdated l_escValue l_line
	l_param="${1//./_}" # when do we pass dotted l_params?
	l_value="$2"
	l_pathsFile="${3:-${d_baseDir}/includes/paths.sh}"
	l_strUpdated="$4" # only when called via ChangePath()

	# escape single quotes for embedding inside single quotes: ' -> '\''
	l_escValue=$(printf "%s" "$l_value" | sed "s/'/'\\\\''/g")
	l_line="${l_param}='${l_escValue}'"
	[ -n "$l_strUpdated" ] && l_line="$l_line $l_strUpdated"
	if grep -q -E "^[[:space:]]*${l_param}[[:space:]]*=" "$l_pathsFile"; then
		sed -i "s~^[[:space:]]*${l_param}[[:space:]]*=.*~${l_line}~" "$l_pathsFile"
		Send2Log "Updated paths.sh with $l_line" 2 "${0##$d_baseDir/} : AddEntry : Line Number ${LINENO}"
	else
		printf '%s\n' "$l_line" >> "$l_pathsFile"
		Send2Log "Added new entry to paths.sh -> $l_line" 2 "${0##$d_baseDir/} : AddEntry : Line Number ${LINENO}"
	fi
}

ChangePath(){
	# changes a value in the user generated includes/paths.sh, adds an updated tag.
	AddEntry "$1" "$2" "$3" "        # re-generated $_ds $_ts"
}
CheckGroupChain(){
	Send2Log "CheckGroupChain: $1 / $2 " 0 "${0##$d_baseDir/} : CheckGroupChain: Line Number ${LINENO}"
	local cmd="$1"
	local groupName="${2:-Unknown}"
	local groupChain="${YAMON_IPTABLES}_$(echo $groupName | sed "s~[^a-z0-9]~~ig")"
	if [ -z "$($cmd -L | grep '^Chain' | grep "$groupChain\b")" ] ; then
		Send2Log "CheckGroupChain: Adding group chain to iptables: $groupChain " 2 "${0##$d_baseDir/} : CheckGroupChain: Line Number ${LINENO}"
		eval $cmd -N "$groupChain" "$_iptablesWait"
		eval $cmd -A "$groupChain" -j "RETURN" "$_iptablesWait"
	fi
}
GetMACbyIP(){
	# first check arp
	local ip="$1"
	local tip="\b${ip//\./\\.}\b"

	local mip=$(cat /proc/net/arp | grep "$tip" | awk '{print $4}')
	if [ -n "$mip" ] ; then
		echo "$mip"
		return
	fi

	# then check users.js
	local dd=$(echo "$_currentUsers" | grep -e "^mac2ip({.*})$" | grep "$tip")
	if [ -z "$dd" ] ; then
		Send2Log "GetMACbyIP - no matching entry for $ip in users.js $(IndentList $dd)" 2 "${0##$d_baseDir/} : GetMACbyIP: Line Number ${LINENO}"
	else
		local id=$(GetField "$dd" 'id')
		local mac=$(echo "$id"| cut -d- -f1)
		Send2Log "GetMACbyIP - $ip --> $id --> $mac" 0 "${0##$d_baseDir/} : GetMACbyIP: Line Number ${LINENO}"
		[ -n "$mac" ] && echo "$mac"
	fi
}

GetDeviceGroup(){
	local mgList=$(echo "$_currentUsers" | grep -e "^mac2group({.*})$")
	local dd=$(echo "$mgList" | grep "$1")
	if [ -z "$dd" ] ; then
		Send2Log "GetDeviceGroup - no matching entry for $1 in users.js... set to '$_defaultGroup' " 2 "${0##$d_baseDir/} : GetDeviceGroup: Line Number ${LINENO}" #to do...
		echo "${_defaultGroup:-${_defaultOwner:-Unknown}}"
		return
	fi
	local group=$(GetField "$dd" 'group')

	Send2Log "GetDeviceGroup - $1 / $2 --> $dd --> $group" 0 "${0##$d_baseDir/} : GetDeviceGroup: Line Number ${LINENO}"
	echo "$group"
}

CheckIPTableEntry(){

	Send2Log "CheckIPTableEntry: $1 / $2 " 0 "${0##$d_baseDir/} : CheckIPTableEntry: Line Number ${LINENO}"

	local ip=$1
	local groupName=${2:-Unknown}
	local chain="$YAMON_IPTABLES"
	Send2Log "CheckIPTableEntry: ip=$ip / cmd=$cmd / chain=$YAMON_IPTABLES " 0 "${0##$d_baseDir/} : CheckIPTableEntry: Line Number ${LINENO}"

	re_ip4="([0-9]{1,3}\.){3}[0-9]{1,3}"
	#if [ -n "$(echo $ip | egrep "$re_ip4")" ] ; then # simplistically matches IPv4
	if [ -n "$(echo $ip | grep -E "$re_ip4")" ] ; then # simplistically matches IPv4
		local cmd='iptables'
		local g_ip='0.0.0.0/0'
	else
		[ -z "$ip6Enabled" ] && Send2Log "CheckIPTableEntry: skipping ip6tables check for $ip as IPv6 is not enabled" 1 "${0##$d_baseDir/} : CheckIPTableEntry: Line Number ${LINENO}"&& return
		local cmd='ip6tables'
		local g_ip='::/0'
	fi
	Send2Log "CheckIPTableEntry: checking $cmd for $ip" 0 "${0##$d_baseDir/} : CheckIPTableEntry: Line Number ${LINENO}"

	ClearDuplicateRules(){
		local n=1
		while [ true ]; do
			[ -z "$ip" ] && break
			local dup_num=$($cmd -L "$YAMON_IPTABLES" -n --line-numbers | grep -m 1 -i "\b$ip\b" | cut -d' ' -f1)
			[ -z "$dup_num" ] && break
			eval $cmd -D "$YAMON_IPTABLES" $dup_num "$_iptablesWait"
			n=$(( $n + 1 ))
		done
		Send2Log "ClearDuplicateRules: removed $n duplicate entries for $ip" 0 "${0##$d_baseDir/} : ClearDuplicateRules : Line Number ${LINENO}"
	}
	AddIP(){
		local groupChain="${YAMON_IPTABLES}_$(echo $groupName | sed "s~[^a-z0-9]~~ig")"
		Send2Log "AddIP: $cmd $YAMON_IPTABLES $ip --> $groupChain (firmware: $_firmware)" 0 "${0##$d_baseDir/} : AddIP : Line Number ${LINENO}"
		if [ "$_firmware" -eq "0" ] && [ "$cmd" == 'ip6tables' ] ; then
			eval $cmd -I "$YAMON_IPTABLES" -j "RETURN" -s $ip "$_iptablesWait"
			eval $cmd -I "$YAMON_IPTABLES" -j "RETURN" -d $ip "$_iptablesWait"
			eval $cmd -I "$YAMON_IPTABLES" -j "$groupChain" -s $ip "$_iptablesWait"
			eval $cmd -I "$YAMON_IPTABLES" -j "$groupChain" -d $ip "$_iptablesWait"
		else
			eval $cmd -I "$YAMON_IPTABLES" -g "$groupChain" -s $ip "$_iptablesWait"
			eval $cmd -I "$YAMON_IPTABLES" -g "$groupChain" -d $ip "$_iptablesWait"
			Send2Log "AddIP: $cmd -I "$YAMON_IPTABLES" -g "$groupChain" -s $ip" 0 "${0##$d_baseDir/} : AddIP : Line Number ${LINENO}"
		fi
	}

	[ "$ip" == "$g_ip" ] && return
	local tip="\b${ip//\./\\.}\b"
	local nm=$($cmd -L "$YAMON_IPTABLES" -n | grep -ic "$tip")

	if [ "$nm" -eq "2" ] || [ "$nm" -eq "4" ] ; then #correct number of entries
		Send2Log "CheckIPTableEntry: $nm matches for $ip in $cmd / $YAMON_IPTABLES" 0 "${0##$d_baseDir/} : CheckIPTableEntry: Line Number ${LINENO}"
		return
	fi

	CheckGroupChain $cmd $groupName

	if [ "$nm" -eq "0" ]; then
		Send2Log "CheckIPTableEntry: no match for $ip in $cmd / $YAMON_IPTABLES" 0 "${0##$d_baseDir/} : CheckIPTableEntry: Line Number ${LINENO}"
	else
		Send2Log "CheckIPTableEntry: Incorrect number of rules for $ip in $cmd / $YAMON_IPTABLES -> $nm... removing duplicates\n\t$cmd -L "$YAMON_IPTABLES" | grep -ic "$tip"" 3 "${0##$d_baseDir/} : CheckIPTableEntry: Line Number ${LINENO}"
		ClearDuplicateRules
	fi
	AddIP
}
UpdateLastSeen(){
	local id="$1"
	local tls="$2"

	local lsd="$_ds $tls"
	Send2Log "UpdateLastSeen: Updating last seen for '$id' to '$lsd'" 0 "${0##$d_baseDir/} : UpdateLastSeen : Line Number ${LINENO}"
	echo -e "lastseen({ \"id\":\"$id\", \"last-seen\":\"$lsd\" })\n$(cat "$tmpLastSeen" | grep -e "^lastseen({.*})$" | grep -v "$id")" > "$tmpLastSeen"
}
GetField(){
	#returns just the first match... duplicates are ignored
	local result=$(echo "$1" | grep -io -m1 "$2\":\"[^\"]\{1,\}" | cut -d\" -f3)
	echo "$result"
	# use a subshell for isolation.
	[ -n "$result" ] && { Send2Log "GetField: $2='$result' in \`$1\`" 0 "${0##$d_baseDir/} : GetField : Line Number ${LINENO}"; return; }
	[ -z "$result" ] && [ -z "$1" ] && { \
	Send2Log "GetField: field '$2' not found because the search string was empty (\`$1\`)" 1 "${0##$d_baseDir/} : GetField: Line Number ${LINENO}"; \
	return; }
	[ -z "$result" ] && { Send2Log "GetField: field '$2' not found in \`$1\`" 1 "${0##$d_baseDir/} : GetField : Line Number ${LINENO}"; }
}
UsersJSUpdated(){
	sed -i "s~users_updated=\"[^\"]\{0,\}\"~users_updated=\"$_ds $_ts\"~" "$_usersFile"
	Send2Log "UsersJSUpdated: users_updated changed to '$_ds $_ts'" 2 "${0##$d_baseDir/} : UsersJSUpdated : Line Number ${LINENO}"
}
UpdateField(){
	local cl="$1" #current line of text
	local wf="$2" #which field to update
	local nv="$3" #new value
	local result=$(echo "$cl" | sed -e "s~\"$wf\":\"[^\"]\{0,\}\"~\"$wf\":\"$nv\"~" -e "s~\"updated\":\"[^\"]\{0,\}\"~\"updated\":\"$_ds $_ts\"~")
	[ -z "$result" ] && Send2Log "UpdateField: replacement of $wf failed" 2 "${0##$d_baseDir/} : UpdateField : Line Number ${LINENO}"
	echo "$result"
}
GetDeviceName(){
	local mac="$1"
	NullFunction(){ #do nothing
		echo ''
	}

	DNSMasqConf(){
		local mac="$1"
		local result=$(echo "$(cat $_dnsmasq_conf | grep -i "dhcp-host=")" | grep -i "$mac" | cut -d, -f$deviceNameField)
		Send2Log "DNSMasqConf: result=$result" 0 "${0##$d_baseDir/} : DNSMasqConf : Line Number ${LINENO}"
		echo "$result"
	}
	DNSMasqLease(){
		local mac="$1"
		local dnsmasq=''
		[ -f "$_dnsmasq_leases" ] && local dnsmasq=$(cat "$_dnsmasq_leases")
		local result=$(echo "$dnsmasq" | grep -i "$mac" | tr '\n' ' / ' | cut -d' ' -f4)
		Send2Log "DNSMasqLease: result=$result" 0 "${0##$d_baseDir/} : DNSMasqLease : Line Number ${LINENO}"
		echo "$result"
	}
	StaticLeases_DDWRT(){
		local mac="$1"
		local nvr=$(nvram show 2>&1 | grep -i "static_leases=")
		local result=$(echo "$nvr" | grep -io "$mac[^=]*=.\{1,\}=.\{1,\}=" | cut -d= -f2)
		Send2Log "StaticLeases_DDWRT: result=$result" 0 "${0##$d_baseDir/} : StaticLeases_DDWRT : Line Number ${LINENO}"
		echo "$result"
	}
	StaticLeases_OpenWRT(){
		local mac="$1"
		# thanks to Robert Micsutka for providing this code & easywinclan for suggesting & testing improvements!
		local result=''
		local ucihostid=$(uci show dhcp | grep -i $mac | cut -d. -f2)
		[ -n "$ucihostid" ] && local result=$(uci get dhcp.$ucihostid.name)
		Send2Log "StaticLeases_OpenWRT: result=$result " 0 "${0##$d_baseDir/} : StaticLeases_OpenWRT : Line Number ${LINENO}"
		echo "$result"
	}
	StaticLeases_Merlin_Tomato(){
		local mac="$1"
		if [ "$_firmware" -eq "3" ] ; then
			local dhcp_str='dhcpd_static'
		else
			local dhcp_str='dhcp_staticlist'
		fi
		#thanks to Chris Dougherty for providing Merlin code, and
		#to Tvlz for providing Tomato Nvram settings
		local nvr=$(nvram show 2>&1 | grep -i "${dhcp_str}=")
		local nvrt=$nvr
		local nvrfix=''
		while [ "$nvrt" ] ;do
			iter=${nvrt%%<*}
			nvrfix="$nvrfix$iter="
			[ "$nvrt" = "$iter" ] && \
				nvrt='' || \
				nvrt="${nvrt#*<}"
		done
		nvr=${nvrfix//>/=}
		local result=$(echo "$nvr" | grep -io "$mac[^=]*=.\{1,\}=.\{1,\}=" | cut -d= -f3)
		Send2Log "StaticLeases_Merlin_Tomato: result=$result " 0 "${0##$d_baseDir/} : StaticLeases_Merlin_Tomato : Line Number ${LINENO}"
		echo "$result"
	}

	Send2Log "GetDeviceName: $1 $2" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"
	#check first in static leases
	local dn=`$nameFromStaticLeases "$mac"`
	if [ -n "${dn/$/}" ] ; then
		Send2Log "GetDeviceName: found device name $dn for $mac in static leases ($nameFromStaticLeases)" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"
		echo "$dn"
		return
	fi
	Send2Log "GetDeviceName: No device name for $mac in static leases ($nameFromStaticLeases)" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"

	#then in DNSMasqConf
	dn=`$nameFromDNSMasqConf "$mac"`
	if [ -n "${dn/$/}" ] ; then
		Send2Log "GetDeviceName: found device name $dn for $mac in $_dnsmasq_conf" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"
		echo "$dn"
		return
	fi
	Send2Log "GetDeviceName: No device name for $mac in in $_dnsmasq_conf ($nameFromDNSMasqConf)" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"

	#finally in DNSMasqLease
	dn=`$nameFromDNSMasqLease "$mac"`
	if [ -n "${dn/$/}" ] ; then
		Send2Log "GetDeviceName: found device name $dn for $mac in $_dnsmasq_leases" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"
		echo "$dn"
		return
	fi
	Send2Log "GetDeviceName: No device name for $mac in in $_dnsmasq_leases ($nameFromDNSMasqLease)" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"

	#Dang... no matches
	local big=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep -o "\"$_defaultDeviceName-[^\"]\{0,\}\"" | sort | tail -1 | tr -d '"' | cut -d- -f2)
	local nextnum=$(printf %02d $(( $(echo "${big#0} ")+ 1 )))
	echo "$_defaultDeviceName-$nextnum"
	Send2Log "GetDeviceName: did not find name for $mac... defaulting to $_defaultDeviceName-$nextnum" 0 "${0##$d_baseDir/} : GetDeviceName : Line Number ${LINENO}"
}

CheckMAC2GroupinUserJS(){
	Send2Log "CheckMAC2GroupinUserJS: $1 $2" 2 "${0##$d_baseDir/} : ChangeMACGroupinUserJS : Line Number ${LINENO}"
	local m=$1
	local gn=${2:-${_defaultGroup:-${_defaultOwner:-Unknown}}}

	ChangeMACGroup(){
		Send2Log "ChangeMACGroup: group names do not match! $gn !== $cgn " 2 "${0##$d_baseDir/} : ChangeMACGroup : Line Number ${LINENO}"
		local newLine=$(UpdateField "$matchesMACGroup" 'group' "$gn")
		local groupChain="${YAMON_IPTABLES}_$(echo $gn | sed "s~[^a-z0-9]~~ig")"
		sed -i "s~$matchesMACGroup~$newLine~" $_usersFile
		#To do - change entries in ip[6]tables
		# iptables -E YAMONv40_Interfaces2 YAMONv40_Interfaces
		local matchingMACs=$(cat "$_usersFile" | grep -e "^mac2ip" | grep "\"active\":\"1\"")
		IFS=$'\n'
		for line in $matchingMACs ; do
			[ -z "$line" ] && continue
			local id=$(GetField $line 'id')
			[ -z "$id" ] && continue
			local mm=$(echo "$id" | cut -d'-' -f1)
			local ii=$(echo "$id" | cut -d'-' -f2)

			re_ip4="([0-9]{1,3}\.){3}[0-9]{1,3}"
			if [ -n "$(echo $ip | grep -E "$re_ip4")" ] ; then # simplistically matches IPv4
				local cmd='iptables'
			else
				local cmd='ip6tables'
			fi
			Send2Log "ChangeMACGroup: changing chain destination for $ii in $cmd ($gn)" 2 "${0##$d_baseDir/} : ChangeMACGroup : Line Number ${LINENO}"

			local matchingRules=$($cmd -L ${YAMON_IPTABLES} -n --line-numbers | grep "\b${ii//\./\\.}\b")
			for rule in $matchingRules ; do
				[ -z "$rule" ] && continue
				local ln=$(echo $rule | awk '{print $1}')
				eval $cmd -R ${YAMON_IPTABLES} $ln -j $groupChain "$_iptablesWait"
				Send2Log "ChangeMACGroup: changing destination of $rule to $gn" 2 "${0##$d_baseDir/} : ChangeMACGroup : Line Number ${LINENO}"
			done
		done
		UsersJSUpdated
	}

	AddNewMACGroup(){
		Send2Log "AddNewMACGroup: adding mac2group entry for $m & $gn" 2 "${0##$d_baseDir/} : AddNewMACGroup : Line Number ${LINENO}"
		local newentry="mac2group({ \"mac\":\"$m\", \"group\":\"$gn\" })"
		sed -i "s~//MAC -> Groups~//MAC -> Groups\n$newentry~g" "$_usersFile"
		UsersJSUpdated
	}

	local matchesMACGroup=$(cat "$_usersFile" | grep -e "^mac2group({.*})$" | grep "\"mac\":\"$m\"")

	if [ -z "$matchesMACGroup" ] ; then
		AddNewMACGroup
	elif [ "$(echo $matchesMACGroup | wc -l)" -eq 1 ] ; then
		local cgn=$(GetField "$matchesMACGroup" 'group')
		#To do - check that the group names match
		[ -n "$2" ] && [ "$gn" == "$cgn" ] || ChangeMACGroup
	else
		Send2Log "CheckDeviceInUserJS: uh-oh... *$matchesMACGroup* mac2group matches for '$m' in '$_usersFile' --> $(IndentList "$(cat "$_usersFile" | grep -e "^mac2group({.*})$" | grep "\"id\":\"$m\"")")" 2 "${0##$d_baseDir/} : CheckMAC2GroupinUserJS : Line Number ${LINENO}"
	fi
}
CheckMAC2IPinUserJS(){
	Send2Log "CheckMAC2IPinUserJS: $1 $2" 0 "${0##$d_baseDir/} :CheckMAC2IPinUserJS : Line Number ${LINENO}"
	local m=$1
	local i=$2
	local dn=$3
	DeactivatebyIP(){
		Send2Log "DeactivatebyIP: $i" 0 "${0##$d_baseDir/} :CheckMAC2IPinUserJS : Line Number ${LINENO}"
		local otherswithIP=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep "\b${i//\./\\.}\b" | grep "\"active\":\"1\"")
		if [ -z "$otherswithIP" ] ; then
			Send2Log "DeactivatebyIP: no active duplicates of $i in $_usersFile" 0 "${0##$d_baseDir/} :CheckMAC2IPinUserJS : Line Number ${LINENO}"
			return
		fi
		Send2Log "DeactivatebyIP: $(echo "$otherswithIP" | wc -l) active duplicates of $i in $_usersFile" 0 "${0##$d_baseDir/} :CheckMAC2IPinUserJS : Line Number ${LINENO}"
		IFS=$'\n'
		for od in $otherswithIP
		do
			Send2Log "DeactivatebyIP: set active=0 in $od" 0 "${0##$d_baseDir/} : CheckMAC2IPinUserJS: Line Number ${LINENO}"
			local nl=$(UpdateField "$od" 'active' '0')
			local nl=$(UpdateField "$nl" 'updated' "$_ds $_ts")
			sed -i "s~$od~$nl~g" "$_usersFile"
			local changes=1
		done
		[ -n "$changes" ] && UsersJSUpdated
	}
	AddNewMACIP(){
		Send2Log "AddNewMACIP: $m $i $dn" 0 "${0##$d_baseDir/} : AddNewMACIP : Line Number ${LINENO}"
		DeactivatebyIP
		[ -z "$dn" ] && local otherswithMAC=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep -m1 "$m") #NB - specifically looks for just one match
		if [ -n "$otherswithMAC" ] ; then
			local dn=$(GetField "$otherswithMAC" 'name')
			Send2Log "AddNewMACIP: copying device name '$dn' from $otherswithMAC" 0 "${0##$d_baseDir/} : AddNewMACIP: Line Number ${LINENO}"
			if [ -n "$(echo "$dn" | grep $_defaultDeviceName )" ] ; then
				local ndn=$(GetDeviceName "$m" "$i")
				[ -z "$(echo "$ndn" | grep $_defaultDeviceName )" ] && dn="$ndn"
			fi
		elif [ -z "$dn" ] ; then
			local dn=$(GetDeviceName "$m" "$i")
			Send2Log "Otherwise..." 0 "${0##$d_baseDir/} : AddNewMACIP: Line Number ${LINENO}"
		fi
		local newentry="mac2ip({ \"id\":\"$m-$i\", \"name\":\"${dn:-New Device}\", \"active\":\"1\", \"added\":\"${_ds} ${_ts}\", \"updated\":\"\" })"
		Send2Log "AddNewMACIP: adding $newentry to $_usersFile" 0 "${0##$d_baseDir/} : AddNewMACIP : Line Number ${LINENO}"
		sed -i "s~//MAC -> IP~//MAC -> IP\n$newentry~g" "$_usersFile"
		UpdateLastSeen "$m-$i" "$(date +"%T")"
		UsersJSUpdated
	}

	local matchesMACIP=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep "\"id\":\"$m-$i\"")
	if [ -z "$matchesMACIP" ] ; then
		AddNewMACIP
	elif [ "$(echo $matchesMACIP | wc -l)" -eq 1 ] ; then
		Send2Log "CheckMAC2IPinUserJS: found a unique match for $m-$i" 0 "${0##$d_baseDir/} : CheckMAC2IPinUsersJS : Line Number ${LINENO}"
		[ -z "$dn" ] && return
		# To do: check that the name matches
	else
		Send2Log "CheckMAC2IPinUserJS: uh-oh... *$matchesMACIP* matches for '$m-$i' in '$_usersFile' --> $(IndentList "$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep "\"id\":\"$m-$i\"")")" 2 "${0##$d_baseDir/} : CheckMAC2IPinUserJS : Line Number ${LINENO}"
	fi
}

AddActiveDevices(){
	Send2Log "AddActiveDevices" 0 "${0##$d_baseDir/} : AddActiveDevices : Line Number ${LINENO}"
	local _ActiveIPs=$(cat "$_usersFile" | grep -e "^mac2ip({.*})$" | grep '"active":"1"')
	local _MACGroups=$(cat "$_usersFile" | grep -e "^mac2group({.*})$")
	local currentMacIP=$(cat "$macIPFile")
	local adl=$(echo "$_currentUsers" | grep '"active":"1"')
	IFS=$'\n'
	for device in $_ActiveIPs
	do
		local id=$(GetField $device 'id')
		local ip=$(echo "$id" | cut -d'-' -f2)
		[ -z "$ip" ] && Send2Log "AddActiveDevices --> IP is null --> $device" 0 "${0##$d_baseDir/} : AddActiveDevices: Line Number ${LINENO}" && continue
		[ "$_generic_ipv4" == "$ip" ] || [ "$_generic_ipv6" == "$ip" ] && continue
		local mac=$(echo "$id" | cut -d'-' -f1)
		local group=$(GetField "$(echo "$_MACGroups" | grep "$mac")" 'group')

		Send2Log "AddActiveDevices --> $id / $mac / $ip / ${group:-Unknown} " 0 "${0##$d_baseDir/} : AddActiveDevices: Line Number ${LINENO}"
		if [ -z "$(echo "$currentMacIP" | grep "${ip//\./\\.}" )" ] ; then
			Send2Log "AddActiveDevices --> IP $ip does not exist in $macIPFile... added to the list" 0 "${0##$d_baseDir/} : AddActiveDevices: Line Number ${LINENO}"
		else
			Send2Log "AddActiveDevices --> IP $ip exists in $macIPFile... deleted entries $(IndentList "$(echo "$currentMacIP" | grep "${ip//\./\\.}" )")" 2 "${0##$d_baseDir/} : AddActiveDevices: Line Number ${LINENO}"
			echo -e "$macIPList" | grep -Ev "${ip//\./\\.}" > "$macIPFile"
		fi
		Send2Log "AddActiveDevices --> $id added to $macIPFile" 1 "${0##$d_baseDir/} : AddActiveDevices : Line Number ${LINENO}"
		echo "$mac $ip" >> "$macIPFile"

		CheckIPTableEntry "$ip" "${group:-Unknown}"
	done
	Send2Log "AddActiveDevices: macipList --> $(IndentList "$(cat "$macIPFile")")" 0 "${0##$d_baseDir/} : AddActiveDevices: Line Number ${LINENO}"
}

DigitAdd(){
	local n1 n2 max_digits l1 l2 carry total d1 d2 s sum
	n1=${1:-0}
	n2=${2:-0}
	max_digits=${_max_digits:-12}
	if [ "${#n1}" -lt "$max_digits" ] && [ "${#n2}" -lt "$max_digits" ] ; then
		echo $(($n1+$n2))
		# Send2Log "DigitAdd: $1 + $2 = $total" 0 "${0##$d_baseDir/} : DigitAdd: Line Number ${LINENO}"
		return
	fi
	l1=${#n1}
	l2=${#n2}
	carry=0
	total=''
	while [ "$l1" -gt "0" ] || [ "$l2" -gt "0" ]; do
		d1=0
		d2=0
		l1=$(($l1-1))
		l2=$(($l2-1))
		[ "$l1" -ge "0" ] && d1=${n1:$l1:1}
		[ "$l2" -ge "0" ] && d2=${n2:$l2:1}
		s=$(($d1+$d2+$carry))
		sum=$(($s%10))
		carry=$(($s/10))
		total="$sum$total"
	done
	[ "$carry" -eq "1" ] && total="$carry$total"
	echo ${total:-0}
	Send2Log "Large number DigitAdd: $1 + $2 = $total" 0 "${0##$d_baseDir/} : DigitAdd: Line Number ${LINENO}"
}
CheckIntervalFiles(){
# create the data directory
	[ -f "$_intervalDataFile" ] && Send2Log "CheckIntervalFiles: interval file exists: $_intervalDataFile" 1 "${0##$d_baseDir/} : CheckIntervalFiles : Line Number ${LINENO}" && return

	if [ ! -d "$_path2CurrentMonth" ] ; then
		mkdir -p "$_path2CurrentMonth"
		Send2Log "CheckIntervalFiles: create directory: $_path2CurrentMonth" 1 "${0##$d_baseDir/} : CheckIntervalFiles: Line Number ${LINENO}"
	fi
	Send2Log "CheckIntervalFiles: create interval file: $_intervalDataFile" 1 "${0##$d_baseDir/} : CheckIntervalFiles: Line Number ${LINENO}"
	echo "var monthly_created=\"${_ds} ${_ts}\"
	var monthly_updated=\"${_ds} ${_ts}\"
	var monthlyDataCap=\"$_monthlyDataCap\"
	var monthly_total_down=\"0\"	// 0 GB
	var monthly_total_up=\"0\"	// 0 GB
	var monthly_unlimited_down=\"0\"	// 0 GB
	var monthly_unlimited_up=\"0\"	// 0 GB
	var monthly_billed_down=\"0\"	// 0 GB
	var monthly_billed_up=\"0\"	// 0 GB
	" >> $_intervalDataFile
}

HtmlHeader(){
	# end-of-hour.sh
	# HtmlHeader "<!--header-->" "$tds" "$tmplogFile" "$thr"
	# new-day.sh
	# HtmlHeader "" "$_ds" "$g_daily_log_file"
	# moved from new-day.sh & end-of-hour.sh
	local l_header="$1" l_ds="$2" l_html_file="$3" l_thr="$4"
	Send2Log "HtmlHeader: header? ${l_header} : l_ds ${l_ds} : l_html_file ${l_html_file} : l_thr ${l_thr} " 4 "${0##$d_baseDir/} : HTMLHeader : Line Number ${LINENO}"
# As if we need any more wordage! # <label><input class='filter' type='checkbox' name='no-ll5' checked>Level 5<span class='tooltip tooltip-ll5'>Level 5: Debugging Info.</span></label> ${l_header}

echo "<!DOCTYPE html><html lang='en'>
<head>
<title>Log for $l_ds</title>
<meta http-equiv='cache-control' content='no-cache'>
<meta http-equiv='Content-Type' content='text/html;charset=utf-8'>
<link rel='stylesheet' href='//code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css'>
<link rel='stylesheet' type='text/css' href='../css/normalize.css'>
<link rel='stylesheet' type='text/css' href='../css/logs.css'>
<script src='https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js'></script>
<script src='https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js'></script>
<script src='../js/logs.js'></script>
</head>
<body onload='window.scrollTo(0, 0);'>
<div id='header'> ${l_header}
<h1>Log for <span id='logDate'>$l_ds</span></h1> ${l_header}
<p>Show: <label><input class='filter' type='checkbox' name='no-errors' checked>Errors<span class='tooltip tooltip-no-errors'>Errors!</span></label> ${l_header}
<Label><input class='filter' type='checkbox' name='no-ll4' checked>Level 4<span class='tooltip tooltip-ll4'>This option shows Level 4 logs.</span></label> ${l_header}
<label><input class='filter' type='checkbox' name='no-ll3' checked>Level 3<span class='tooltip tooltip-ll3'>Level 3: Function, Start &amp; Ending; with Values.</span></label> ${l_header}
<label><input class='filter' type='checkbox' name='no-ll2' checked>Level 2<span class='tooltip tooltip-ll2'>This option shows Level 2 logs.</span></label> ${l_header}
<label><input class='filter' type='checkbox' name='no-ll1' checked>Level 1<span class='tooltip tooltip-ll1'>Level 1: Verbose Information, lists etc.</span></label> ${l_header}
<label><input class='filter' type='checkbox' name='no-ll0'>Level 0<span class='tooltip tooltip-ll0'>This option shows Level 0 logs.</span></label></p> ${l_header}
" > "$l_html_file"

if [ -n "${l_header}" ] ; then
	echo "</div> $l_header
<div class='hour-contents'><p>Hour: $l_thr</p> " >> "$l_html_file"
else
	echo "</div>
<div id='log-contents' class='no-ll0'> " >> "$l_html_file"
fi
	Send2Log "Finished HTMLHeader creation " 4 "${0##$d_baseDir/} : HTMLHeader : Line Number ${LINENO}"
}
