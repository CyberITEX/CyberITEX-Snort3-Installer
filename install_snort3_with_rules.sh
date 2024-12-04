#!/bin/bash

# Snort 3 Installation Script for Debian-Based Systems
# Ensure you run this script as root or with sudo privileges.

echo "Starting Snort 3.5.2.0 installation process..."

# Update the system
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y


# Install required dependencies
echo "Installing dependencies..."
sudo apt-get install -y \
    cmake make gcc g++ flex bison libpcap-dev libpcre3-dev zlib1g-dev liblzma-dev \
    libssl-dev libhwloc-dev libdnet-dev libsqlite3-dev pkg-config autoconf git wget luajit libluajit-5.1-dev libdumbnet-dev

# Install LibDAQ
echo "Cloning and installing LibDAQ..."
cd /tmp
git clone https://github.com/snort3/libdaq.git
cd libdaq
./bootstrap
./configure
make
sudo make install
sudo ldconfig  # Update linker configuration

# Download Snort 3.5.2.0
echo "Downloading Snort 3.5.2.0..."
cd /tmp
wget https://github.com/snort3/snort3/archive/refs/tags/3.5.2.0.tar.gz -O snort3-3.5.2.0.tar.gz
tar -xvzf snort3-3.5.2.0.tar.gz
cd snort3-3.5.2.0

# Build and Install Snort
echo "Building and installing Snort 3.5.2.0..."
mkdir build
cd build
cmake ..
make
sudo make install
sudo ldconfig  # Refresh dynamic linker

# Verify Installation
echo "Verifying Snort installation..."
snort_version=$(snort -V 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "Snort installed successfully: $snort_version"
else
    echo "Snort installation failed. Please check the logs."
    exit 1
fi

# Set up configuration
echo "Setting up Snort configuration..."
sudo mkdir -p /usr/local/etc/snort/rules
sudo mkdir -p /usr/local/etc/snort/so_rules
sudo mkdir -p /usr/local/etc/snort/preproc_rules
sudo mkdir -p /var/log/snort
sudo touch /usr/local/etc/snort/rules/local.rules
sudo cp /usr/local/etc/snort/snort_defaults.lua /usr/local/etc/snort/snort.lua

# Update HOME_NET variable
echo "Updating HOME_NET in snort.lua..."
sudo sed -i "s|HOME_NET = 'any'|HOME_NET = '192.168.0.0/16'|" /usr/local/etc/snort/snort.lua

# Download Snort Rules
echo "Downloading Snort community rules..."
wget https://www.snort.org/downloads/community/snort3-community-rules.tar.gz -O /tmp/snort3-community-rules.tar.gz
sudo tar -xvzf /tmp/snort3-community-rules.tar.gz -C /usr/local/etc/snort/rules/

# Include community rules in the Snort configuration
echo "Including community rules in snort.lua..."
sudo sed -i "/ips.rules/a include = 'rules/community.rules'" /usr/local/etc/snort/snort.lua
sudo sed -i "/ips.rules/a include = 'rules/snort3-community-rules/snort3-community.rules'" /usr/local/etc/snort/snort.lua


# Validate Snort Configuration
echo "Validating Snort configuration..."
snort -c /usr/local/etc/snort/snort.lua -T
if [[ $? -eq 0 ]]; then
    echo "Snort configuration is valid."
else
    echo "Snort configuration validation failed."
    exit 1
fi

# Create systemd service for Snort
echo "Creating systemd service for Snort..."
sudo bash -c 'cat > /etc/systemd/system/snort.service << EOF
[Unit]
Description=Snort 3 NIDS
After=network.target

[Service]
ExecStart=/usr/local/bin/snort -c /usr/local/etc/snort/snort.lua -i eth0
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF'

# Enable and start Snort service
echo "Enabling and starting Snort service..."
sudo systemctl daemon-reload
sudo systemctl enable snort
sudo systemctl start snort

# Final check
echo "Checking Snort service status..."
sudo systemctl status snort

echo "Snort 3.5.2.0 installation and setup complete."
