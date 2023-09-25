#!/bin/bash

readonly NAME=0
readonly HASH=1
readonly ACK_FIELD=2
readonly USER=dummy
readonly PW=dummyPW

readonly SUBSCRIBER=/usr/bin/mosquitto_sub
readonly BUS_HOST=testbed.chmuranet.com
readonly BUS_PORT=1883
readonly CHANNEL=ACK
readonly OTHER_PARMS='-C 1'

readonly ACK=DONE
readonly NACK=OOPS
readonly ACK_VALUE="+"
readonly LOGFILE=~/Queue.log

declare -a Event

function Main()
{
    local _ack_field
    local _name

    while GetEvent
    do
        if [[ ${Event[$ACK_FIELD]} == $ACK_VALUE ]]
        then
            _ack_field=$ACK
        else
            _ack_field=$NACK
        fi
        
        _name="${Event[$NAME]}"

        printf "%s: Transfer <%s> %s ( %s )\n" "$(date)" ${_ack_field} "${_name}" ${Event[HASH]}  >> ${LOGFILE}
    done
}



function GetEvent()
{
        oldIFS=$IFS
        IFS=$'\t'

        Event=($($SUBSCRIBER -h $BUS_HOST $OTHER_PARMS  -p $BUS_PORT  -t $CHANNEL -u $USER -P $PW  ))
        local result=$?

        IFS=$oldIFS

        return $result
}

Main

