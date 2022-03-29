#!/bin/sh

if [ "$(uname)" = "NetBSD" ]
then
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/pkg/bin:/usr/pkg/sbin
elif [ "$(uname)" = "OpenBSD" ]
then
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin
else
    # Unsupported OS
    echo "Unsupported OS, exiting"
    exit 1
fi

### Run shutdown scripts ###

shutdown_script=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/shutdown-script)

if [ "$shutdown_script" != "" ]
then
    if [ $(echo "$shutdown_script" | grep -c 'was not found') -eq 0 ]
    then
        echo "Running shutdown script"
        echo "${shutdown_script}" | sh > /dev/null 2>&1 &
    fi
fi
