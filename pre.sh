#!/bin/bash

# Ensure the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Update and install necessary packages
apt-get update -qq
apt-get install -y git wget vim ufw tmux

# Install Go
GO_VERSION="go1.20.14.linux-amd64.tar.gz"
if [ "$(uname -m)" == "aarch64" ]; then
    GO_VERSION="go1.20.14.linux-arm64.tar.gz"
fi
wget -q "https://go.dev/dl/${GO_VERSION}"
tar -xvf ${GO_VERSION}
mv go /usr/local
rm ${GO_VERSION}

# Set temporary environment variables for Go
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Configure sysctl for better network performance
echo "net.core.rmem_max=600000000" >> /etc/sysctl.conf
echo "net.core.wmem_max=600000000" >> /etc/sysctl.conf
sysctl -p

# Set up cron job for after reboot
(crontab -l 2>/dev/null; echo "@reboot $(pwd)/post_reboot.sh") | crontab -

# Reboot the system to apply changes
echo "System will reboot now..."
reboot
