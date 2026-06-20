#!/bin/sh
##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# updates the data for the live tab
# run: by cron
# History
# 2026-06-02: Fix broken dpct expression (overlay, not /)
#	allow for garbage response - Send2Log if req'd
#	fixes long standing $doArchiveLiveUpdates error
# 2026-05-22: 4.0.8 - no changes
# 2020-01-26: 4.0.7 - no changes
# 2020-01-03: 4.0.6 - added current traffic to the output file
# 2019-12-23: 4.0.5 - no changes 
# 2019-11-24: 4.0.4 - no changes (yet)
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

d_baseDir=$(cd "$(dirname "$0")" && pwd)
source "${d_baseDir}/includes/shared.sh"
source "${d_baseDir}/includes/traffic.sh"

t_reportSpan=$(CalcReportSpan '1')

Send2Log "Running update-live-data: --> ${t_reportSpan}" 1 "${0##$d_baseDir/} : Start : Line Number ${LINENO}"
echo "Running update-live-data: --> ${t_reportSpan} 1 ${0##$d_baseDir/} : Start : Line Number ${LINENO}" >> '/opt/YAMon4/testCounter.debug'

CurrentConnections_0()
{ #_doCurrConnections=0 --> do nothing, the option is disabled
	return
}

CurrentConnections_1()
{ #_doCurrConnections=1
	IP6Enabled(){
		echo "$(ip6tables -L "$YAMON_IPTABLES" "$vnx" | grep -v RETURN | awk '{ print $2,$7,$8 }' | grep "^[1-9]")"
	}
	NoIP6(){
		echo ''
	}

	Send2Log "Running CurrentConnections_1 --> $_liveFilePath" 0 "${0##$d_baseDir/} : CurrentConnections_1 : Line Number ${LINENO}"

	ArchiveLiveUpdates_0()
	{ #_doArchiveLiveUpdates=0 --> do nothing, the option is disabled
		return
	}
	ArchiveLiveUpdates_1(){ #_doArchiveLiveUpdates=1
		local dpct dspace
		#local diskpcent diskspace
		# broken local dpct=$(df $d_baseDir | grep "^/" | awk '{print $5}')
		#diskpcent=$(df "$d_baseDir" | awk 'NR>1 {print $5; exit}')
		#Don't check the filesystem type, we want the % of d_baseDir in use
		dpct=$(df -P "$d_baseDir" 2>/dev/null | awk 'NR==2{print $5}')
		if printf '%s' "$dpct" | grep -qE '^[0-9]+%$'; then
		  dspace=$(printf '%02d' "${dpct%\%}")
		  Send2Log "ArchiveLiveUpdates :  ${dpct} becomes ${dspace} available" 0 "${0##$d_baseDir/} : ArchiveLiveUpdates_1 : Line Number ${LINENO}"
		else
		  # NaN or ?? - pass a safe default
		  dspace='99'
		fi
		# old local dspace=$(printf %02d $(echo "${dpct%\%} "))
		# strip percent and pad
		# if [ -n "$dpct" ]; then
		#   diskspace=$(printf '%02d' "${diskpcent%\%}")
		# else
		#   diskspace=91   # fallback to "full" so
		# fi
		if [ "$dspace" -lt '90' ] ; then
			cat "$_liveFilePath" >> "$_liveArchiveFilePath"
			# Send2Log "ArchiveLiveUpdates : cat $_liveFilePath >> $_liveArchiveFilePath" 3 "${0##$d_baseDir/} : ArchiveLiveUpdates_1 : Line Number ${LINENO}"
		else
			Send2Log "ArchiveLiveUpdates_: skipped because of low / unknown disk space: $dpct" 4 "${0##$d_baseDir/} : ArchiveLiveUpdates_1 : Line Number ${LINENO}"
		fi
	}
	
	#to-do - grab the iptables data and send along with the live data
	local vnx='-vnx'
	local ip4t=$(iptables -L "$YAMON_IPTABLES" "$vnx" | grep -v RETURN | awk '{ print $2,$8,$9 }' | grep "^[1-9]")
	local ip6t="$ip6tablesFn"
	local ipt="$ip4t\n$ip6"
	local macIP=$(cat "$macIPFile")
	
	echo -e "\n/*current traffio by device:*/" >> $_liveFilePath
	while [ 1 ] ;
	do
		[ -z "$ipt" ] && break
		fl=$(echo -e "$ipt" | head -n 1)
		[ -z "$fl" ] && break
		local ip=$(echo "$fl" | cut -d' ' -f2)
		if [ "$_generic_ipv4" == "$ip" ] || [ "$_generic_ipv6" == "$ip" ] ; then
			ip=$(echo "$fl" | cut -d' ' -f3)
		fi
		local tip="\b${ip//\./\\.}\b"
		if [ "$_generic_ipv4" == "$ip" ] || [ "$_generic_ipv6" == "$ip" ] ; then
			ipt=$(echo -e "$ipt" | grep -v "$fl")
		else
			local do=$(echo "$ipt" | grep -E "($_generic_ipv4|$_generic_ipv6) $tip\b" | cut -d' ' -f1)
			local up=$(echo "$ipt" | grep -E "$tip ($_generic_ipv4|$_generic_ipv6)" | cut -d' ' -f1)
			local mac=$(echo "$macIP" | grep $tip | awk '{print $1}')
			[ -z "$mac" ] && mac=$(GetMACbyIP "$tip")
			echo "curr_users4({id:'$mac-$ip',down:'${do:-0}',up:'${up:-0}'})" >> $_liveFilePath
			ipt=$(echo -e "$ipt" | grep -v "$tip")
		fi
	done
	
	local ddd=$(awk "$_conntrack_awk" "$_conntrack")
	ddd_snip=$(printf '%s' "${ddd:0:100}")
	echo -e "\n/*current connections by ip:*/" >> $_liveFilePath
	local err=$(echo "${ddd%,}]" 2>&1 1>> $_liveFilePath)
	# verbose output# Send2Log "curr_connections >>> $(IndentList "$ddd")" 0 "${0##$d_baseDir/} : CurrentConnections_1 : Line Number ${LINENO}"
	Send2Log "curr_connections >>> $(IndentList "$ddd_snip") [..8<..] " 0 "${0##$d_baseDir/} : CurrentConnections_1 : Line Number ${LINENO}"
	[ -n "$err" ] && Send2Log "ERROR >>> doliveUpdates:  $(IndentList "$err")" 4 "${0##$d_baseDir/} : CurrentConnections_1 : Line Number ${LINENO}"
	# sh: invalid number '' - was bug in dpct
	 $doArchiveLiveUpdates
	# Send2Log " >>> doArchiveliveUpdates:  $doArchiveLiveUpdates" 4 "${0##$d_baseDir/} : CurrentConnections_1 : Line Number ${LINENO}"
}

loads=$(cat /proc/loadavg | cut -d' ' -f1,2,3 | tr -s ' ' ',')
Send2Log ">>> loadavg: $loads" 0 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"

echo -e "var last_update='$_ds $_ts'${_nl}serverload($loads)" > $_liveFilePath

$doCurrConnections

FunctionUsage "Finished" 2 "${0##$d_baseDir/} : End : Line Number ${LINENO}"
