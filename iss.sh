#!/usr/bin/env bash

# Colors
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

clear
echo -e "${ORANGE}Initial Server Setup (iss.sh) by Amadex - https://www.amadex.com${NC}"
echo -e "${ORANGE}Github: https://github.com/amaramadex/initial-server-setup${NC}"
echo -e "${WHITE}Important: Please make sure you are logged in as root to execute this script!${NC}"

# Check if logged in as root user
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

# Change root password
echo -e "${GREEN}Do you want to change the root password? (yes/no)${NC}"
read change_root_passwd
if [[ $change_root_passwd == "yes" ]]; then
    echo -e "${WHITE}Changing root password...${NC}"
    passwd
    echo -e "${YELLOW}Root password has been changed. Please remember the new password.${NC}"
fi

# Change hostname
echo -e "${GREEN}1. Do you want to change hostname? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    echo -e "${WHITE}Enter the new hostname:${NC}"
    read new_hostname
    hostnamectl set-hostname "$new_hostname"
fi

# Change timezone
echo -e "${GREEN}2. Do you want to change timezone? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    echo -e "${WHITE}Enter the new timezone (e.g. America/New_York):${NC}"
    read new_timezone
    timedatectl set-timezone "$new_timezone"
fi

# Change ssh port
echo -e "${GREEN}3. Do you want to change ssh port? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    echo -e "${WHITE}Enter the new ssh port:${NC}"
    read new_port
    sed -i "s/^#Port 22/Port $new_port/" /etc/ssh/sshd_config
fi

# Add swap or check if there's swap already added
echo -e "${GREEN}4. Do you want to add swap space? (yes/no)${NC}"
read answer
if [[ $answer == "yes" ]]; then
    if ! swapon --show | grep -q "swap"; then
        echo -e "${WHITE}Enter the swap size in GB (e.g. 1 - just a number):${NC}"
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

# Keep (if detected) or disable IPv6
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

# Install additional packages
echo -e "${GREEN}Do you want to install nano, htop, curl, screen, and git? (yes/no)${NC}"
read install_packages
if [[ $install_packages == "yes" ]]; then
    if command -v apt > /dev/null; then
        apt update
        apt install -y nano htop curl screen git
    elif command -v dnf > /dev/null; then
        dnf update -y
        dnf install -y nano htop curl screen git
    elif command -v yum > /dev/null; then
        yum update -y
        yum install -y nano htop curl screen git
    elif command -v pacman > /dev/null; then
        pacman -Syu --noconfirm
        pacman -S --noconfirm nano htop curl screen git
    else
        echo -e "${YELLOW}No supported package manager (apt, dnf, yum, or pacman) detected. Unable to install additional packages.${NC}"
    fi
fi

# Run YABS (Yet-Another-Bench-Script) by Mason Rowe - https://github.com/masonr/yet-another-bench-script
echo -e "${GREEN}Do you want to run YABS (Yet-Another-Bench-Script) - (duration cca. 15 min.)? (yes/no)${NC}"
read run_yabs
if [[ $run_yabs == "yes" ]]; then
    echo -e "${WHITE}Running YABS...${NC}"
    wget -qO- yabs.sh | bash
fi

# Reboot
echo -e "${GREEN}To apply the changes, please enter the ${YELLOW}'reboot'${GREEN} command after exiting this script. You can then log in with your kept or new password.${NC}"
