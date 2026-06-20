##########################################################################
# Yet Another Monitor (YAMon)
# Copyright (c) 2013-present Al Caughey
# All rights reserved.
#
# utility functions used by install and setup
#
# History
# Glenn McKechnie - modified 03/06/26
# 2026-06-03: rework varNames and add _domain default
# 2026-05-22: 4.0.8 - no changes
# 2020-01-26: 4.0.7 - no changes
# 2020-01-03: 4.0.6 - added pad_length in UpdateConfig
# 2019-12-23: 4.0.5 - removed extra space before # Added in UpdateConfig()
# 2019-11-24: 4.0.4 - no changes (yet)
# 2019-06-18: development starts on initial v4 release
#
##########################################################################

SetupLog(){
	[ "${2:-0}" -lt "${_loglevel:-0}" ] && return
	echo -e "<section class='ll${2:-0}'><article class='dt'>$(date +"%T")</article><article class='msg'>$1</article></section>" >> "$setupLogFile"
}

Prompt(){
#   Prompt _varName _prompt2 _prompt3 _defValue _regex _topic
    local _response=''
    local _varName=$1
     eval _newValue=\"\$$_varName\"
    local _defValue="$4"
    local _regex="$5"
    _queryNum=$(($_queryNum + 1))
    local _prompt2="$2"
    local _topic="$6"
    [ -z  "$_topic" ] && _topic="$_varName"
    echo -e "
#$_queryNum. $_prompt2" >&2
    _prompt3="$(echo -e "    $3
    "| sed -re 's~[\t]+~    ~g')
    "
    if [ -z "$_newValue" ] && [ -z "$_defValue" ] ; then
        _newValue='n/a'
        _defValue='n/a'
        readStr="    Enter your preferred value: "
    elif [ -z "$_defValue" ] ; then
        readStr="${_prompt3}Hit <enter> to accept the current value (\`$_newValue\`),
      or enter your preferred value: "
    elif [ -z "$_newValue" ] ; then
        _newValue='n/a'
        readStr="${_prompt3}Hit <enter> to accept the default (\`$_defValue\`),
      or enter your preferred value: "
    elif [ "$_defValue" == "$_newValue" ] ; then
        readStr="${_prompt3}Hit <enter> to accept the current/default value (\`$_defValue\`),
      or enter your preferred value: "
    else
        readStr="${_prompt3}Hit <enter> to accept the current value: \`$_newValue\`, \`d\` for the default (\`$_defValue\`)
      or enter your preferred value: "
    fi
    local _tries=0
    while true ; do
        read -p "$readStr" _response
        [ ! "$_defValue" == 'n/a' ] && [ "$_response" == 'd' ] && _response="$_defValue" && break
        [ ! "$_newValue" == 'n/a' ] && [ -z "$_response" ] && _response="$_newValue" && break
        [ "$_newValue" == 'n/a' ] && [ ! "$_defValue" == 'n/a' ] && [ -z "$_response" ] && _response="$_defValue" && break
        if [ -n "$_regex" ] ;  then
            _ignore=$(echo "$_response" | grep -E $_regex)
            [ ! "$_ignore" == '' ] && [ "$_response" == 'n' ] || [ "$_response" == 'N' ] && _response="0" && break
            [ ! "$_ignore" == '' ] && [ "$_response" == 'y' ] || [ "$_response" == 'Y' ] && _response="1" && break
            [ ! "$_ignore" == '' ] && break
        else
            break
        fi
        _tries=$(($_tries + 1))
        if [ "$_tries" -eq "3" ] ; then
            echo "*** Strike three... you're out!" >&2
            exit 0
        fi
        SetupLog "Bad value for $_varName --> $_response" 2
        echo "
    *** \`$_response\` is not a permitted value for this variable!  Please try again.
     >>> For more info, see http://usage-monitoring.com/help/?t=$_topic" >&2
    done
    eval $_varName=\"$_response\"
    SetupLog "Prompt: $_prompt2 --> $_response" 2
    UpdateConfig "$_varName" "$_response"
}
UpdateConfig(){
    local _varName="$1"
    local _newValue="$2"
    [ "${_varName:0:2}" == 't_' ] && return
    [ -z "$_newValue" ] && eval _newValue="\$$_varName"
    SetupLog "UpdateConfig: $_varName --> $_newValue" 2
    local _searchVal="$_varName=.*#"
    local _replacementVal="$_varName=\'$_newValue\'"
    local _substrMatch=$(echo "$configStr" | grep -o "$_searchVal")
    local _lenRepVal="${#_replacementVal}"
    #SetupLog "UpdateConfig: _substrMatch--> $_substrMatch ($l1)// _replacementVal--> $_replacementVal ($_lenRepVal)" 2
    local spacing='==================================================='
	local _pad_length=$((46-$_lenRepVal+1))
	[ "$_pad_length" -lt 1 ] && _pad_length=1
	local _pad=${spacing:0:$_pad_length}
    if [ -z "$_substrMatch" ] ; then
        configStr="$configStr\n$_varName='$_newValue'${_pad//=/ }# Added"
    else
        configStr=$(echo "$configStr" | sed -e "s~$_searchVal~$_replacementVal${_pad//=/ }#~g")
    fi
}
