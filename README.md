# Raspberry Pi Python App Manager & Service Installer

This repository provides a complete system to:
- Manage multiple Python applications in parallel using screen
- Automate the start/stop of apps
- Install and manage a systemd service for automatic startup
- Monitor and view logs

---

## 🚦 Step-by-step Installation Guide

Follow these steps to set up and use the Python App Manager on your Raspberry Pi (or compatible Linux system):

1. **Clone the repository**
   ```bash
   git clone <REPO_URL>
   cd raspberry-pi-server
   ```

2. **Install required dependencies**
   ```bash
   sudo apt-get update
   sudo apt-get install python3 jq screen
   ```

3. **Configure your applications**
   - Edit `app_manager/apps_config.json` to add your Python apps and adjust settings (see the example in the next section).

4. **Make all scripts executable**
   ```bash
   chmod +x app_manager/*.sh service_installer/*.sh
   chmod +x app_manager/debug/*.sh service_installer/debug/*.sh
   ```

5. **(Optional) Fix permissions**
   - If you encounter permission issues, run:
     ```bash
     cd service_installer
     ./fix_permissions.sh
     cd ..
     ```

6. **(Optional) Install the systemd service for autostart**
   ```bash
   cd service_installer
   sudo ./install_service.sh
   cd ..
   ```
   - This will set up a systemd service to automatically start your apps at boot.

7. **Manage your applications**
   - Go to the app_manager directory:
     ```bash
     cd app_manager
     ```
   - Use the main commands:
     ```bash
     ./manage_apps.sh start      # Start all apps
     ./manage_apps.sh stop       # Stop all apps
     ./manage_apps.sh status     # Show status
     ./manage_apps.sh restart    # Restart all apps
     ./manage_apps.sh list       # List configured apps
     ./manage_apps.sh logs       # Show recent logs
     ```

8. **(Optional) Advanced debugging and repair**
   - Use the scripts in `app_manager/debug/` and `service_installer/debug/` for troubleshooting, configuration validation, or repairing the environment.
   - **Repair environment**: If you encounter issues, run:
     ```bash
     cd app_manager/debug
     ./repair_environment.sh
     ```
   - **Validate configuration**: Check your setup with:
     ```bash
     cd app_manager/debug
     ./validate_config.sh
     ```

---

## 📁 Folder Structure

```
app_manager/
  manage_apps.sh            # Main script to manage all apps (start/stop/status/list/logs)
  config_utils.sh           # Utility functions for configuration
  apps_config.json          # Centralized app configuration
  apps_config_template.json # Configuration template
  debug/
    validate_config.sh      # Debug for configuration and functions
    repair_environment.sh   # Script for installation fix and recovery

service_installer/
  python-apps-autostart.service # systemd unit file for autostart
  install_service.sh            # Installs/updates the systemd service
  fix_permissions.sh            # Sets correct permissions on scripts
  debug/
    test_service_startup.sh     # Debug for the systemd service
    check_service_installation.sh # Debug for service installation

README.md
.gitignore
.vscode/settings.json
```

---

## 📄 Files and Folders: Description and Usage

