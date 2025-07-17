# Raspberry Pi Python App Manager & Service Installer

This repository provides a complete system to:
- Manage multiple Python applications in parallel using screen
- Automate the start/stop of apps
- Install and manage a systemd service for automatic startup
- Monitor and view logs

## 📁 Folder Structure

```
app_manager/
  manage_apps.sh           # Main script to manage all apps
  start_scripts.sh         # Starts all apps in screen sessions
  stop_scripts.sh          # Stops all apps
  config_utils.sh          # Utility to read the JSON configuration
  apps_config.json         # Centralized app configuration

service_installer/
  python-apps-autostart.service    # systemd unit file for automatic startup
  install_service.sh       # Script to install the service
  set_permissions.sh       # Script to set correct permissions
  debug_service.sh         # Script to debug the service
```

---

## ⚙️ Requirements

- **Python 3** installed and accessible as `python3`
- **jq** for JSON parsing:
  ```bash
  sudo apt-get install jq
  ```
- **screen** to manage sessions:
  ```bash
  sudo apt-get install screen
  ```

---

## 🚀 Python Application Management (`app_manager/`)

### 1. App Configuration

Edit `app_manager/apps_config.json` to add/remove apps:
```json
{
  "apps": {
    "my_app": {
      "script_path": "apps/my_app/main.py",
      "screen_name": "pyapp_my_app",
      "description": "Description of my app"
    }
  },
  "settings": {
    "main_dir": "/home/pi",
    "python_cmd": "python3",
    "log_dir": "/home/pi/bash_logs"
  }
}
```

### 2. Main Commands

Go to the `app_manager/` folder and make the scripts executable:
```bash
chmod +x *.sh
```

Run the commands:
```bash
# Start all apps
./manage_apps.sh start

# Stop all apps
./manage_apps.sh stop

# Detailed status
./manage_apps.sh status

# Restart all apps
./manage_apps.sh restart

# List configured apps
./manage_apps.sh list

# Show recent logs
./manage_apps.sh logs
```

### 3. Output Example

**Status**
```
=== Application Status ===
Total configured applications: 2

App: my_app
  Description: Description of my app
  Script: /home/pi/apps/my_app/main.py
  Screen: pyapp_my_app
  Status: RUNNING
  Script file: EXISTS

=== Summary ===
Running: 1
Stopped: 1
Dead: 0
Missing scripts: 0
```

**Logs**
```
=== my_app ===
Last 10 lines of my_app.log:
2024-01-15 10:30:15 - INFO - App started
...
```

---

## 🛡️ Systemd Service Installation & Management (`service_installer/`)

### 1. Main Files
- `python-apps-autostart.service`: systemd unit file
- `install_service.sh`: installs/updates the service
- `set_permissions.sh`: sets correct permissions
- `debug_service.sh`: helps debug the service

### 2. Service Installation

Go to the `service_installer/` folder and make the scripts executable:
```bash
chmod +x *.sh
```

Install the service:
```bash
sudo ./install_service.sh
```

Check the service status:
```bash
systemctl status python-apps-autostart.service
```

View the service logs:
```bash
journalctl -u python-apps-autostart.service -e
```

### 3. Debug & Permissions

- Use `set_permissions.sh` to fix file/script permissions
- Use `debug_service.sh` to manually test script startup as systemd would

---

## 📝 Useful Notes

- **Adding new apps**: just edit `apps_config.json` and restart
- **Logs**: all logs are in `log_dir` (e.g. `/home/pi/bash_logs`)
- **Screen**: each app runs in a separate screen session, you can attach with `screen -r screen_name`
- **Safety**: only apps defined in the config are managed/terminated
- **Validation**: configuration errors are reported on screen and in the logs

---

## ❓ Troubleshooting

- **App does not start**: check script path, permissions, logs, and that `python3` is installed
- **Service does not start**: use `systemctl status python-apps-autostart.service` and `journalctl -u python-apps-autostart.service`
- **Screen "Dead"**: restart with `./manage_apps.sh restart` or clean with `screen -wipe`
- **jq not found**: `sudo apt-get install jq`
- **Permissions**: make sure all scripts are executable

---

## 📚 Example Full Workflow

```bash
# 1. Configure apps in app_manager/apps_config.json
# 2. Make all scripts executable
chmod +x app_manager/*.sh service_installer/*.sh

# 3. Install the service (optional)
cd service_installer
sudo ./install_service.sh

# 4. Manage the apps
cd ../app_manager
./manage_apps.sh start
./manage_apps.sh status
./manage_apps.sh logs
```

---

**For any questions, check this README or the comments in the individual scripts!** 