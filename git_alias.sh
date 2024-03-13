#!/bin/bash
case "$1" in
    --help|help)
        sed "s/various situations:/&\n\nmanage multiple git accounts\n   account   Enter git account manager mode /g" <<<$(git --help) 
        exit 0
        ;;
    account)
        # Check if the configuration file exists and source it
        if [ -z "${PROFILE_DIR}" ]; then
            source "$(dirname "$0")/.env"
            if [ -z "${PROFILE_DIR}" ]; then
                echo "[.git_alias] Profile directory not found. Exiting."
                exit 1
            fi
        fi
        echo "[.git_alias] Account management mode."
        source "$(dirname "$0")/git_account.sh" && git_account "$@" 
        exit 0
        ;;
    # Commands that need network configuration
    clone|fetch|pull|push|remote|archive|submodule) 
        # Retrieve the current default IP gateway address
        gateway_ip=$(route print 0.0.0.0 | awk '/0.0.0.0/ {print $5, $4}' | sort -n | head -n 1 | awk '{print $2}')

        if [ -s ~/.ssh/config ]; then
            # Retrieve the configured IP gateway address from .ssh/config
            configured_gateway_ip=$(awk '/Gateway:/ {sub(/^ *# *Gateway: */, "", $0); gsub(/^[ \t]+|[ \t]+$/, "", $0); print $0; exit}' ~/.ssh/config)
        else
            configured_gateway_ip=""
        fi
        
        # If the current IP gateway matches the configured one, exit with success
        if [ "$gateway_ip" = "$configured_gateway_ip" ]; then
            echo "[.git_alias] IP gateway $gateway_ip is still valid. Skipping configuration."
        else
            echo "[.git_alias] Current IP gateway address: $gateway_ip"
            # Check if the configuration file exists and source it
            if [ -z "${CONFIG_FILE}" ]; then
                . "$(dirname "$0")/.env"
                if [ -z "${CONFIG_FILE}" ] || [ ! -f "${CONFIG_FILE}" ]; then
                    echo "[.git_alias] Configuration file not found. Exiting."
                    echo "[.git_alias]   If you don't wish to use .git_alias, execute [unalias git]"            
                    exit 1
                fi
            fi

            network_comment="# Gateway: $gateway_ip"
            proxy_command=""
           
            # Read configuration file and determine proxy settings
            while IFS='|' read -r ip_gateway proxy_host_and_port || [ -n "$ip_gateway" ]; do
                if [[ $ip_gateway == \#* ]]; then
                    continue
                fi
                if [ "$gateway_ip" = "$ip_gateway" ]; then
                    if [ -n "$proxy_host_and_port" ]; then
                        proxy_host_and_port=$(echo "$proxy_host_and_port" | tr -d '\n\r') # Remove line feed
                        echo "[.git_alias] IP gateway $ip_gateway detected. Using proxy $proxy_host_and_port."
                        proxy_command=$(echo "ProxyCommand $PROXY_CMD" | sed "s/proxy:port/$proxy_host_and_port/")
                        network_comment="# Gateway: $ip_gateway"
                    fi
                    break
                fi
            done < "$CONFIG_FILE"

            if [ -s ~/.ssh/config ]; then
                #Remove gateway comment and proxy command from .ssh/config
                sed -i '/^# Gateway:/d; /^ProxyCommand/d' ~/.ssh/config
                # Backup account-specific directory
                local backup_dir="${BACKUP_DIR}/$(date +"%Y-%m-%d")"
                mkdir -p "${backup_dir}"
                tar -czf "${backup_dir}/$(date +"%H-%M-%S")_ssh_config.tar.gz" -C ~/.ssh config
            else
                #create .ssh/config
                echo "# default configuration file created by .git_alias" > ~/.ssh/config
                echo "Host github.com" >> ~/.ssh/config
                echo "  User git" >> ~/.ssh/config
                echo "  Port 22" >> ~/.ssh/config
                echo "  Hostname github.com" >> ~/.ssh/config
                echo "  TCPKeepAlive yes" >> ~/.ssh/config
                echo "  IdentitiesOnly yes" >> ~/.ssh/config                
            fi

            #add Gateway comment to .ssh/config
            echo "$network_comment" >> ~/.ssh/config
            
            # If proxy settings were determined, add the ProxyCommand in .ssh/config
            if [ -n "$proxy_command" ]; then
                echo " $proxy_command" >> ~/.ssh/config
            else
                echo "[.git_alias] No proxy configured for IP gateway $ip_gateway."                   
            fi
        fi
        ;;    
esac

# Delegate the command to git.
git "$@"