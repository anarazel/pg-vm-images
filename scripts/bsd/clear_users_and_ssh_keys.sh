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

project_level_ssh_keys=$(curl -fsH "Metadata-Flavor: Google"  http://metadata.google.internal/computeMetadata/v1/project/attributes/ssh-keys)
instance_level_ssh_keys=$(curl -fsH "Metadata-Flavor: Google"  http://metadata.google.internal/computeMetadata/v1/instance/attributes/ssh-keys)
ssh_keys=$(printf '%s\n%s' "$project_level_ssh_keys" "$instance_level_ssh_keys")

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
