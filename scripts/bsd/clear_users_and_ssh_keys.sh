#!/bin/sh

set -e

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

# since we are creating postgres images from vanilla images,
# vanilla images' rc.local script will create users and
# these users will exist in postgres images.
# we need to remove these users.

ssh_keys=""

# do not fail if curl fails with 404
curl_helper ()
{
    curl_temp_path=$(mktemp)

    exit_code=0
    http_code=$(curl -fsH "Metadata-Flavor: Google" -o ${curl_temp_path} -w "%{http_code}\n" $1) || exit_code=$?

    if [ "${exit_code}" != "0" ] && [ "${http_code}" != "404" ]
    then
        echo "Curl failed with exit code ${exit_code}"
        exit ${exit_code}
    elif [ "${http_code}" = "404" ]
    then
        echo "Curl returned 404"
    else
        ssh_keys=$(printf '%s\n%s' "$ssh_keys" "$(cat $curl_temp_path)")
    fi

    rm -f $curl_temp_path
}

curl_helper http://metadata.google.internal/computeMetadata/v1/project/attributes/ssh-keys
curl_helper http://metadata.google.internal/computeMetadata/v1/instance/attributes/ssh-keys

if [ "$ssh_keys" != "" ]
then
    echo "$ssh_keys" | while read line
    do
        username="$(echo $line | cut -d: -f1)"
        if [ "$username" != "root" ] && id "$username" > /dev/null 2>&1;
        then
            # remove the user's home directory, any subdirectories,
            # and any files and other entries in them.
            userdel -r $username
        fi
    done
fi

# remove root's ssh keys
rm -rf /root/.ssh/
