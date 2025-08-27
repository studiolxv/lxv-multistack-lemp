#!/bin/sh
# Check if lemp is running, returns Bool
is_lemp_running() {
    stack_name=${1:-$STACK_NAME}
    source_lemp_stack_env ${stack_name}
    # Check if any LEMP container is running
    if docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" ps | grep -q "Up"; then
        return 0 # True (running)
    else
        return 1 # False (not running)
    fi
}


check_and_create_stack_network() {
    stack_name=${1:-$STACK_NAME}
    # Load stack env (defines LEMP_NETWORK_NAME, LEMP_PATH, etc.)
    source_lemp_stack_env ${stack_name}

    net_name=${LEMP_NETWORK_NAME:-${stack_name}_lemp_network}
    heading "Checking Network: ${net_name}"

    # Ensure Docker is available
    if ! docker info >/dev/null 2>&1; then
        if command -v error_msg >/dev/null 2>&1; then
            error_msg "Docker does not appear to be running. Please start Docker Desktop."
        else
            echo "[ERROR] Docker does not appear to be running. Please start Docker Desktop." >&2
        fi
        return 1
    fi

    # If network exists, we are good
    if docker network inspect "$net_name" >/dev/null 2>&1; then
        # Check ownership label
        owner_label=$(docker network inspect -f '{{ index .Labels "com.docker.compose.project" }}' "$net_name" 2>/dev/null || echo "")
        network_label=$(docker network inspect -f '{{ index .Labels "com.docker.compose.network" }}' "$net_name" 2>/dev/null || echo "")
        if [ -z "$owner_label" ] || [ "$owner_label" != "$stack_name" ] || [ -n "$network_label" ] && [ "$network_label" != "$net_name" ]; then
            # If owner is empty or different, prompt the user (stack is stopped at this point)
            msg_moved="It is possible you moved a LEMP stack or WordPress container into this project."
            if is_lemp_running "$stack_name"; then
                # Extra safety: never modify networks while stack is running
                if command -v warning_msg >/dev/null 2>&1; then
                    if [ -n "$owner_label" ]; then
                        warning_msg "Network '${net_name}' exists but belongs to a different project ('${owner_label}'). ${msg_moved} Since the stack is running, leaving network unchanged."
                    else
                        warning_msg "Network '${net_name}' exists without compose ownership label. ${msg_moved} Since the stack is running, leaving network unchanged."
                    fi
                else
                    if [ -n "$owner_label" ]; then
                        echo "[WARN] Network '${net_name}' exists but belongs to a different project ('${owner_label}'). ${msg_moved} Since the stack is running, leaving network unchanged."
                    else
                        echo "[WARN] Network '${net_name}' exists without compose ownership label. ${msg_moved} Since the stack is running, leaving network unchanged."
                    fi
                fi
                return 0
            fi

            # Interactive choice (default: Recreate)
            if command -v warning_msg >/dev/null 2>&1; then
                if [ -n "$owner_label" ]; then
                    warning_msg "Network '${net_name}' exists but belongs to a different project ('${owner_label}'). ${msg_moved}"
                else
                    warning_msg "Network '${net_name}' exists without compose ownership label. ${msg_moved}"
                fi
                if [ -n "$network_label" ] && [ "$network_label" != "$net_name" ]; then
                    warning_msg "Compose network label mismatch: found 'com.docker.compose.network=${network_label}', expected '${net_name}'."
                fi
                warning_msg "You can recreate it (recommended when moving stacks). The script will then let docker-compose create the network with correct labels. Or keep it (may cause 'not created by this project' errors unless marked external)."
            else
                if [ -n "$owner_label" ]; then
                    echo "[WARN] Network '${net_name}' exists but belongs to a different project ('${owner_label}'). ${msg_moved}"
                else
                    echo "[WARN] Network '${net_name}' exists without compose ownership label. ${msg_moved}"
                fi
                if [ -n "$network_label" ] && [ "$network_label" != "$net_name" ]; then
                    echo "[WARN] Compose network label mismatch: found 'com.docker.compose.network=${network_label}', expected '${net_name}'."
                fi
                echo "[WARN] You can recreate it (recommended when moving stacks). The script will then let docker-compose create the network with correct labels. Or keep it (may cause 'not created by this project' errors unless marked external)."
            fi

            # Allow env override for non-interactive runs
            # FORCE_NETWORK_RECREATE=true  -> auto recreate
            # KEEP_MISMATCHED_NETWORK=true -> auto keep
            choice=""
            if [ "${FORCE_NETWORK_RECREATE:-}" = "true" ]; then
                choice="r"
                elif [ "${KEEP_MISMATCHED_NETWORK:-}" = "true" ]; then
                choice="k"
            fi

            if [ -z "$choice" ]; then
                printf "Do you want to [R]ecreate the network or [K]eep it as-is? [R/k]: "
                IFS= read -r choice
            fi
            case "$choice" in
                ''|R|r)
                    _log_run docker network rm "$net_name"
                    docker network rm "$net_name" >/dev/null 2>&1 || true
                ;;
                K|k)
                    if command -v status_msg >/dev/null 2>&1; then
                        status_msg "Keeping existing network '${net_name}' with mismatched/empty labels. Note: Compose may refuse to attach this project to it."
                    else
                        echo "[INFO] Keeping existing network '${net_name}' with mismatched/empty labels. Note: Compose may refuse to attach this project to it."
                    fi
                    return 0
                ;;
                *)
                    # Treat unrecognized input as default (Recreate)
                    _log_run docker network rm "$net_name"
                    docker network rm "$net_name" >/dev/null 2>&1 || true
                ;;
            esac
        else
            if command -v status_msg >/dev/null 2>&1; then
                status_msg "Network '${net_name}' already exists."
            else
                echo "[INFO] Network '${net_name}' already exists."
            fi
            return 0
        fi
    fi

    # Defer network creation to docker-compose unless explicitly forced
    if [ "${FORCE_PRECREATE_NETWORK:-}" = "true" ]; then
        if command -v running_msg >/dev/null 2>&1; then
            running_msg "% docker network create --driver bridge ${net_name}"
        else
            echo "% docker network create --driver bridge ${net_name}"
        fi
        if docker network create --driver bridge "$net_name" >/dev/null 2>&1; then
            if command -v success_msg >/dev/null 2>&1; then
                success_msg "Docker network '${net_name}' created (pre-created by script)."
            else
                echo "[OK] Docker network '${net_name}' created (pre-created by script)."
            fi
            return 0
        else
            if command -v error_msg >/dev/null 2>&1; then
                error_msg "Failed to create docker network '${net_name}'."
            else
                echo "[ERROR] Failed to create docker network '${net_name}'." >&2
            fi
            return 1
        fi
    fi

    # Default path: do not create here. Let docker-compose create it with proper labels.
    if command -v status_msg >/dev/null 2>&1; then
        status_msg "Letting docker-compose create '${net_name}' so ownership labels are correct."
    else
        echo "[INFO] Letting docker-compose create '${net_name}' so ownership labels are correct."
    fi
    return 0
}


