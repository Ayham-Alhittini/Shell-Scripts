#!/bin/bash

# Variables
directories=()
backupFinish=0
backupFormat="tar"
destination=""
tempLogs=()

############################### Helper functions ##############################
log() {
    for log in "$@"; do
        tempLogs+=("$log")
    done
}

create_logger_file() {
    logFile="$destination/backup.log"
    for log in "${tempLogs[@]}"; do
        echo -e "$log" >> "$logFile"
    done
}

print_error() {
    echo -e "\033[1;31m$1\033[0m"
    log "$1"
}

print_success() {
    echo -e "\033[1;32m$1\033[0m"
    log "$1"
}

print() {
    echo -e "$1"
    log "$1"
}

is_directory_in_list() {
    local directory="$1"
    for item in "${directories[@]}"; do
        if [[ $item == $directory ]]; then
            return 0
        fi
    done
    return 1
}

remove_directory() {
    local to_remove_dir="$1"
    local temp_array=()
    for dir in "${directories[@]}"; do
        if [[ $dir != $to_remove_dir ]]; then
            temp_array+=("$dir")
        fi
    done
    directories=("${temp_array[@]}")
}

prompt_compress_format() {
    while true;do
        print "Choose from following formats: (tar, zip, rar):"
        read format
        log "$format"
        if [ "$format" != "tar" ] && [ "$format" != "zip" ] &&
            [ "$format" != "rar" ]; then
                print_error "Invalid format"
        else
            backupFormat="$format"
            return;
        fi
    done
}

execute_backup() {
    # Check if compress format is installed
    if ! command -v $1 > /dev/null 2>&1; then
        print "Installing $1 package..."
        sudo apt-get update > /dev/null 2>&1
        sudo apt-get install $1 > /dev/null 2>&1
    fi

    local backup_date="$(date +%F__%H:%M:%S)"

    destination="backups/$backup_date"
    if [ ! -e "backups" ]; then
        mkdir "backups"
    fi

    mkdir "backups/$backup_date"

    # Backup execution based on format
    case $1 in
        "tar") backupFormat="tar.gz";tar -czf "$destination/backup.tar.gz" "${directories[@]}" > /dev/null 2>&1;;
        "zip") zip -r "$destination/backup.$1" "${directories[@]}" > /dev/null 2>&1;;
        "rar") rar a "$destination/backup.$1" "${directories[@]}" > /dev/null 2>&1;;
        *) print_error "Format not exists!!";;
    esac
}

############################# Directory Management ############################
add_directories() {
    print "Enter directories to backup (separated by spaces): "
    read dirs
    log "$dirs"
    for dir in $dirs; do
        if [ -e "$dir" ] && [ -d "$dir" ]; then
            if is_directory_in_list "$dir"; then
                print_error "$dir already exists!!"
            else
                directories+=("$dir")
                print_success "$dir added."
            fi
        else
            print_error "$dir not exists!!"
        fi
    done
}

remove_directories() {
    if [ ${#directories[@]} == 0 ]; then
        print_error "No directories to exclude!!"
        return
    fi
    print "Enter directories to remove (separated by spaces): "
    read dirs
    log $dirs
    for to_remove_dir in $dirs; do
        if is_directory_in_list "$to_remove_dir"; then
            remove_directory "$to_remove_dir"
            print_success "$to_remove_dir removed."
        else
            print_error "$to_remove_dir not exists!!"
        fi
    done
}

############################### Backup Function ###############################
backup() {
    if [ ${#directories[@]} = 0 ]; then
        print_error "Can't make empty backup!!"
        return
    fi
    log "Continue with default compress format? [Y/n] "
    read -p "Continue with default compress format? [Y/n] " defaultFormat
    log "$defaultFormat"
    if [ "$defaultFormat" = "n" ]; then
        prompt_compress_format
    fi

    local startTime=$(date +%s)

    execute_backup $backupFormat

    local endTime=$(date +%s)

    local duration=$((endTime - startTime))

    # Display backup details
    print "Backup File..."

    print "$(du -h "${directories[@]}")"
    print "Total size: $(du -sh "$destination/backup.$backupFormat" | cut -f1)"

    print "Backup Duration: $duration seconds"
    print_success "Backup completed successfully.\n"

    create_logger_file 
    backupFinish=1
}

################################ Main Function ################################
print_state() {
    print ""
    print "Current directories : [${directories[*]}]"
    print "Please select action (add, del, exe):"
}

determine_action() {
    read action
    log "$action"
    case $action in
        "add") add_directories;;
        "del") remove_directories;;
        "exe") backup;;
        *) print_error "Invalid action"
    esac
}

main() {
    while [ $backupFinish == 0 ]; do
        print_state
        determine_action
    done
}

#Execution
main