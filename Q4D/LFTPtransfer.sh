#!/bin/bash
#set -xv  # debugging

# Please Change
readonly USER="dummy"
readonly PW="dummyPW"

# Local Values
readonly LOCAL_BASE="/home/owner/Downloads/Torrents"


# LFTP Values
readonly CREDS='dummy:dummyPW'
readonly HOST="owner.chmuranet.net"
readonly PORT=21
readonly BASE="/home/owner/Downloads/"
readonly THREADS=5
readonly SEGMENTS=5
readonly FTPOPTIONS="set ftp:ssl-force yes; set ssl:verify-certificate no; set xfer:use-temp-file yes; set xfer:temp-file-name *.lftp"
readonly HOSTKEYFIX="set sftp:auto-confirm yes"

## Event Bus (for ACK)
readonly PUBLISHER="/usr/bin/mosquitto_pub"
readonly BUS_HOST="testbed.chmuranet.com"
readonly BUS_PORT=1883
readonly CHANNEL="ACK"
readonly OTHER_PARMS="-q 2"


readonly LOGFILE=~/Process.log

function Main()
{
	local _result
	
	local _target="$1"
	local _hash="$2"
	local _category="$3"
	local _content_path="$4"


	WaitLock

	SetDirectory ${_category}

	_result=$(TransferPayload "${_content_path}")

	if [[ _result -eq 0 ]]
	then
		# fix perms (if not running via docker)
		chown -R docker:users "${_target}"
		chmod -R a=,a+rX,u+w,g+w "${_target}"
	fi

	ProcessResult ${_result} "${_target}" ${_hash}

}

function WaitLock()
{
    # Wait
    exec 5>/tmp/lock
    flock 5
}

function SetDirectory()
{

	local _destination=$1

	cd "${LOCAL_BASE}/${_destination}"

}


function TransferPayload()
{
	local _target="$1"
	local _transferred

	umask 0

    # Try to grab as a directory
	lftp -u ${CREDS} ftp://${HOST}:${PORT}  -e "$HOSTKEYFIX; $FTPOPTIONS; cd $BASE ; mirror -c  --parallel=$THREADS --use-pget-n=$SEGMENTS \"${_target}\" ;quit" >>/tmp/fail$$.log 2>&1 

	_transferred=$?

	if [[ $_transferred -ne 0 ]]
	then
            # Now as a file
        	lftp -u ${CREDS} ftp://${HOST}:${PORT}  -e "$HOSTKEYFIX; $FTPOPTIONS; cd ${BASE} ; pget -n $SEGMENTS \"${_target}\" ;quit" >>/tmp/fail$$.log 2>&1 
        	_transferred=$?
	fi

	echo ${_transferred}
}

function ProcessResult()
{
	local _result=$1
	local _target="$2"
	local _hash=$3
    local _event
	

	if [[ ${_result} -eq 0  ]]
	then
        # ACK
       	echo $(date)": Transfer of ${_target} Completed." >> $LOGFILE

        _event=$(printf "%s\t%s\t+\n" "${_target}" ${_hash})
    else
        # NACK
        echo $(date)": Transfer of ${_target} Failed." >> $LOGFILE
     	cat /tmp/fail$$.log >> $LOGFILE
        
        _event=$(printf "%s\t%s\t#\n" "${_target}" ${_hash})
    
    fi

    if [ ${_hash} != "0000" ]
    then
        $PUBLISHER -h $BUS_HOST  -p $BUS_PORT -t $CHANNEL -u $USER -P $PW -m "${_event}" $OTHER_PARMS

   	    if [[ $? -eq 0 ]]
   	    then
            echo $(date)": Event ACKED for "${_hash} >> $LOGFILE
   	    else
        	echo $(date)": ACK Failed for "${_hash} >> $LOGFILE
   		fi
    fi
}

Main "$1" "$2" "$3" "$4"