start_lemp() {
    stack_name=${1:-$STACK_NAME}
    # Contains some overrides to default vars if exists
    source_lemp_stack_env ${stack_name}

    # Check if LEMP services are running
    if ! is_lemp_running ${stack_name}; then
        heading "Starting LEMP services..."
        # Command to Start docker container
        if check_and_create_stack_network; then
            running_msg "% docker-compose -f ${stack_name}/docker-compose.yml up -d"
            line_break
            if command -v status_msg >/dev/null 2>&1; then
                status_msg "Starting stack; docker-compose will (re)create '${LEMP_NETWORK_NAME:-${STACK_NAME}_lemp_network}' with proper labels."
            fi
            docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" up -d
        else
            error_msg "❌ Cannot start LEMP stack. Docker Network issue."
            line_break
            exit 1
        fi

        # Wait for the services to start
        # write a function that loops until the services are up
        # docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" ps | grep 'Up' >/dev/null

        ######## START WAIT
        timeout=${2:-60} # Default timeout of 60 seconds
        start_time=$(date +%s)
        while :; do
            # Check if all services are up
            if ! docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" ps | grep 'Up' >/dev/null; then
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                if [ "$elapsed_time" -ge "$timeout" ]; then
                    status_msg "Timeout reached. Not all services are up."
                    exit 1
                fi
                # Services are not up yet; wait and retry
                sleep 2
            else
                line_break
                if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
                    success_msg "LEMP services are now up and running."
                fi
                lemp_started_message
                line_break
                # Now running lemp-entrypoint.sh
                break
            fi
        done
        ####### END WAIT
    else
        echo -e "${C_Status}#   ✅ LEMP services are already running.${C_Reset}"
        lemp_started_message
    fi
}


restart_lemp() {
    stack_name=${1:-$STACK_NAME}
    if is_lemp_running ${stack_name}; then
        status_msg "🔄 Restarting LEMP..."
        line_break
        docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" down
        docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" up -d
        echo -e "${C_Status}#   ✅ ✅ LEMP restarted successfully!"
    else
        status_msg "⚠️ LEMP is not running. Starting now..."
        line_break
        docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" up -d
        echo -e "${C_Status}#   ✅ LEMP started successfully!"
    fi
}

