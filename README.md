# Raspberry Pi Python App Manager & Service Installer

This repository provides a complete system to:
- Manage multiple Python applications in parallel using screen
- Automate the start/stop of apps
- Install and manage a systemd service for automatic startup
- Automatically restart crashed apps with a watchdog timer
- Monitor and view logs, with automatic log rotation

---

## 📋 Table of Contents

- [🚦 Step-by-step Installation Guide](#-step-by-step-installation-guide)
- [📁 Folder Structure](#-folder-structure)
- [📄 Files and Folders: Description and Usage](#-files-and-folders-description-and-usage)
- [⚙️ Requirements](#️-requirements)
- [🚀 How to Use the System](#-how-to-use-the-system)
  - [1. App Configuration](#1-app-configuration)
  - [2. Main Commands (from app_manager/)](#2-main-commands-from-app_manager)
  - [3. Service Installation and Management (from service_installer/)](#3-service-installation-and-management-from-service_installer)
  - [4. Watchdog (automatic restart)](#4-watchdog-automatic-restart)
  - [5. Log rotation](#5-log-rotation)
- [📝 Useful Notes](#-useful-notes)
- [❓ Troubleshooting](#-troubleshooting)

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
     ./manage_apps.sh heal       # Restart only what crashed
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
  manage_apps.sh            # Main script to manage all apps (start/stop/status/list/logs/heal)
  config_utils.sh           # Utility functions for configuration
  apps_config.json          # Centralized app configuration
  apps_config_template.json # Configuration template
  debug/
    validate_config.sh      # Debug for configuration and functions
    repair_environment.sh   # Script for installation fix and recovery

service_installer/
  python-apps-autostart.service   # systemd unit template for autostart
  python-apps-watchdog.service    # systemd unit template for the watchdog
  python-apps-watchdog.timer      # timer that runs the watchdog every 5 minutes
  logrotate-python-apps.template  # logrotate config template
  install_service.sh              # Installs/updates the systemd units
  uninstall_service.sh            # Removes the systemd units
  fix_permissions.sh              # Sets correct permissions on scripts
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
  - **repair_environment.sh**: Solves common installation issues (creates the log directory, checks interpreters, sets permissions, checks jq). Reads all paths from the configuration. Pass `--create-placeholders` to also generate stub `main.py` files for missing scripts.

### service_installer/
- **python-apps-autostart.service**: systemd unit template for automatic startup of Python apps at system boot. Uses `__USER__` and `__INSTALL_DIR__` placeholders, replaced during installation.
- **python-apps-watchdog.service** / **python-apps-watchdog.timer**: unit and timer that run `manage_apps.sh heal` every 5 minutes to restart crashed apps.
- **logrotate-python-apps.template**: logrotate configuration template for the app logs.
- **install_service.sh**: Installs and configures the systemd units for the current user, plus the logrotate config. Detects the repository path automatically; accepts `--no-watchdog` and `--no-logrotate`.
- **uninstall_service.sh**: Removes the installed units and logrotate config. Leaves running apps and logs alone.
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
    },
    "my_venv_app": {
      "script_path": "apps/my_venv_app/main.py",
      "screen_name": "pyapp_my_venv_app",
      "python_cmd": "/home/$USER/apps/my_venv_app/.venv/bin/python",
      "description": "App running in its own virtualenv"
    }
  },
  "settings": {
    "main_dir": "/home/$USER",
    "python_cmd": "python3",
    "log_dir": "/home/$USER/bash_logs"
  }
}
```

**Per-app interpreter:** `python_cmd` inside an app is optional. When omitted, the
app uses `settings.python_cmd`. Set it to a virtualenv interpreter when an app needs
its own dependencies.

**Validation:** the configuration is checked on every run. Startup fails with a clear
message if a required field is missing or if two apps share the same `screen_name`.

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

# Restart only the apps that are stopped or dead
./manage_apps.sh heal
```

### 3. Service Installation and Management (from service_installer/)

Install the services:
```bash
sudo ./install_service.sh
```

The script can be run from any directory. Options:
- `--no-watchdog` — skip the watchdog service and timer
- `--no-logrotate` — skip the logrotate configuration

**How the service installation works:**
1. Detects the repository location from the script's own path
2. Reads the unit templates and replaces `__USER__` and `__INSTALL_DIR__`
3. Writes user-specific units to `/etc/systemd/system/` (e.g., `python-apps-autostart-mario.service`)
4. Enables the autostart service and starts the watchdog timer
5. Writes `/etc/logrotate.d/python-apps`

**Template variables:**
- `__USER__` → the user who ran sudo (e.g., `mario`)
- `__INSTALL_DIR__` → the detected repository path (e.g., `/home/mario/raspberry-pi-server`)

> **Upgrading from an older install:** units installed by a previous version used the
> `%i` placeholder and a hardcoded path. Re-run `sudo ./install_service.sh` once to
> regenerate them. The old units keep working until you do.

Check the service status:
```bash
systemctl status python-apps-autostart-$(whoami).service
```

View the service logs:
```bash
journalctl -u python-apps-autostart-$(whoami).service -e
```

Remove everything:
```bash
sudo ./uninstall_service.sh
```
This removes the systemd units and the logrotate config. Running apps and log files
are left untouched.

### 4. Watchdog (automatic restart)

The autostart service is `Type=oneshot`: it runs once at boot. On its own it would
never notice an app crashing later. The watchdog closes that gap.

`python-apps-watchdog.timer` runs `manage_apps.sh heal` every 5 minutes. `heal`
restarts only the apps whose screen session is missing or dead — healthy apps are
never touched.

```bash
# When does it run next?
systemctl list-timers | grep python-apps

# What did it do?
journalctl -u python-apps-watchdog-$(whoami).service -e

# Run it manually
cd app_manager && ./manage_apps.sh heal
```

To change the interval, edit `OnUnitActiveSec` in `python-apps-watchdog.timer` and
re-run `sudo ./install_service.sh`.

### 5. Log rotation

`install_service.sh` writes `/etc/logrotate.d/python-apps`, rotating the logs in
`log_dir` weekly and keeping 4 compressed generations.

It uses `copytruncate` because the Python processes hold the log file open: without
it they would keep writing to the rotated file and the new one would stay empty.

```bash
# Dry run, shows what logrotate would do
sudo logrotate -d /etc/logrotate.d/python-apps
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
- **Logs**: Each app writes to `log_dir/<app_name>.log`; the manager writes to `manage_apps.log`.
- **Screen**: Each app runs in a separate screen session, you can attach with `screen -r screen_name`.
  Since output is redirected to the log file, an attached session shows no output — read the log instead.
- **Safety**: Only apps defined in the config are managed/terminated. Screen names are matched
  exactly, so an app named `pyapp_bot` is never confused with `pyapp_bot2`.
- **Validation**: Configuration errors are reported on screen and in the logs.
- **Repair**: Use `repair_environment.sh` to fix common installation issues automatically.
  Add `--create-placeholders` if you also want stub `main.py` files created for missing scripts.
- **Virtualenvs**: Give an app its own interpreter with a per-app `python_cmd`.

---

## ❓ Troubleshooting

- **App does not start**: Check script path, permissions, logs, and that `python3` is installed.
- **Service does not start**: Use `systemctl status` and `journalctl` as above.
- **Screen "Dead"**: Run `./manage_apps.sh heal` to restart only what died, or `restart` for everything.
- **Log file empty**: The app may not have produced output yet. Apps are launched with `python -u`
  so output is unbuffered — if the file stays empty, check the app itself.
- **"screen_name is used by more than one app"**: Two apps share a screen name in the config.
  They would fight over the same session; give each one a unique name.
- **Service still uses the old path**: Re-run `sudo ./install_service.sh` to regenerate the units.
- **jq not found**: `sudo apt-get install jq`
- **Permissions**: Make sure all scripts are executable (`./fix_permissions.sh`).
- **Environment issues**: Run `./repair_environment.sh` to automatically fix common problems.
- **Configuration issues**: Run `./validate_config.sh` to check your setup.

---

## 📚 Example Full Workflow

```bash
# 1. Configure the apps in app_manager/apps_config.json
# 2. Make all scripts executable
./service_installer/fix_permissions.sh

# 3. (Optional) Repair environment if needed
./app_manager/debug/repair_environment.sh

# 4. (Optional) Install the service and the watchdog
sudo ./service_installer/install_service.sh

# 5. Manage the apps
cd app_manager
./manage_apps.sh start
./manage_apps.sh status
./manage_apps.sh logs

# 6. (Optional) Debug if needed
./debug/validate_config.sh
```

All scripts resolve their own location, so they work from any directory. 