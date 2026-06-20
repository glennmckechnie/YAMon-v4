#!/bin/sh

##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# run scripts needed at the start of a new day
# run: by cron
# History
# 2026-06-13: Add missing _liveArchiveFilePath update line.
# 2026-06-09: 4.0.8 - Add logging statements, move html headers to shared.sh
# 2025-04:    Add day to "// Hour t_day-hr" stamp
# 2020-01-26: 4.0.7 - no changes
# 2020-01-03: 4.0.6 - no changes
# 2019-12-23: 4.0.5 - added symlinks for day and hour logs 
# 2019-11-24: 4.0.4 - no changes (yet)
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

d_baseDir=$(cd "$(dirname "$0")" && pwd)
source "${d_baseDir}/includes/shared.sh"
FunctionUsage "Main-start" 3 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"

hourlyDataFile="${tmplog}hourly_${_ds}.js"
dailyLogFile="${_path2logs}${_ds}.html"
ChangePath 'rawtraffic_day' "${_path2CurrentMonth}raw-traffic-$_ds.txt"
ChangePath 'hourlyDataFile' "$hourlyDataFile"
ChangePath '_liveArchiveFilePath' "${_path2CurrentMonth}${_ds}-live_data4.js"
ChangePath 'dailyLogFile' "$dailyLogFile"
# FIXME - delete when ready
#if [ ! -f "$hourlyDataFile" ] ; then
#	echo -e "var hourly_created=\"${_ds} ${_ts}\"\nvar hourly_updated=\"${_ds} ${_ts}\"\nvar disk_utilization=\"\"\nvar serverUptime=\"$_uptime\"\nvar freeMem=\"\",availMem=\"\",totMem=\"\"" > "$hourlyDataFile"
#fi
#if [ ! -f "$g_hourly_data_js_file" ] ; then
# Glenn McKechnie - modified 13/06/26 18:31
# # /mnt/nvme0n1/0000AAAA-CurrentAsOf-20260522/YAMon4-20250116

if [ ! -f "$hourlyDataFile" ] ; then
  t_day=$(date +"%d")
  # Glenn McKechnie - modified 30/04/25 20:58.
  t_ts=$(date +"%T") # Temporary debug
  # NEW as per output style
  printf "%s" "var hourly_created=\"${_ds} ${_ts}\"
var hourly_updated=\"${_ds} ${_ts}\"
var disk_utilization=\"\"
var serverUptime=\"$_uptime\"
var freeMem=\"\",availMem=\"\",totMem=\"\"

// Hour: 00 (${t_day}--${t_ts})" > "$hourlyDataFile"
fi
Send2Log "new-day: $_ds / $hourlyDataFile" 1 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
# FIXME - delete when ready
# g_daily_log_file=/opt/YAMon4/logs/2025-03-28.html
#    dailyLogFile='/opt/YAMon4/logs/2026-06-03.html'
# g_rawtraf_day_file='/opt/YAMon4/data/2025/03/raw-traffic-2025-03-31.txt'
#     rawtraffic_day='/opt/YAMon4/data/2026/06/raw-traffic-2026-06-03.txt'
cp "$rawtraffic_day" "${rawtraffic_day}-backup"
Send2Log "Copy $rawtraffic_day to ${rawtraffic_day}-backup : Now check its contents" 2  "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
[ ! -f "$dailyLogFile" ] && > "$rawtraffic_day"
[ ! -f "$dailyLogFile" ] && HtmlHeader "" "$_ds" "$dailyLogFile"

DeleteSeeSharedHtmlHeader(){
[ ! -f "$dailyLogFile" ] && > "$rawtraffic_day"
[ ! -f "$dailyLogFile" ] && echo "<html lang='en'>
<head>
<meta http-equiv='cache-control' content='no-cache' />
<meta http-equiv='Content-Type' content='text/html;charset=utf-8' />
<link rel='stylesheet' href='//code.jquery.com/ui/1.12.1/themes/smoothness/jquery-ui.css'>
<link rel='stylesheet' type='text/css' href='../css/normalize.css'>
<link rel='stylesheet' type='text/css' href='../css/logs.css'>
<script src='https://ajax.googleapis.com/ajax/libs/jquery/3.3.1/jquery.min.js'></script>
<script src='https://ajax.googleapis.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js'></script>
<script src='../js/logs.js'></script>
</head>
<body>
<div id='header'>
<h1>Log for <span id='logDate'>$_ds</span></h1>
<p>Show: <label><input class='filter' type='checkbox' name='no-errors' checked>Errors</label><!-- label><input class='filter' type='checkbox' name='no-ll5' checked>Level 5</label --><label><input class='filter' type='checkbox' name='no-ll4' checked>Level 4</label><label><input class='filter' type='checkbox' name='no-ll3' checked>Level 3</label><label><input class='filter' type='checkbox' name='no-ll2' checked>Level 2</label><label><input class='filter' type='checkbox' name='no-ll1' checked>Level 1</label><label><input class='filter' type='checkbox' name='no-ll0'>Level 0</label></p>
</div><div id='log-contents' class='no-ll0'>
" > "$dailyLogFile"

}
#update the day-log symlink
nll="${_path2logs%/}/${_ds}.html"
oll="${_wwwPath}logs/day-log.html"
[ -h "$oll" ] && rm -fv "$oll"
ln -s "$nll" "$oll"
Send2Log "new-day: day log changed from oll --> nll  $oll --> $nll" 1  "${0##$d_baseDir/} : Main : Line Number ${LINENO}"

FunctionUsage "Finished" 3 "${0##$d_baseDir/} : Main : Line Number ${LINENO}"
