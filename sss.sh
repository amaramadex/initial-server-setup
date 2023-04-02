#!/bin/bash

echo "Basic server setup by Amar Dugonja - www.amadex.com"

# Function to ask user for input
ask_user() {
  echo -n "$1"
  read -r response
  echo "$response"
}

# Detect OS and update if desired
os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
update_choice=$(ask_user "Do you want to update the server? (yes/no): ")

if [ "$update_choice" = "yes" ]; then
  if [ -n "$(command -v apt-get)" ]; then
    sudo apt-get update && sudo apt-get upgrade -y
  elif [ -n "$(command -v yum)" ]; then
    sudo yum update -y
  elif [ -n "$(command -v dnf)" ]; then
    sudo dnf update -y
  fi
  echo "The server is successfully updated."
fi

# Set hostname
new_hostname=$(ask_user "Enter the desired hostname: ")
sudo hostnamectl set-hostname "$new_hostname"

# Set timezone
new_timezone=$(ask_user "Enter the desired timezone: ")
sudo timedatectl set-timezone "$new_timezone"

# Change SSH port if desired
ssh_port_choice=$(ask_user "Do you want to change the SSH port? (yes/no): ")

if [ "$ssh_port_choice" = "yes" ]; then
  new_ssh_port=$(ask_user "Enter the new SSH port: ")
  sudo sed -i "s/^Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config
fi

# Check if IPv6 is enabled
if [ -n "$(ip addr show | grep inet6)" ]; then
  echo "The server is using IPv6."
  ipv6_choice=$(ask_user "Do you want to keep IPv6? (yes/no): ")
  if [ "$ipv6_choice" = "no" ]; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
  fi
fi

# Check swap memory and configure if needed
swap_info=$(swapon --show)

if [ -n "$swap_info" ]; then
  echo "Swap is already configured:"
  echo "$swap_info"
else
  swap_size=$(ask_user "How much swap memory do you want to create (e.g. 2G): ")
  sudo fallocate -l "$swap_size" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
  sudo sysctl vm.swappiness=10
  sudo sysctl vm.vfs_cache_pressure=50
  echo "vm.swappiness = 10" | sudo tee -a /etc/sysctl.conf
  echo "vm.vfs_cache_pressure = 50" | sudo tee -a /etc/sysctl.conf
fi

# Reboot the server if desired
reboot_choice=$(ask_user "Do you want to reboot the server to apply the changes? (yes/no): ")

if [ "$reboot_choice" = "yes" ]; then
  echo "Server is rebooting..."
  sudo reboot
fi
