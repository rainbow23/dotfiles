#!/bin/sh
# Get Linux distribution name
get_os_distribution() {
    if   [ -e /etc/debian_version ] ||
         [ -e /etc/debian_release ]; then
        # Check Ubuntu or Debian
        if [ -e /etc/lsb-release ]; then
            # Ubuntu
            distri_name="ubuntu"
        else
            # Debian
            distri_name="debian"
        fi
    elif [ -e /etc/redhat-release ]; then
        # Red Hat Enterprise Linux
        distri_name="redhat"
    elif [ -e /etc/system-release-cpe ]; then
        distri_name="amazonlinux"
    elif [ -e /etc/arch-release ]; then
        # Arch Linux
        distri_name="arch"
    elif [ cat  /etc/alpine-release ]; then
        distri_name="alpine"
    elif echo ${OSTYPE} | grep -q "darwin"; then
        # Mac
        distri_name="darwin"
    else
        # Other
        echo "unkown distribution"
        distri_name="unkown"
    fi

    echo ${distri_name}
}

echo $(get_os_distribution)
