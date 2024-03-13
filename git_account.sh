#!/bin/bash

# Adds a new Git account with the given profile name, name, email, and optional GitHub user.
#
# Parameters:
# - $1: The profile name for the new account.
# - $2: The name for the new account.
# - $3: The email for the new account.
# - $4: The GitHub user for the new account (optional).
add_account() {
    local profile_name="$1"
    mkdir -p "${PROFILE_DIR}"

    local profile="${PROFILE_DIR}/${profile_name}"
    # Create directory for the account if it doesn't exist, and fail if it already exists
    mkdir "${profile}" || (echo "ERROR: Account [${profile_name}] already exists" && exit 1)

    # Generate SSH key for the new account
    ssh-keygen -t ed25519 -C "${3}" -f "${profile}/${profile_name}_key" -N ""

    # Print the SSH public key to add to the Git server
    echo "Public key for [${profile_name}]:"
    cat "${profile}/${profile_name}_key.pub"

    git config --file="${profile}/.gitconfig" --add user.name "${2}"
    git config --file="${profile}/.gitconfig" --add user.email "${3}"

    if [ -n "${4}" ]; then
        git config --file="${profile}/.gitconfig" --add github.user "${4}"
    fi
    git config --file="${profile}/.gitconfig" --add core.sshCommand "ssh -i ${profile}/${profile_name}_key"

    activate_account "${profile_name}"
}

#Lists all available accounts in the PROFILE_DIR directory.
#
#This function checks if the PROFILE_DIR directory exists and is a directory. If it is,
#it iterates over each file in the directory and prints the name of each directory.
#If the PROFILE_DIR directory does not exist or is not a directory, it prints "No accounts found."
list_accounts() {
    if [ -d "${PROFILE_DIR}" ]; then
        echo "Available accounts:"
        for profile in "${PROFILE_DIR}"/*; do
            if [ -d "${profile}" ]; then
                echo "  - $(basename "${profile}")"
            fi
        done
    else
        echo "No accounts found."
    fi
}

# Activates a Git account by setting the global include.path to the specified profile's .gitconfig file.
#
# Parameters:
# - $1: The name of the profile to activate.
activate_account() {
    local profile_name="$1"
    if [ -f "${PROFILE_DIR}/${profile_name}/.gitconfig" ]; then
        git config --global --replace-all "include.path" "${PROFILE_DIR}/${profile_name}/.gitconfig"
        echo "Account [${profile_name}] has been activated."
    else
        echo "ERROR: profile [${profile_name}] does not exist"
    fi
}

# Removes a Git account by backing up the account-specific directory and removing it.
#
# Parameters:
# - $1: The name of the profile to remove.
remove_account() {
    local profile_name="$1"
    local profile="${PROFILE_DIR}/${profile_name}"
    local backup_dir="${BACKUP_DIR}/$(date +"%Y-%m-%d")"

    # Backup account-specific directory
    mkdir -p "${backup_dir}"
    tar -czf "${backup_dir}/$(date +"%H-%M-%S")_${profile}.tar.gz" -C "${profile}" .

    # Remove account-specific directory
    rm -rf "${profile}"

    echo "Account [${profile_name}] has been removed and unconfigured."

    # Check if the include.path is set to the desired value
    if [ "$(git config --get include.path)" == *"/${profile_name}/"*]; then
        git config --unset-all include.path
        echo "Account [${profile_name}] has been deactivated, you must activate a new one."
    fi
}

git_account() {
    if [ -z "${GIT_PROFILE_DIR}" ]; then
        echo "ERROR: GIT_PROFILE_DIR not defined"
        return 1
    fi
    case "${2}" in
        "add")
            if [ $# -eq 6 ]; then
                add_account "${3}" "${4}" "${5}" "${6}"
            else
                echo "Invalid number of parameters."
                echo "Usage: git account add <profile> <name> <email> <github_user>"
            fi
            ;;
        "activate")
            if [ $# -eq 3 ]; then
                activate_account "${3}"
            else
                echo "Invalid number of parameters."
                echo "Usage: git account activate <profile>"
            fi
            ;;
        "list")
            list_accounts
            ;;
        "remove")
            if [ $# -eq 3 ]; then
                remove_account "${3}"
            else
                echo "Invalid number of parameters."
                echo "Usage: git account remove <profile>"
            fi
            ;;
        *)
            echo "Usage:"
            echo "    git account add <profile> <name> <email> <github_user>"
            echo "    git account activate <profile>"
            echo "    git account list"
            echo "    git account remove <profile>"
            ;;
    esac
}
