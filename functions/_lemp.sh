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
export -f is_lemp_running

start_lemp() {
	stack_name=${1:-$STACK_NAME}
	# Contains some overrides to default vars if exists
	source_lemp_stack_env ${stack_name}

	# Check if LEMP services are running
	if ! is_lemp_running ${stack_name}; then
		heading "Starting LEMP services..."
		line_break
		# Command to Start docker container
		if check_and_create_network; then
			running_msg "% docker-compose -f ${stack_name}/docker-compose.yml up -d"
			line_break
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
		local timeout=${2:-60} # Default timeout of 60 seconds
		local start_time=$(date +%s)
		while true; do
			# Check if all services are up
			if ! docker-compose -f "${LEMP_DOCKER_COMPOSE_YML}" ps | grep 'Up' >/dev/null; then
				local current_time=$(date +%s)
				local elapsed_time=$((current_time - start_time))
				if [[ $elapsed_time -ge $timeout ]]; then
					status_msg "Timeout reached. Not all services are up."
					exit 1
				fi
				# Services are not up yet; wait and retry
				sleep 2
			else
				line_break
				if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
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
export -f start_lemp

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
export -f stop_lemp

lemp_started_message() {
	stack_name=${1:-$STACK_NAME}
	source_lemp_stack_env ${stack_name}
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
	open_link "https://phpmyadmin.${LEMP_SERVER_DOMAIN}"
	open_link "https://${LEMP_SERVER_DOMAIN}"
}
export -f lemp_started_message


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
            warning_msg "ATTENTION: macOS users — You may need to trust the new ${LEMP_SERVER_DOMAIN} certificate in Keychain Access (KeychainAccess.app) the first time."
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
export -f lemp_host_file_trusted_cert_message
