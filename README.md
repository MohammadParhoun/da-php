# da-php.sh

A Bash script to manage and update `php.ini` configurations for all installed PHP versions on DirectAdmin servers. Ideal for server admins looking to apply consistent PHP configuration settings across environments.

## ✨ Features

- Automatically finds all installed PHP versions.
- Updates important `php.ini` settings:
  - `max_execution_time`, `max_input_time`, `max_input_vars`
  - `memory_limit`, `upload_max_filesize`, `post_max_size`
  - `display_errors`, `date.timezone`, `disable_functions`
- Automatically installs and enables ionCube Loader for all PHP versions.
- Backs up original `php.ini` files before making changes.
- Restarts appropriate PHP-FPM and web server services (Apache, Nginx, LiteSpeed, etc.)
- Detects DirectAdmin's active web server from CustomBuild config.

## 📦 Requirements

- Root access
- DirectAdmin server with CustomBuild
- Bash shell
- `systemctl` and typical Linux CLI tools (`grep`, `awk`, `perl`, `sed`, etc.)

## 🛠️ Installation

Just download the script and make it executable:
```bash```
```chmod +x da-php.sh```

## 🚀 Usage

sudo ./da-php.sh

ℹ️ Must be run as root!

## 📂 Backup

Before modifying any file, the script creates a backup:

/usr/local/phpXX/lib/php.ini.bak
If the backup file already exists, it increments:

/usr/local/phpXX/lib/php.ini.bak.1, .2, ...

## 📝 Changelog
- **v1.1 (2025-10-18)**: Added automatic ionCube Loader installation with silent error handling.  
- **v1.0 (2025-04-24)**: Initial release with PHP settings management.

