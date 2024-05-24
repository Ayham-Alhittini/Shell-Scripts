#!/bin/bash

print_title() {
    echo -e "\033[1;36m$1\033[0m"
}
print_alert() {
    echo -e "\033[1;31m$1\033[0m"
}

check_disk_space() {
    print_title "Checking Disk Space..."
    while read -r usage partition mount_point; do
        usage=$(echo $usage | sed 's/%//')  # Remove '%' and get just the number
        if [[ $usage -ge 90 ]]; then
            print_alert "Partition $partition (mounted at $mount_point) is at $usage% capacity."
            echo "Recommendation: Disk usage is above 90% on $partition (mounted at $mount_point). Consider cleaning up disk."
        else
            echo "Partition $partition (mounted at $mount_point) is at $usage% capacity. Disk usage is below 90%."
        fi
    done < <(df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5, $1, $6 }')
    echo
}

check_memory_usage() {
    print_title "Checking Memory Usage..."
    mem_free=$(free -m | awk '/^Mem:/ {print int($7/$2 * 100.0)}') # $7 is available memory, and 2 total memory
    echo "Free memory is $mem_free% of total."
    if [[ $mem_free -lt 20 ]]; then
        print_alert "Recommendation: Free memory is low at $mem_free%. Consider adding more memory or closing some applications."
    else
        echo "Free memory is at a healthy level."
    fi
    echo
}

check_running_services() {
    print_title "Checking Running Services..."
    systemctl list-units --type=service --state=running
    echo
}

check_recent_updates() {
    print_title "Checking Recent System Updates..."
    tail -n 50 /var/log/apt/history.log | tac
}

main() {
    echo
    print_alert "System Health Report"
    date
    echo "===================="

    # Disk Space
    check_disk_space

    # Memory Usage
    check_memory_usage

    # Running Services
    check_running_services

    # System Updates
    check_recent_updates

    echo "===================="
    print_alert "End of Report"
    echo
}
main