#!/bin/bash

if [ -f /scripts/ProcessEvent.sh ]; then
	/scripts/ProcessEvent.sh &
else
	echo "Script not found!" >&2
	exit 1
fi

wait -n

exit $?
