#!/bin/sh

# This is open source software, licensed under the MIT License.
#
# Copyright (C) 2024 BobbyUnknown
#
# Description:
# This software provides a RAM release scheduling application for OpenWrt.
# The application allows users to configure and automate the process of
# releasing RAM on their OpenWrt routers at specified intervals, helping
# to optimize system performance and resource management through
# a user-friendly web interface.


. /lib/functions.sh
. /usr/share/libubox/jshn.sh

export TZ='Asia/Jakarta'

LOG_FILE="/var/log/ram_release.log"
PID_FILE="/var/run/ram_release.pid"

log_message() {
    local timestamp=$(TZ='Asia/Jakarta' date +"%Y-%m-%d %H:%M:%S %Z")
    echo "$timestamp: $1" >> "$LOG_FILE"
    logger -t "RAM Release" "$1"
}

get_config() {
    config_load "77_syscontrol"
    config_get enabled schedule enabled "0"
    config_get time schedule time
    config_get days schedule days
}

update_cron() {
    get_config
    log_message "Update cron started"
    log_message "Enabled: $enabled, Time: $time, Days: $days"

    sed -i '/ram_release/d' /etc/crontabs/root
    if [ "$enabled" = "1" ]; then
        cron_days=$(echo $days | sed 's/mon/1/g; s/tue/2/g; s/wed/3/g; s/thu/4/g; s/fri/5/g; s/sat/6/g; s/sun/0/g')
        hour=$(echo $time | cut -d: -f1)
        minute=$(echo $time | cut -d: -f2)
        cron_entry="$minute $hour * * $cron_days TZ='Asia/Jakarta' /usr/bin/ram_release.sh release"
        echo "$cron_entry" >> /etc/crontabs/root
        log_message "Cron job updated: $cron_entry"
    else
        log_message "Schedule disabled"
    fi
    /etc/init.d/cron restart
}

release_ram() {
    log_message "RAM release started"
    sync
    echo 3 > /proc/sys/vm/drop_caches
    swapoff -a && swapon -a
    echo 1 > /proc/sys/vm/compact_memory
    free_result=$(free -m)
    log_message "RAM release executed. Current memory state:\n$free_result"
}

start_service() {
    if [ -f "$PID_FILE" ]; then
        log_message "Service already running"
        exit 0
    fi
    get_config
    if [ "$enabled" = "1" ]; then
        update_cron
        echo $$ > "$PID_FILE"
        log_message "Service started"
    else
        log_message "Service not enabled"
    fi
}

stop_service() {
    if [ -f "$PID_FILE" ]; then
        rm "$PID_FILE"
        sed -i '/ram_release/d' /etc/crontabs/root
        /etc/init.d/cron restart
        log_message "Service stopped"
    else
        log_message "Service not running"
    fi
}

case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        stop_service
        start_service
        ;;
    update)
        update_cron
        ;;
    release)
        release_ram
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|update|release}"
        exit 1
        ;;
esac

exit 0
