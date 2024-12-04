# Update and install linux packages:
sudo apt update && apt upgrade -y
sudo apt install gcc rpm htop make -y
sudo apt install linux-headers-`uname -r` -y
sudo apt install linux-image-`uname -r` -y
sudo apt update && sudo apt upgrade -y
sudo apt install python3-pip python3-dev libxml2-dev libxslt1-dev zlib1g-dev libsasl2-dev libldap2-dev build-essential libssl-dev libffi-dev libjpeg-dev libpq-dev liblcms2-dev libblas-dev libatlas-base-dev htop neofetch redis-tools git wget curl redis-server net-tools nodejs npm libnss3-tools quota docker-compose -y


# Swap
# Update and install linux packages:
HOSTNAME="snort.cyberitex.com"
RAM=4G
sudo fallocate -l $RAM /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo sysctl vm.swappiness=10

CONFIG_FILE="/etc/sysctl.conf"
CONFIG_LINES=("vm.swappiness=10" "vm.vfs_cache_pressure=754" "vm.max_map_count=262144" "fs.inotify.max_user_watches=524288")

for line in "${CONFIG_LINES[@]}"; do
    if ! grep -q "^$line" "$CONFIG_FILE"; then
        echo "$line" | sudo tee -a "$CONFIG_FILE" > /dev/null
    fi
done
hostnamectl set-hostname $HOSTNAME
