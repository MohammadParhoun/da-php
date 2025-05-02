#!/bin/bash
# ======================================================================================================
# Script Name: da-php.sh
# Description: A script for updating php.ini settings across multiple PHP versions on DirectAdmin servers.
# Author: Mohammad Parhoun <mohammad.parhoun.7@gmail.com>
# Version: 1.0
#
# Copyright (c) 2025 Mohammad Parhoun. All Rights Reserved.
# This script is licensed under the MIT License.
#
# Changelog:
# v1.0 - 2025-04-24: Initial release.
# ======================================================================================================


GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"


if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root.${RESET}" >&2
    exit 1
fi


# ------------ Execution & Input Limits ------------
max_execution_time=400    # Max time (in seconds) a script can run. Prevents endless loops. Default: 30
max_input_time=400        # Max time to receive input data (like POST or GET). Default: 60
max_input_vars=5000       # Max number of form fields accepted. Prevents abuse. Default: 1000
memory_limit="512M"         # Max memory a PHP script can use. Prevents overload. Default: 128M

# ------------ File Uploads ------------
#file_uploads = On              # Allows users to upload files.
upload_max_filesize="500M"      # Max size of a single uploaded file. Default: 64M
post_max_size="500M"            # Max size of total POST data (including files). Default: 64M

# ------------ Output & Buffering ------------
#output_buffering = 4096         # Speeds up output by grouping it into chunks.
#implicit_flush = Off            # Waits until script ends to send output (faster).

# ------------ Error Handling ------------
display_errors="on"                     # Show errors to users (unsafe for production).
#log_errors = On                        # Log errors to a file.

# ------------ Timezone ------------
date_timezone="\"Asia/Tehran\""

# ------------ Security Settings ------------
#expose_php = Off                        # Hides PHP version in HTTP headers.
#enable_dl = Off                         # Disables dynamic loading of PHP extensions (for safety).
disable_functions="exec,system,passthru,shell_exec,proc_close,proc_open,dl,popen,show_source,posix_kill,posix_mkfifo,posix_getpwuid,posix_setpgid,posix_setsid,posix_setuid,posix_setgid,posix_seteuid,posix_setegid,posix_uname,phpinfo"      # Disables risky functions like exec, shell_exec to stop system access.

webserver=$(grep '^webserver=' /usr/local/directadmin/custombuild/options.conf | cut -d "=" -f 2)


restart_webserver() {

    if [[ -z "$webserver" ]]; then
        echo -e "${RED}Error: Could not determine webserver from CustomBuild configuration.${RESET}" >&2
        return 1
    fi

    if [[ "$webserver" == "apache" ]]; then
        if systemctl restart httpd; then
            echo -e "${GREEN}Restarted Apache successfully.${RESET}"
        else
            echo -e "${RED}Error: Failed to restart Apache.${RESET}" >&2
            return 1
        fi

    elif [[ "$webserver" == "litespeed" || "$webserver" == "openlitespeed" ]]; then
       if systemctl restart lsws; then
            echo -e "${GREEN}Restarted $webserver successfully.${RESET}"
        else
            echo -e "${RED}Error: Failed to restart $webserver.${RESET}" >&2
            return 1
        fi

    elif [[ "$webserver" == "nginx" ]]; then
        if systemctl restart nginx; then
            echo -e "${GREEN}Restarted Nginx successfully.${RESET}"
        else
            echo -e "${RED}Error: Failed to restart Nginx.${RESET}" >&2
            return 1
        fi

    elif [[ "$webserver" == "nginx_apache" ]]; then
        if systemctl restart nginx && systemctl restart httpd; then
            echo -e "${GREEN}Restarted Nginx and Apache successfully.${RESET}"
        else
            echo -e "${RED}Error: Failed to restart Nginx and/or Apache.${RESET}" >&2
            return 1
        fi
    else
        echo -e "${RED}Warning: Unknown webserver '$webserver'. Cannot restart.${RESET}" >&2
        return 0
    fi

    return 0

}

declare -a php_versions
mapfile -t php_versions < <(/usr/local/directadmin/custombuild/build options | grep PHP | awk '{print $3}' | perl -pe 's/\e\[?.*?[\@-~]//g') # Removing ANSI Escape Codes


for php in ${php_versions[@]}; do
    success=true
    path=$(echo $php | tr -d ".")
    full_path="/usr/local/php$path/lib/php.ini"

    if [[ ! -f "$full_path" ]]; then
        echo -e "${RED}Error: PHP configuration file not found: $full_path ${RESET}" >&2
        continue
    fi


    backup_file="$full_path.bak"
    counter=1

    while [[ -f "$backup_file" ]]; do
        backup_file="$full_path.bak.$counter"
        ((counter++))
    done

    if cp "$full_path" "$backup_file"; then
        echo -e "${YELLOW}Created backup: $backup_file ${RESET}"
    else
        echo -e "${RED}Warning: Failed to create backup of $full_path ${RESET}" >&2
    fi


    sed -i "s|^max_execution_time =.*$|max_execution_time = ${max_execution_time}|" "$full_path" || success=false
    sed -i "s|^max_input_time =.*$|max_input_time = ${max_input_time}|" "$full_path" || success=false
    sed -i "s|^;*max_input_vars =.*$|max_input_vars = ${max_input_vars}|" "$full_path" || success=false
    sed -i "s|^memory_limit =.*$|memory_limit = ${memory_limit}|" "$full_path" || success=false
    sed -i "s|^upload_max_filesize =.*$|upload_max_filesize = ${upload_max_filesize}|" "$full_path" || success=false
    sed -i "s|^post_max_size =.*$|post_max_size = ${post_max_size}|" "$full_path" || success=false
    sed -i "s|^date.timezone =.*$|date.timezone = ${date_timezone}|" "$full_path" || success=false
    sed -i "s|^disable_functions =.*$|disable_functions = ${disable_functions}|" "$full_path" || success=false
    sed -i "s|^display_errors =.*$|display_errors = ${display_errors}|" "$full_path" || success=false



    if $success; then
        echo -e "${GREEN}Successfully updated PHP settings in $full_path ${RESET}"
    else
        echo -e "${RED}Error: Failed to update PHP settings in $full_path ${RESET}" >&2
    fi


    if [[ "$webserver" == "apache" || "$webserver" == "nginx" || "$webserver" == "nginx_apache" ]]; then
        php_fpm_service="php-fpm$path"
        if systemctl restart "$php_fpm_service"; then
            echo -e "${GREEN}Restarted $php_fpm_service successfully. ${RESET}"
        else
            echo -e "${RED}Error: Failed to restart $php_fpm_service. ${RESET}" >&2
        fi
    fi

    echo ""

done

echo ""

restart_webserver

exit 0

    


