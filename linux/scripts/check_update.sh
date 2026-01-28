#!/bin/bash

# Script to detect Linux distribution, check for available updates, and optionally install them
# Displays updates in a formatted table
# Supports Oracle Linux, Rocky Linux, Ubuntu, and Debian

# Uncomment the next line for debugging
# set -x

# Color Definitions (Optional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file (Optional)
LOG_FILE="/var/log/update_script.log"
# Ensure the log file exists and is writable
touch "$LOG_FILE" 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Cannot write to log file: $LOG_FILE${NC}"
    LOG_FILE="/dev/null" # Fallback to no logging
fi
exec > >(tee -a "$LOG_FILE") 2>&1

# Function to print error messages
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to prompt the user for a yes/no response
prompt_yes_no() {
    # $1: Prompt message
    while true; do
        read -rp "$1 (y/n): " yn
        case "$yn" in
            [Yy]* ) return 0 ;;
            [Nn]* ) return 1 ;;
            * ) echo "Please answer yes (y) or no (n)." ;;
        esac
    done
}

# Function to detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        # Source the os-release file to get distribution information
        . /etc/os-release
        DISTRO_ID=$ID
        DISTRO_NAME=$NAME
        DISTRO_VERSION=$VERSION_ID
    else
        error "/etc/os-release not found. Cannot determine Linux distribution."
    fi
}

# Function to determine if sudo is needed
determine_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        SUDO='sudo'
    else
        SUDO=''
    fi
}

# Function to check for updates on Debian-based systems
check_debian_updates() {
    echo -e "${BLUE}Updating package lists for $DISTRO_NAME $DISTRO_VERSION...${NC}"
    $SUDO apt update -y
    if [ $? -ne 0 ]; then
        error "Failed to update package lists using apt."
    fi

    echo -e "${BLUE}Checking for available updates...${NC}"
    # Fetch upgradable packages
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." )

    if [ -z "$UPGRADABLE" ]; then
        echo -e "${GREEN}All packages are up to date.${NC}"
        return 1
    else
        echo ""
        echo -e "${YELLOW}Available Updates:${NC}"
        printf "${BLUE}%-40s %-25s %-25s${NC}\n" "Package" "Current Version" "Available Version"
        printf "${BLUE}%-40s %-25s %-25s${NC}\n" "-------" "---------------" "----------------"

        # Iterate through each upgradable package and display in table
        echo "$UPGRADABLE" | while read -r line; do
            # Example line: cloud-init/noble-updates 24.2-0ubuntu1~24.04.3 amd64 [upgradable from: 24.2-0ubuntu1~24.04.2]
            # Extract PACKAGE, AVAILABLE_VERSION, CURRENT_VERSION
            PACKAGE=$(echo "$line" | awk -F'/' '{print $1}')
            AVAILABLE_VERSION=$(echo "$line" | awk '{print $2}')
            CURRENT_VERSION=$(echo "$line" | grep -oP '(?<=\[upgradable from: ).*(?=\])')

            # Handle cases where parsing fails
            if [ -z "$CURRENT_VERSION" ]; then
                CURRENT_VERSION="Unknown"
            fi

            printf "${GREEN}%-40s${NC} %-25s %-25s\n" "$PACKAGE" "$CURRENT_VERSION" "$AVAILABLE_VERSION"
        done
        return 0
    fi
}

