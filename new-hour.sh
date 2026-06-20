#!/bin/sh

##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# runs tasks needed to start a new hour
# run: by cron
# History
# 2026-06-18: Refine "//Hour" header for debugging / timing
# 2026-06-09: Add debug logging
# 2026-05-22: 4.0.8 - no changes
# 2025-04:    Add day to "// Hour t_day-t_hr" stamp
# 2020-01-26: 4.0.7 - no changes
# 2020-01-03: 4.0.6 - no changes
# 2019-12-23: 4.0.5 - no changes
# 2019-11-24: 4.0.4 - no changes (yet)
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

d_baseDir=$(cd "$(dirname "$0")" && pwd)
source "${d_baseDir}/includes/shared.sh"
Send2Log "DEBUG: _ts - $_ts _ds - $_ds rawtraffic_hr - $rawtraffic_hr hourlyDataFile - $hourlyDataFile" 4  "${0##"$d_baseDir/"} : Main : Line Number ${LINENO}"
#t_hr=$(echo $g_ts | cut -d':' -f1)
t_day=$(date +"%d")
t_date=$(date +"%d  %H %M %S")
t_hr=$(echo $_ts | cut -d':' -f1)

Send2Log "new hour: Start of hour $t_hr" 1  "${0##"$d_baseDir/"} : Main : Line Number ${LINENO}"

rawtraffic_hr="${tmplog}raw-traffic-${_ds}-${t_hr}.txt"
ChangePath 'rawtraffic_hr' "$rawtraffic_hr"

[ ! -f "$rawtraffic_hr" ] && > "$rawtraffic_hr"
Send2Log "new hour: created new temporary hour file: $rawtraffic_hr" 0  "${0##"$d_baseDir/"} : Main : Line Number ${LINENO}"

sleep 5
#[ -z "$(grep "// Hour: $t_hr" "$hourlyDataFile")" ] && echo -e "\n// Hour: $t_hr" >> "$hourlyDataFile"
#[ -z "$(grep "// Hour: ${t_hr}" "$hourlyDataFile")" ] && echo -e "\n// Hour: ${t_hr} (${t_date})" >> "$hourlyDataFile"
#Send2Log "// Hour: ${t_hr} (${t_date}) -- header created" 1  "${0##"$d_baseDir/"} : Main : Line Number ${LINENO}"
if ! grep -Fq "// Hour: ${t_hr}" "$hourlyDataFile"; then
	printf '\n// Hour: %s (%s)\n' "$t_hr" "$t_date" >> "$hourlyDataFile"
fi
#[ -z "$(grep "// Hour: ${t_hr}" "$hourlyDataFile")" ] && echo -e "\n// Hour: ${t_hr} (${t_date})" >> "$hourlyDataFile"
Send2Log "// Hour: ${t_hr} (${t_date}) -- header created" 1  "${0##"$d_baseDir/"} : Main : Line Number ${LINENO}"

FunctionUsage "Finished" 3 "${0##"$d_baseDir/"} : Main : Line Number ${LINENO}"
