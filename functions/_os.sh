#!/bin/sh

detect_os() {
	# Get OS type using uname
	os_name=$(uname -s 2>/dev/null)

	case "$os_name" in
	Linux)
		# Check for specific Linux distributions
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			echo "$ID" # Return OS ID (e.g., "ubuntu", "debian", "centos", "arch")
			return
		elif [ -f /etc/redhat-release ]; then
			echo "rhel"
			return
		elif [ -f /etc/debian_version ]; then
			echo "debian"
			return
		else
			echo "linux" # Fallback for unknown Linux distros
			return
		fi
		;;
	Darwin)
		echo "macos"
		return
		;;
	FreeBSD)
		echo "freebsd"
		return
		;;
	OpenBSD)
		echo "openbsd"
		return
		;;
	SunOS)
		echo "solaris"
		return
		;;
	CYGWIN* | MINGW* | MSYS*)
		echo "windows"
		return
		;;
	*)
		echo "unknown"
		return 1
		;;
	esac
}
export -f detect_os

detect_os_name() {
	OS_ID=$(detect_os) # Get OS type

	case "$OS_ID" in
	ubuntu | debian | raspbian)
		awk -F= '/^PRETTY_NAME/ { print $2 }' /etc/os-release | tr -d '"'
		;;
	centos | rhel | fedora | rocky | alma)
		cat /etc/redhat-release 2>/dev/null || awk -F= '/^PRETTY_NAME/ { print $2 }' /etc/os-release | tr -d '"'
		;;
	arch)
		awk -F= '/^PRETTY_NAME/ { print $2 }' /etc/os-release | tr -d '"'
		;;
	macos)
		echo "$(sw_vers -productName) $(sw_vers -productVersion) $(sw_vers -buildVersion)"
		;;
	freebsd | openbsd)
		uname -sr
		;;
	solaris)
		cat /etc/release | head -n 1
		;;
	windows)
		systeminfo | awk -F: '/OS Name/ {print $2}' | sed 's/^ *//'
		;;
	*)
		echo "Unknown OS"
		;;
	esac
}
export -f detect_os_name

#####################################################
# OPERATING SYSTEM HOST FILE

detect_os_hosts_file() {

	OS_ID=$(detect_os) # Get OS type
	case "${OS_ID}" in
	macos|macOS|linux|ubuntu|debian|raspbian|centos|rhel|fedora|rocky|alma|arch|freebsd|openbsd|solaris)
		echo "/etc/hosts"
		return
		;;
	windows)
		echo "/c/Windows/System32/drivers/etc/hosts"
		return
		;;
	*)
		return 1
		;;
	esac
}
export -f detect_os_hosts_file

get_local_loopback_ip() {
	# Always emit a value; default to 127.0.0.1
	default="127.0.0.1"

	# Detect OS inline to avoid relying on external globals
	_os=$(detect_os 2>/dev/null)

	case "$_os" in
		macos)
			ip=$(ifconfig lo0 2>/dev/null | awk '/inet[[:space:]]/ {print $2; exit}')
			;;
		linux)
			ip=$(ip -4 addr show lo 2>/dev/null | awk '/inet[[:space:]]/ {print $2; exit}' | cut -d/ -f1)
			[ -z "$ip" ] && ip=$(/sbin/ip -4 addr show lo 2>/dev/null | awk '/inet[[:space:]]/ {print $2; exit}' | cut -d/ -f1)
			[ -z "$ip" ] && ip=$(hostname -I 2>/dev/null | awk '{print $1; exit}')
			[ -z "$ip" ] && ip=$(getent hosts localhost 2>/dev/null | awk '{print $1; exit}')
			[ -z "$ip" ] && ip=$(awk '/^127\./ {print $1; exit}' /etc/hosts 2>/dev/null)
			;;
		freebsd|openbsd)
			ip=$(ifconfig lo0 2>/dev/null | awk '/inet[[:space:]]/ {print $2; exit}')
			;;
		windows)
			ip="$default"
			;;
		*)
			ip=""
			;;
	esac

	[ -n "$ip" ] && printf '%s\n' "$ip" || printf '%s\n' "$default"
}
export -f get_local_loopback_ip

