# Snort 3 Installation Script

This repository contains a comprehensive Bash script to automate the installation and configuration of **Snort 3.5.2.0** on Debian-based Linux systems. It includes downloading dependencies, setting up configuration files, and integrating community rules to streamline the setup process.

## Features

- Installs Snort 3.5.2.0 from source.
- Downloads and integrates Snort community rules.
- Configures `HOME_NET` and other essential variables.
- Sets up a systemd service for Snort to run as a daemon.
- Validates the Snort configuration.

## Requirements

- A Debian-based Linux distribution (e.g., Ubuntu, Debian).
- Root or sudo privileges.

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/CyberITEX/CyberITEX-Snort3-Installer.git
cd CyberITEX-Snort3-Installer
```

### 2. Make the Script Executable

```bash
chmod +x install_snort3_with_rules.sh
```

### 3. Run the Script

```bash
sudo ./install_snort3_with_rules.sh
```

The script will handle the entire process, including installing dependencies, downloading Snort, and configuring the environment.

## Configuration

- **`HOME_NET`:** The script sets the `HOME_NET` variable to `192.168.0.0/16` by default. You can update this later in the `snort.lua` configuration file:
  ```bash
  sudo nano /usr/local/etc/snort/snort.lua
  ```
  Replace `192.168.0.0/16` with your internal network range.

- **Network Interface:** The script uses `eth0` as the default monitoring interface. If your system uses a different interface, update it in the systemd service file:
  ```bash
  sudo nano /etc/systemd/system/snort3.service
  ```
  Replace `eth0` with your desired interface.

## Validating Snort Configuration

After installation, validate the configuration:
```bash
snort -c /usr/local/etc/snort/snort.lua -T
```

## Logs

Snort logs and alerts are stored in `/var/log/snort/`.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to improve this script.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Snort](https://www.snort.org/)
- [CyberITEX](https://cyberitex.com/) for sharing this script with the community.
```

---