stop_lemp() {
    stack_name=${1:-$STACK_NAME}
    if is_lemp_running ${stack_name}; then
        running_msg "Stopping LEMP services..."
        line_break
        running_msg "% docker-compose -f ${LEMP_DIR}/docker-compose.yml down"
        docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" down

        success_msg "LEMP container stopped."
        line_break
    else
        warning_msg "LEMP services are not currently running. Skipping shutdown."
        line_break
    fi
}


lemp_started_message() {
    STACK_NAME=${1:-$STACK_NAME}
    STACK_NAME_UC=$(uc_word "$STACK_NAME")
    source_lemp_stack_env ${STACK_NAME}
    line_break
    status_msg "- Container Name: ${C_Status}${LEMP_CONTAINER_NAME}"
    status_msg "- Host Files Path: ${C_Status}${LEMP_PATH}"
    line_break
    status_msg "- Server: ${C_Status}${C_Underline}https://${LEMP_SERVER_DOMAIN}"
    status_msg "- Shared PhpMyAdmin: ${C_Status}${C_Underline}https://phpmyadmin.${LEMP_SERVER_DOMAIN}"
    line_break
    status_msg "🖥️  Now opening your default browser to the WordPress site and phpMyAdmin..."
    line_break

    sleep 2
    # Open the default browser to the WordPress site and phpMyAdmin
	open_link "https://${LEMP_SERVER_DOMAIN}"
    open_link "https://phpmyadmin.${LEMP_SERVER_DOMAIN}"

	if [ -f "${LEMP_PATH}/secrets/db_root_user.txt" ] && [ -f "${LEMP_PATH}/secrets/db_root_user_password.txt" ]; then
	    DB_USER=$(cat "${LEMP_PATH}/secrets/db_root_user.txt")
	    DB_PASS=$(cat "${LEMP_PATH}/secrets/db_root_user_password.txt")
	    show_popup "NEW LEMP STACK: ${STACK_NAME_UC}" "Copy and paste the user and password to log into phpMyAdmin with the following credentials\n\nUser: $DB_USER\nPassword: $DB_PASS"
fi
}



lemp_host_file_trusted_cert_message(){
    # Detect OS and hosts file path using existing helpers
    os_type=$(detect_os 2>/dev/null)
    hosts_file=$(detect_os_hosts_file 2>/dev/null)
    : "${hosts_file:=/etc/hosts}"

    # Extra hint for WSL (Linux kernel but Windows host)
    is_wsl=false
    if [ "$os_type" = "linux" ] && [ -r /proc/version ]; then
        case "$(cat /proc/version 2>/dev/null)" in
            *Microsoft*|*microsoft*) is_wsl=true ;;
        esac
    fi

    case "$os_type" in
        macos)
            warning_msg "ATTENTION: macOS users — if your browser is not showing you phpMyAdmin login or the php info on the main domain the You may need to trust the new ${LEMP_SERVER_DOMAIN} certificate in Keychain Access (KeychainAccess.app) the first time."
            warning_msg "Also, double-check these domains were added to your ${hosts_file} file."
        ;;
        linux)
            if [ "$is_wsl" = true ]; then
                warning_msg "ATTENTION: WSL users — mkcert installs a Linux trust store. Windows browsers may still rely on the Windows trust store. If you browse via Windows, import the certificate in certmgr.msc as well."
            else
                warning_msg "ATTENTION: Linux users — Ensure the new ${LEMP_SERVER_DOMAIN} certificate is trusted. If using mkcert, 'mkcert -install' adds the local CA to the system trust store."
                warning_msg "For Firefox/NSS, make sure 'certutil' (libnss3-tools / nss-tools) is installed so mkcert can update the NSS store."
            fi
            warning_msg "Also, double-check these domains were added to your ${hosts_file} file."
        ;;
        freebsd|openbsd)
            warning_msg "ATTENTION: BSD users — Ensure the new ${LEMP_SERVER_DOMAIN} certificate is trusted (e.g., 'certctl rehash' on FreeBSD)."
            warning_msg "Also, double-check these domains were added to your ${hosts_file} file."
        ;;
        solaris)
            warning_msg "ATTENTION: Solaris users — Ensure the new ${LEMP_SERVER_DOMAIN} certificate is trusted in your system's certificate store."
            warning_msg "Also, double-check these domains were added to your ${hosts_file} file."
        ;;
        windows)
            warning_msg "ATTENTION: Windows users — You may need to trust the new ${LEMP_SERVER_DOMAIN} certificate in Certificate Manager (certmgr.msc) under 'Trusted Root Certification Authorities'."
            warning_msg "Also, double-check these domains were added to your C:\\Windows\\System32\\drivers\\etc\\hosts file."
        ;;
        *)
            warning_msg "ATTENTION: Your OS couldn't be detected. Please ensure ${LEMP_SERVER_DOMAIN} is trusted in your system certificate store."
            warning_msg "Also, double-check these domains were added to your ${hosts_file} file."
        ;;
    esac
}

