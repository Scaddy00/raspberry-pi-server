# Raspberry Pi Server - Python Applications Management System

This project implements an automated management system for Python applications on Raspberry Pi, using `systemd` for automatic startup and `screen` for session management.

## 📋 Overview

The system automatically manages the startup and monitoring of multiple Python applications through separate `screen` sessions, with centralized logging and integrated diagnostics.

### Managed Applications

The system currently manages the following Python applications:

- **Discord Bot** (`apps/wish_discord_bot/main.py`)
- **JW Group App** (`apps/jw_group_app/main.py`) 
- **Talk Sync App** (`apps/talk_sync_app/main.py`)

## 🏗️ Architecture

```
raspberry_pi_server/
├── start_scripts.service    # Systemd configuration
├── start_scripts.sh        # Main startup script
├── stop_scripts.sh         # Shutdown script
├── install_service.sh      # Installation script
└── debug_service.sh        # Diagnostics script
```

## 📁 Directory Structure

```
/home/scad-pi/
├── raspberry_pi_server/   # Repository folder
│   ├── start_scripts.sh   # Main startup script
│   ├── stop_scripts.sh    # Shutdown script
│   ├── debug_service.sh   # Diagnostics script
│   ├── install_service.sh # Installation script
│   ├── start_scripts.service # Systemd configuration
│   └── README.md          # Documentation
├── apps/                  # Python applications
│   ├── wish_discord_bot/
│   ├── jw_group_app/
│   └── talk_sync_app/
├── bash_logs/             # Centralized logs
│   ├── start_scripts.log  # Main log
│   ├── discord_bot.log    # Discord bot log
│   ├── jw_group.log       # JW Group app log
│   └── talk_sync.log      # Talk Sync app log
└── [other project files]
```

## 🚀 Installation

### Prerequisites

- Raspberry Pi with Raspberry Pi OS
- Python 3 installed
- `scad-pi` user configured
- Python applications in the specified directories

### Installation Steps

1. **Clone or copy the project files:**
   ```bash
   # Make sure you're in the project directory
   cd /path/to/raspberry_pi_server
   ```

2. **Run the installation script:**
   ```bash
   sudo ./install_service.sh
   ```

3. **Verify the installation:**
   ```bash
   sudo systemctl status start_scripts.service
   ```

**Note:** The installation script will copy `start_scripts.sh` to `/home/scad-pi/raspberry_pi_server/` and configure the systemd service to use this location.

## ⚙️ Configuration

### Modifying Managed Applications

To add or remove applications, edit the `start_scripts.sh` file:

```bash
# Add new applications here
python_apps["app_name"]="path/to/app/main.py"
```

### Service Configuration

The systemd service is configured in `start_scripts.service`:

- **User:** `scad-pi`
- **Working directory:** `/home/scad-pi`
- **Auto-restart:** Enabled (10 seconds wait)
- **Logs:** Managed via journald

## 🎮 Usage

### Main Commands

#### Systemd Service Management

```bash
# Start the service
sudo systemctl start start_scripts.service

# Stop the service
sudo systemctl stop start_scripts.service

# Restart the service
sudo systemctl restart start_scripts.service

# Check status
sudo systemctl status start_scripts.service

# Enable/disable automatic startup
sudo systemctl enable start_scripts.service
sudo systemctl disable start_scripts.service
```

#### Screen Sessions Management

```bash
# View all active screen sessions
screen -ls

# Connect to a specific session
screen -r pyapp_discord_bot
screen -r pyapp_jw_group
screen -r pyapp_talk_sync

# Exit a session (Ctrl+A, then D)
# Within the screen session: Ctrl+A, D
```

#### Management Scripts

```bash
# Manually start applications
./start_scripts.sh

# Stop all applications
./stop_scripts.sh

# Diagnose problems
./debug_service.sh
```

### Monitoring and Logs

#### Log Viewing

```bash
# Systemd service logs
sudo journalctl -u start_scripts.service -f

# Main logs
tail -f /home/scad-pi/bash_logs/start_scripts.log

# Application-specific logs
tail -f /home/scad-pi/bash_logs/discord_bot.log
tail -f /home/scad-pi/bash_logs/jw_group.log
tail -f /home/scad-pi/bash_logs/talk_sync.log
```

#### Status Check

```bash
# General system status
sudo systemctl status start_scripts.service

# Active screen sessions
screen -ls

# Running Python processes
ps aux | grep python
```

## 🔧 Troubleshooting

### Automatic Diagnostics

Run the diagnostics script to identify common problems:

```bash
./debug_service.sh
```

This script verifies:
- Presence of systemd service file
- Service status
- Recent logs
- Script permissions
- Script executability

### Common Problems

#### Service won't start
```bash
# Check logs
sudo journalctl -u start_scripts.service -n 50

# Verify permissions
ls -la /home/scad-pi/start_scripts.sh

# Manual test
cd /home/scad-pi && ./start_scripts.sh
```

#### Applications won't start
```bash
# Check specific logs
tail -f /home/scad-pi/bash_logs/*.log

# Verify Python dependencies
python3 -c "import sys; print(sys.path)"
```

#### Screen sessions don't create
```bash
# Verify screen is installed
which screen

# Check permissions
ls -la /home/scad-pi/
```

## 📊 Monitoring

### Metrics to Monitor

- **Systemd service status**
- **Number of active screen sessions**
- **Memory usage of Python applications**
- **Error logs in applications**

### Monitoring Commands

```bash
# General status
sudo systemctl status start_scripts.service

# Active sessions
screen -ls

# Resource usage
htop
top

# Real-time logs
sudo journalctl -u start_scripts.service -f
```

## 🔄 Maintenance

### Updates

1. **Stop the service:**
   ```bash
   sudo systemctl stop start_scripts.service
   ```

2. **Update files:**
   ```bash
   # Copy new files
   cp start_scripts.sh /home/scad-pi/
   chmod +x /home/scad-pi/start_scripts.sh
   ```

3. **Restart the service:**
   ```bash
   sudo systemctl start start_scripts.service
   ```

### Backup

```bash
# Configuration backup
sudo cp /etc/systemd/system/start_scripts.service /backup/

# Logs backup
tar -czf logs_backup_$(date +%Y%m%d).tar.gz /home/scad-pi/bash_logs/
```

## 📝 Technical Notes

### Implementation Details

- **Systemd Service:** Manages automatic startup and restart
- **Screen Sessions:** Each Python application runs in a separate screen session
- **Logging:** Centralized logs with timestamps for each application
- **Error Handling:** Automatic restart in case of crashes

### Security

- The service runs with the `scad-pi` user (not root)
- Logs are saved in dedicated directories
- Appropriate permissions on scripts

## 🤝 Contributing

To modify or extend the system:

1. Edit `start_scripts.sh` to add new applications
2. Update `start_scripts.service` if necessary
3. Test changes with `debug_service.sh`
4. Restart the service to apply changes

## 📞 Support

In case of problems:

1. Run `./debug_service.sh` for automatic diagnostics
2. Check logs in `/home/scad-pi/bash_logs/`
3. Verify service status with `systemctl status start_scripts.service`
4. Check screen sessions with `screen -ls`

---

**Version:** 1.0  
**Date:** $(date +%Y-%m-%d)  
**Author:** Raspberry Pi Server System 