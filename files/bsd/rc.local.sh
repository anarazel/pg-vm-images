#!/bin/sh

# Save to /etc/rc.local, to be ran on startup

if [ "$(uname)" = "NetBSD" ]
then
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/pkg/bin:/usr/pkg/sbin

    # restarting syslogd
    restart_syslogd()
    {
        /etc/rc.d/syslogd restart > /dev/null
    }

    # chown home paths
    chown_home()
    {
        chown -R ${username}:users /home/${username}
    }
elif [ "$(uname)" = "OpenBSD" ]
then
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin

    # restarting syslogd
    restart_syslogd()
    {
        rcctl restart syslogd > /dev/null
    }

    # chown home paths
    chown_home()
    {
        chown -R ${username}:${username} /home/${username}
    }
else
    # Unsupported OS
    echo "Unsupported OS, exiting"
    exit 1
fi

### get instance hostname ###

instance_hostname=$(curl -s -H "Metadata-Flavor: Google"  http://metadata.google.internal/computeMetadata/v1/instance/name)
current_hostname=$(hostname)

if [ "$instance_hostname" != "" ]
then
    if [ "$instance_hostname" != "$current_hostname" ]
    then
        echo "Setting hostname to $instance_hostname"
        hostname $instance_hostname
        echo $instance_hostname > /etc/myname
        restart_syslogd
    else
        echo "Hostname is correct"
    fi
else
    echo "Could not discover hostname"
fi

### set up user's keys ###

# There are two types of ssh keys on the GCE; project level and instance level ssh keys.
# Fetch both of the keys and put them to the related paths
project_level_ssh_keys=$(curl -fsH "Metadata-Flavor: Google"  http://metadata.google.internal/computeMetadata/v1/project/attributes/ssh-keys)
instance_level_ssh_keys=$(curl -fsH "Metadata-Flavor: Google"  http://metadata.google.internal/computeMetadata/v1/instance/attributes/ssh-keys)
ssh_keys=$(printf '%s\n%s' "$project_level_ssh_keys" "$instance_level_ssh_keys")

if [ "$ssh_keys" != "" ]
then
    echo "$ssh_keys" | while read line
    do
        username="$(echo $line | cut -d: -f1)"
        user_key="$(echo $line | cut -d: -f2-)"
        key_comment="$(echo $line | awk '{print $NF}')"

        if [ "$username" = "root" ]
        then
            mkdir -p /root/.ssh
            touch /root/.ssh/authorized_keys
            if [ $(grep -c "$user_key" /root/.ssh/authorized_keys) -eq 0 ]
            then
                echo "$user_key" >> /root/.ssh/authorized_keys
                chmod 600 /root/.ssh/authorized_keys
                echo "$username: added ssh-key $key_comment"
            else
                echo "$username: ssh-key $key_comment already exists"
            fi
        elif [ "$username" != "" ]
        then
            if ! id "$username" > /dev/null 2>&1;
            then
                useradd ${username}
            fi
            mkdir -p /home/${username}/.ssh
            touch /home/${username}/.ssh/authorized_keys
            chown_home
            if [ $(grep -c "$user_key" /home/${username}/.ssh/authorized_keys) -eq 0 ]
            then
                echo "$user_key" >> /home/${username}/.ssh/authorized_keys
                chmod 600 /home/${username}/.ssh/authorized_keys
                echo "$username: added ssh-key $key_comment"
            else
                echo "$username: ssh-key $key_comment already exists"
            fi
        fi
    done
    # restart sshd
    /etc/rc.d/sshd restart
else
    echo "No keys found"
fi

### Check for bootstrap scripts ###

instance_bootstrap=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/bootstrap)

if [ "$instance_bootstrap" != "" ]
then
    if [ $(echo "$instance_bootstrap" | grep -c 'was not found') -eq 0 ]
    then
        if [ ! -f /var/log/bootstrap ] || [ $(grep -c "$instance_bootstrap" /var/log/bootstrap) -eq 0 ]
        then
            echo "Bootstrap: starting"
            ftp -V -o - $instance_bootstrap | sh
            echo $instance_bootstrap >> /var/log/bootstrap
        else
            echo "Bootstrap: completed"
        fi
    else
        echo "Bootstrap: metadata not found"
    fi
else
    echo "Bootstrap: empty curl"
fi

### Run startup scripts ###

startup_script=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/startup-script)

if [ "$startup_script" != "" ]
then
    if [ $(echo "$startup_script" | grep -c 'was not found') -eq 0 ]
    then
        echo "Running startup script"
        echo "${startup_script}" | sh > /dev/null 2>&1 &
    fi
fi