# Function to check for updates on RHEL-based systems (Oracle Linux, Rocky Linux)
check_rhel_updates() {
    # Determine whether to use dnf or yum
    if command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    else
        error "Neither dnf nor yum package manager found."
    fi

    echo -e "${BLUE}Checking for available updates using $PKG_MANAGER...${NC}"

    if [ "$PKG_MANAGER" == "dnf" ]; then
        # Use dnf check-update to get list of upgradable packages
        UPDATE_OUTPUT=$($SUDO dnf check-update)
        CHECK_STATUS=$?
    else
        # Use yum check-update to get list of upgradable packages
        UPDATE_OUTPUT=$($SUDO yum check-update)
        CHECK_STATUS=$?
    fi

    # Interpret dnf/yum exit codes
    # Exit Code 0: No updates
    # Exit Code 100: Updates available
    # Exit Code 1: Error

    if [ "$PKG_MANAGER" == "dnf" ]; then
        if [ $CHECK_STATUS -eq 0 ]; then
            echo -e "${GREEN}All packages are up to date.${NC}"
            return 1
        elif [ $CHECK_STATUS -eq 100 ]; then
            :
        else
            error "An error occurred while checking for updates using dnf."
        fi
    elif [ "$PKG_MANAGER" == "yum" ]; then
        if [ $CHECK_STATUS -eq 0 ]; then
            echo -e "${GREEN}All packages are up to date.${NC}"
            return 1
        elif [ $CHECK_STATUS -eq 100 ]; then
            :
        else
            error "An error occurred while checking for updates using yum."
        fi
    fi

    echo ""
    echo -e "${YELLOW}Available Updates:${NC}"
    printf "${BLUE}%-30s %-25s %-25s${NC}\n" "Package" "Current Version" "Available Version"
    printf "${BLUE}%-30s %-25s %-25s${NC}\n" "-------" "---------------" "----------------"

    # Parse the dnf/yum check-update output
    echo "$UPDATE_OUTPUT" | grep -v "^$" | grep -v "^Obsoleting Packages" | while read -r line; do
        # Example line: bash.x86_64        5.1.0-2.el9        updates
        PACKAGE_FULL=$(echo "$line" | awk '{print $1}')
        AVAILABLE_VERSION=$(echo "$line" | awk '{print $2}')
        PACKAGE=$(echo "$PACKAGE_FULL" | cut -d'.' -f1)

        # Get current installed version using rpm
        CURRENT_VERSION=$(rpm -q --qf "%{VERSION}-%{RELEASE}" "$PACKAGE" 2>/dev/null)

        # Handle cases where rpm cannot find the package
        if [ -z "$CURRENT_VERSION" ]; then
            CURRENT_VERSION="Unknown"
        fi

        printf "${GREEN}%-30s${NC} %-25s %-25s\n" "$PACKAGE" "$CURRENT_VERSION" "$AVAILABLE_VERSION"
    done
    return 0
}

# Function to install updates on Debian-based systems
install_debian_updates() {
    echo -e "${BLUE}Installing updates using apt...${NC}"
    $SUDO apt upgrade -y
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Updates installed successfully.${NC}"
    else
        error "Failed to install updates using apt."
    fi
}

# Function to install updates on RHEL-based systems
install_rhel_updates() {
    echo -e "${BLUE}Installing updates using $PKG_MANAGER...${NC}"
    if [ "$PKG_MANAGER" == "dnf" ]; then
        $SUDO dnf upgrade -y
    else
        $SUDO yum update -y
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Updates installed successfully.${NC}"
    else
        error "Failed to install updates using $PKG_MANAGER."
    fi
}

# Main script execution starts here

# Determine if sudo is needed
determine_sudo

detect_distro

echo -e "${GREEN}Detected Linux Distribution: $DISTRO_NAME $DISTRO_VERSION${NC}"
echo "------------------------------------------------------------"

# Prompt the user to check for updates
if prompt_yes_no "Do you want to check for available updates?"; then
    case "$DISTRO_ID" in
        ubuntu|debian)
            check_debian_updates
            UPDATE_AVAILABLE=$?
            ;;
        ol|oracle|rocky)
            check_rhel_updates
            UPDATE_AVAILABLE=$?
            ;;
        *)
            # Fallback based on ID_LIKE if ID is not directly matched
            if [[ "$ID_LIKE" == *"debian"* ]]; then
                check_debian_updates
                UPDATE_AVAILABLE=$?
            elif [[ "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
                check_rhel_updates
                UPDATE_AVAILABLE=$?
            else
                error "Unsupported Linux distribution: $DISTRO_NAME"
            fi
            ;;
    esac

    # If updates are available, prompt to install
    if [ "$UPDATE_AVAILABLE" -eq 0 ]; then
        if prompt_yes_no "Do you want to install the available updates?"; then
            case "$DISTRO_ID" in
                ubuntu|debian)
                    install_debian_updates
                    ;;
                ol|oracle|rocky)
                    install_rhel_updates
                    ;;
                *)
                    # Fallback based on ID_LIKE if ID is not directly matched
                    if [[ "$ID_LIKE" == *"debian"* ]]; then
                        install_debian_updates
                    elif [[ "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
                        install_rhel_updates
                    else
                        error "Unsupported Linux distribution: $DISTRO_NAME"
                    fi
                    ;;
            esac
        else
            echo -e "${YELLOW}Update installation declined by user. Exiting.${NC}"
            exit 0
        fi
    else
        # No updates available
        exit 0
    fi
else
    echo -e "${YELLOW}Update check declined by user. Exiting.${NC}"
    exit 0
fi

exit 0
