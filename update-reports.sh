#!/bin/sh

##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# gets data from iptables and updates the report files
# run: by cron
# History
# 2026-06-09: Add call to flush arp cache. unknow MAC issues.
# 2026-05-22: 4.0.8 - no changes
# 2020-01-26: 4.0.7 - no changes
# 2020-01-03: 4.0.6 - no changes
# 2019-12-23: 4.0.5 - no changes
# 2019-11-24: 4.0.4 - no changes (yet)
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

sleep 1 # needed to ensure that raw traffic is stored in the right hourly file... might have to be adjusted

d_baseDir=$(cd "$(dirname "$0")" && pwd)

source "${d_baseDir}/includes/shared.sh"
source "${d_baseDir}/includes/traffic.sh"

Send2Log "update-reports.sh : Calling traffic.sh" 1 "${0##$d_baseDir/} : Main - start : Line Number-${LINENO}"
GetTraffic "-vnx"   # get the data without zeroing the tables

# Attempt to clear arp table of old invalid entries.
clearARPTable=$(ip neigh flush all)
[ -n "$clearARPTable" ] && Send2Log "Main: arp tables: $(IndentList "$clearARPTable")" 4 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"

LogEndOfFunction "Finished" 1 "${0##$d_baseDir/} : Main - end : Line Number-${LINENO}"
