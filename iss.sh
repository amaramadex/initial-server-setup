#!/bin/bash

# Colors
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

clear
echo -e "${ORANGE}Initial Server Setup (iss.sh) by Amadex.com${NC}"
echo -e "${WHITE}Please make sure you are logged in as root to execute this script.${NC}"

# Question 1
echo -e "${GREEN}1. Do you want to change hostname? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    echo -e "${WHITE}Enter the new hostname:${NC}"
    read new_hostname
    hostnamectl set-hostname "$new_hostname"
fi

# Question 2
echo -e "${GREEN}2. Do you want to change timezone? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    echo -e "${WHITE}Enter the new timezone (e.g. America/New_York):${NC}"
    read new_timezone
    timedatectl set-timezone "$new_timezone"
fi

# Question 3
echo -e "${GREEN}3. Do you want to change ssh port? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    echo -e "${WHITE}Enter the new ssh port:${NC}"
    read new_port
    sed -i "s/^#Port 22/Port $new_port/" /etc/ssh/sshd_config
fi

# Question 4
echo -e "${GREEN}4. Do you want to add swap space? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    if ! swapon --show | grep -q "swap"; then
        echo -e "${WHITE}Enter the swap size in GB (just number without GB part):${NC}"
        read swap_size
        fallocate -l "${swap_size}G" /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
        sysctl vm.swappiness=10
        sysctl vm.vfs_cache_pressure=50
        echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
        echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf
    else
        echo -e "${WHITE}Swap space already created:${NC}"
        swapon --show
    fi
fi

# Question 5
echo -e "${GREEN}5. Do you want to keep IPv6? (yes/no)${NC}"
read answer
if [[ $answer == "no" ]]; then
    if ! grep -q "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf; then
        echo "net.ipv6.conf.all.disable_ipv6 = 1" | tee -a /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" | tee -a /etc/sysctl.conf
        echo "net.ipv6.conf.lo.disable_ipv6 = 1" | tee -a /etc/sysctl.conf
        sysctl -p
    fi
fi

#

# Question 6
echo -e "${GREEN}6. Do you want to reboot the server to apply the changes? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    echo -e "${YELLOW}Server is rebooting...${NC}"
    reboot
fi
