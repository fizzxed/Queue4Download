#!/bin/bash


declare -A payloadDetails

readonly LOGFILE=~/Queue.log

## Event Bus
readonly PUBLISHER="/usr/bin/mosquitto_pub"
readonly BUS_HOST="testbed.chmuranet.com"
readonly BUS_PORT=1883
readonly CHANNEL="Down"
readonly OTHER_PARMS="-q 2"

# Please Change
readonly USER="dummy"
readonly PW="dummyPW"


function Main() {
	local _name="$1"
	local _category="$2"
	local _hash="$3"
	local _tags="$4"
	local _content_path="$5"
	local _event
	local _queued="1" # Default Not Queued`	

	Invoke=${SECONDS}

	WaitLock

	payloadDetails[KEY]="${_name}"

	payloadDetails[HASHVAL]="${_hash}"

	payloadDetails[CATEGORY]="${_category}"

	payloadDetails[CONTENT_PATH]="${_content_path}"

	local _lower=$(echo "${_category}" | tr '[:upper:]' '[:lower:]')
	local _filter="sonarr|radarr"

	if [[ $_lower =~ $_filter || $_tags =~ "sync" ]]; then
		_event="$(CreateEvent)"
		_queued=$(PublishEvent "${_event}")
	fi
	
	LogEvent ${_queued}
}

function WaitLock() {
	# Wait 
	exec 5>/tmp/lock
	flock 5
}

function CreateEvent() {
	printf "%s\t%s\t%s\t%s\n" "${payloadDetails[KEY]}" "${payloadDetails[HASHVAL]}" "${payloadDetails[CATEGORY]}" "${payloadDetails[CONTENT_PATH]}"
}


function LogEvent() {
	local _result
	local _elapsed=$(( ${SECONDS}-${Invoke} ))

	if [[ $1 == 0 ]]; then 
		_result="SUCCESS"
	else
		_result="FAIL"
	fi

	printf "%s: <%s> %s ( %s ) ( %s ) ( %s ) [%d secs]\n" "$(date)" ${_result} "${payloadDetails[KEY]}" "${payloadDetails[HASHVAL]}" "${payloadDetails[CATEGORY]}" "${payloadDetails[CONTENT_PATH]}" ${_elapsed} >> ${LOGFILE}
}


function PublishEvent() {
	local _event="$1"

	$PUBLISHER -h $BUS_HOST  -p $BUS_PORT -t $CHANNEL -u $USER -P $PW -m "${_event}" $OTHER_PARMS

	echo $?
}

Main "$1" "$2" "$3" "$4" "$5"