is_hosts_file_mods_needed() {
	loopback=${1:-${HOSTS_FILE_LOOPBACK_IP}}
	domain=${2:-${LEMP_SERVER_DOMAIN}}

	get_hosts_file=$(detect_os_hosts_file)
	: "${get_hosts_file:=${HOSTS_FILE}}"

	hosts_file=${3:-${get_hosts_file}}

	# Check if already exists in the hosts file
	if grep -Eq "^[[:space:]]*${loopback}[[:space:]]+${domain}([[:space:]]|$)" "$hosts_file"; then
		return 0
	else
		return 1
	fi
}
export -f is_hosts_file_mods_needed

append_to_hosts_file_manually_msg() {

	status_msg "Please manually add these two lines to your os hosts file:"
	example_msg "${C_Yellow}${HOSTS_FILE_LOOPBACK_IP} ${LEMP_SERVER_DOMAIN}"
	example_msg "${C_Yellow}${HOSTS_FILE_LOOPBACK_IP} phpmyadmin.${LEMP_SERVER_DOMAIN}"
}
export -f append_to_hosts_file_manually_msg

append_to_hosts_file() {

	add_domain=${1:-$LEMP_SERVER_DOMAIN}

	_os_type=$(detect_os)
	os_type="${_os_type:-$OS_NAME}"
	hosts_file=$(detect_os_hosts_file)
	hosts_file="${hosts_file:-$HOSTS_FILE}"
	loopback_ip=$(get_local_loopback_ip)
	loopback_ip="${loopback_ip:-$HOSTS_FILE_LOOPBACK_IP}"

	body_msg "Using hosts file: $hosts_file"
	body_msg "Using loopback IP: $loopback_ip"
	line_break

	if [ -z "$os_type" ]; then
		error_msg "${C_Red}\$os_type is not set!"
	fi

	if [ -z "$hosts_file" ]; then
		error_msg "${C_Red}\$hosts_file is not set!"
	fi

	if [ -z "$loopback_ip" ]; then
		error_msg "${C_Red}\$loopback_ip is not set!"
	fi

	# Add the domain to the hosts file if needed
	if echo "$add_domain" | grep -q "localhost"; then
		status_msg "${C_Yellow}NOTE${C_Reset}:"
		status_msg "Modifications to the hosts file are not necessary for .localhost domains."
		status_msg "✨ ${C_Reset}$add_domain will automatically resolve to ${loopback_ip} on most systems."
	else
		# Check if already exists in the hosts file
		if grep -Eq "^[[:space:]]*${loopback_ip}[[:space:]]+${add_domain}([[:space:]]|$)" "$hosts_file"; then
			# ALREADY EXISTS
			success_msg "'${C_Yellow}$add_domain${C_Reset}' ${C_Green}already exists in '$hosts_file'. Good to go!"
			return

		else
			# NEEDS TO BE ADDED EXISTS
			warning_msg "'$add_domain' not found in '$hosts_file'.${C_Reset} Adding it now..."

			generating_msg "🪄 ${C_Reset} Now adding $add_domain to $hosts_file for local development..."
			line_break

			# Append entry to the hosts file
			case "$os_type" in
			macos | freebsd | openbsd | solaris | linux | ubuntu | debian | raspbian | centos | rhel | fedora | rocky | alma | arch)

				# Check if the user is running as sudo
				status_msg "${C_Yellow}${C_Underline}NOTE${C_Reset}: sudo user needed to modify /etc/hosts file..."
				line_break
				sudo sh -c "echo '${loopback_ip} ${add_domain}' >> '$hosts_file'"
				;;
			windows)
				if command -v sudo >/dev/null 2>&1; then
					echo "${loopback_ip} ${add_domain}" | sudo tee -a "$hosts_file" >/dev/null
				else
					echo "${loopback_ip} ${add_domain}" >> "$hosts_file" 2>/dev/null || {
						error_msg "Need elevated shell to write to $hosts_file on Windows. Run your shell as Administrator."
						append_to_hosts_file_manually_msg
						return 1
					}
				fi
				;;
			*)
				error_msg "Unsupported OS for hosts file modification"
				append_to_hosts_file_manually_msg
				return 1
				;;
			esac

			# Confirm addition
			if grep -Eq "^[[:space:]]*${loopback_ip}[[:space:]]+${add_domain}([[:space:]]|$)" "$hosts_file"; then
				line_break
				success_msg "$add_domain has been added to $hosts_file."
			else
				line_break
				error_msg "Failed to add $add_domain to $hosts_file."
				append_to_hosts_file_manually_msg
			fi

		fi

	fi
	return
}
export -f append_to_hosts_file