### app_manager/
- **manage_apps.sh**: Main script to manage all Python apps. Allows you to start, stop, check status, restart, list, and view logs of configured apps. All main operations go through this script.
- **config_utils.sh**: Collection of Bash functions to read and validate the JSON configuration using jq. Used by all main scripts.
- **apps_config.json**: Central configuration file where you define the apps to manage, paths, Python command, and log directory.
- **apps_config_template.json**: Example/template to create a new configuration.
- **debug/**: Contains debug and recovery scripts:
  - **validate_config.sh**: Checks the validity of the configuration and reading functions.
  - **repair_environment.sh**: Solves common installation issues (e.g. creates directories/logs, sets permissions, checks jq).

### service_installer/
- **python-apps-autostart.service**: systemd unit file template for automatic startup of Python apps at system boot. Uses `%i` as a placeholder for the username that gets replaced during installation.
- **install_service.sh**: Installs and configures the systemd service for the current user. Uses the template file, replaces `%i` with the current username, creates a user-specific service file (e.g., `python-apps-autostart-mario.service`), and enables it in systemd.
- **fix_permissions.sh**: Sets execution permissions on all main scripts in app_manager and service_installer.
- **debug/**: Contains debug scripts for the service:
  - **test_service_startup.sh**: Allows you to manually test the service startup as systemd would.
  - **check_service_installation.sh**: Checks correct installation and registration of the systemd service.

### Other files
- **README.md**: This file, with detailed instructions and explanations.
- **.gitignore**: Git configuration file.
- **.vscode/settings.json**: Local configuration for the VSCode editor (optional).

---

## ⚙️ Requirements

- **Python 3** installed and accessible as `python3`
- **jq** for JSON parsing:
  ```bash
  sudo apt-get install jq
  ```
- **screen** for session management:
  ```bash
  sudo apt-get install screen
  ```

---

## 🚀 How to Use the System

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
    "main_dir": "/home/$USER",
    "python_cmd": "python3",
    "log_dir": "/home/$USER/bash_logs"
  }
}
```

### 2. Main Commands (from app_manager/)

Make the scripts executable:
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

### 3. Service Installation and Management (from service_installer/)

Make the scripts executable:
```bash
chmod +x *.sh
```

Install the service:
```bash
sudo ./install_service.sh
```

**How the service installation works:**
1. The script reads the `python-apps-autostart.service` template file
2. Replaces all instances of `%i` with the current username
3. Creates a user-specific service file (e.g., `python-apps-autostart-mario.service`)
4. Copies it to `/etc/systemd/system/`
5. Enables the service for automatic startup

**Template variables:**
- `%i` → Current username (e.g., `mario`)
- Example: `User=%i` becomes `User=mario`
- Example: `/home/%i/raspberry-pi-server/` becomes `/home/mario/raspberry-pi-server/`

Check the service status:
```bash
systemctl status python-apps-autostart-$(whoami).service
```

View the service logs:
```bash
journalctl -u python-apps-autostart-$(whoami).service -e
```

To fix permission issues:
```bash
./fix_permissions.sh
```

For advanced debugging:
- Use the scripts in `debug/` in the respective folders to validate configuration, restore installation, or manually test the systemd service.

---

## 📝 Useful Notes

- **Adding new apps**: Edit `apps_config.json` and restart via `manage_apps.sh restart`.
- **Logs**: All logs are in the directory specified in `log_dir`.
- **Screen**: Each app runs in a separate screen session, you can attach with `screen -r screen_name`.
- **Safety**: Only apps defined in the config are managed/terminated.
- **Validation**: Configuration errors are reported on screen and in the logs.
- **Repair**: Use `repair_environment.sh` to fix common installation issues automatically.

---

## ❓ Troubleshooting

- **App does not start**: Check script path, permissions, logs, and that `python3` is installed.
- **Service does not start**: Use `systemctl status` and `journalctl` as above.
- **Screen "Dead"**: Restart with `./manage_apps.sh restart` or clean with `screen -wipe`.
- **jq not found**: `sudo apt-get install jq`
- **Permissions**: Make sure all scripts are executable (`./fix_permissions.sh`).
- **Environment issues**: Run `./repair_environment.sh` to automatically fix common problems.
- **Configuration issues**: Run `./validate_config.sh` to check your setup.

---

## 📚 Example Full Workflow

```bash
# 1. Configure the apps in app_manager/apps_config.json
# 2. Make all scripts executable
chmod +x app_manager/*.sh service_installer/*.sh

# 3. (Optional) Repair environment if needed
cd app_manager/debug
./repair_environment.sh
cd ../..

# 4. (Optional) Install the service
cd service_installer
sudo ./install_service.sh
cd ..

# 5. Manage the apps
cd app_manager
./manage_apps.sh start
./manage_apps.sh status
./manage_apps.sh logs

# 6. (Optional) Debug if needed
cd debug
./validate_config.sh
``` 