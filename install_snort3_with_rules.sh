#!/bin/bash

# Snort 3 Installation Script for Debian-Based Systems
# Ensure you run this script as root or with sudo privileges.

# Define the Snort version
SNORT_VERSION="3.5.2.0"

echo "Starting Snort $SNORT_VERSION installation process..."

# Section 1: Update the System
echo "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Section 2: Install Required Dependencies
echo "Installing dependencies..."
sudo apt-get install -y \
    cmake make gcc g++ flex bison libpcap-dev libpcre3-dev zlib1g-dev liblzma-dev \
    libssl-dev libhwloc-dev libdnet-dev libsqlite3-dev pkg-config autoconf git wget luajit libluajit-5.1-dev libdumbnet-dev

# Section 3: Install LibDAQ
echo "Cloning and installing LibDAQ..."
cd /tmp
git clone https://github.com/snort3/libdaq.git
cd libdaq
./bootstrap
./configure
make
sudo make install
sudo ldconfig  # Update linker configuration

# Section 4: Download and Install Snort
echo "Downloading Snort $SNORT_VERSION..."
cd /tmp
wget https://github.com/snort3/snort3/archive/refs/tags/$SNORT_VERSION.tar.gz -O snort3-$SNORT_VERSION.tar.gz
tar -xvzf snort3-$SNORT_VERSION.tar.gz
cd snort3-$SNORT_VERSION

echo "Building and installing Snort $SNORT_VERSION..."
mkdir build
cd build
cmake ..
make
sudo make install
sudo ldconfig  # Refresh dynamic linker

# Section 5: Verify Installation
echo "Verifying Snort installation..."
snort_version=$(snort -V 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "Snort installed successfully: $snort_version"
else
    echo "Snort installation failed. Please check the logs."
    exit 1
fi

# Section 6: Set Up Configuration Directories
echo "Setting up Snort configuration..."
sudo mkdir -p /usr/local/etc/snort/rules
sudo mkdir -p /usr/local/etc/snort/so_rules
sudo mkdir -p /usr/local/etc/snort/preproc_rules
sudo mkdir -p /var/log/snort

# Section 7: Add Example Rules
echo "Configuring local.rules..."
sudo bash -c 'cat >> /usr/local/etc/snort/rules/local.rules << EOF
# Detect ICMP packets (ping)
alert icmp any any -> any any (msg:"ICMP Packet Detected"; sid:1000001; rev:1;)

# Detect TCP packets on port 80 (HTTP)
alert tcp any any -> any 80 (msg:"HTTP Traffic Detected"; sid:1000002; rev:1;)

# Detect SSH attempts
alert tcp any any -> any 22 (msg:"SSH Connection Attempt Detected"; sid:1000003; rev:1;)

# Detect DNS queries
alert udp any any -> any 53 (msg:"DNS Query Detected"; sid:1000004; rev:1;)
EOF'

# Section 8: Modify snort_defaults.lua
if [ -f /usr/local/etc/snort/snort_defaults.lua ]; then
    echo "Updating snort_defaults.lua..."
    sudo sed -i '/^RULE_PATH = /c\RULE_PATH = "/usr/local/etc/snort/rules"' /usr/local/etc/snort/snort_defaults.lua
    sudo sed -i '/^BUILTIN_RULE_PATH = /c\BUILTIN_RULE_PATH = "/usr/local/etc/snort/builtin_rules"' /usr/local/etc/snort/snort_defaults.lua
    sudo sed -i '/^PLUGIN_RULE_PATH = /c\PLUGIN_RULE_PATH = "/usr/local/etc/snort/so_rules"' /usr/local/etc/snort/snort_defaults.lua
    if ! grep -q "^LOG_PATH = " /usr/local/etc/snort/snort_defaults.lua; then
        echo 'LOG_PATH = "/var/log/snort"' | sudo tee -a /usr/local/etc/snort/snort_defaults.lua > /dev/null
    else
        sudo sed -i '/^LOG_PATH = /c\LOG_PATH = "/var/log/snort"' /usr/local/etc/snort/snort_defaults.lua
    fi
else
    echo "snort_defaults.lua not found. Skipping modification."
fi

# Section 9: Download and Set Up Snort Community Rules
echo "Downloading and setting up Snort community rules..."
RULES_URL="https://www.snort.org/downloads/community/snort3-community-rules.tar.gz"
RULES_TMP="/tmp/snort3-community-rules.tar.gz"
RULES_DIR="/usr/local/etc/snort/rules"
COMMUNITY_RULES_FILE="$RULES_DIR/snort3-community.rules"

wget -q "$RULES_URL" -O "$RULES_TMP" && \
sudo mkdir -p "$RULES_DIR" && \
sudo tar -xzf "$RULES_TMP" -C "$RULES_DIR" && \
sudo mv "$RULES_DIR/snort3-community-rules/snort3-community.rules" "$COMMUNITY_RULES_FILE" && \
rm -f "$RULES_TMP" && \
rm -rf "$RULES_DIR/snort3-community-rules" || \
echo "Error: Failed to set up Snort community rules."

# Section 10: Include Rules in Configuration
SNORT_LUA="/usr/local/etc/snort/snort.lua"
COMMUNITY_RULES_INCLUDE="include (RULE_PATH .. '/local.rules')"
LOCAL_RULES_INCLUDE="include (RULE_PATH .. '/snort3-community.rules')"

add_rule_include() {
    local RULE_INCLUDE="$1"
    local FILE="$2"
    if grep -Fxq "$RULE_INCLUDE" "$FILE"; then
        echo "$RULE_INCLUDE is already included in $FILE."
    else
        sudo sed -i "/include 'snort_defaults.lua'/a $RULE_INCLUDE" "$FILE"
    fi
}

if [ -f "$SNORT_LUA" ]; then
    add_rule_include "$COMMUNITY_RULES_INCLUDE" "$SNORT_LUA"
    add_rule_include "$LOCAL_RULES_INCLUDE" "$SNORT_LUA"
else
    echo "Error: $SNORT_LUA not found."
    exit 1
fi

# Section 11: Set Permissions
sudo chmod -R 755 /usr/local/etc/snort
sudo chmod 644 /usr/local/etc/snort/rules/local.rules
sudo chmod 755 /var/log/snort
sudo chown -R root:root /usr/local/etc/snort
sudo chown -R root:root /var/log/snort

# Section 12: Validate Configuration
echo "Validating Snort configuration..."
snort -c /usr/local/etc/snort/snort.lua -T
if [[ $? -eq 0 ]]; then
    echo "Snort configuration is valid."
else
    echo "Snort configuration validation failed."
fi

# Section 13: Create and Start Systemd Service
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

sudo systemctl daemon-reload
sudo systemctl enable snort
sudo systemctl start snort

# Section 14: Final Check
echo "Checking Snort service status..."
sudo systemctl status snort

echo "Snort $SNORT_VERSION installation and setup complete."
