#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# % BREW MKCERT CA & SSL CERTIFICATES

heading "CERTIFICATE AUTHORITY: MKCERT"

#####################################################
# CHECK & INSTALL MKCERT IF MISSING

if ! command -v mkcert >/dev/null 2>&1; then
	status_msg "mkcert is not installed. Attempting to install..."

	case "$(uname -s)" in
		Darwin)
			line_break
			section_title "MACOS detected"
			if command -v brew >/dev/null 2>&1; then
				status_msg "Installing mkcert via Homebrew..."
				brew install mkcert
				success_msg "mkcert installed successfully."
			else
				status_msg "Homebrew is not installed. Would you like to install it now? (y/n) "
				line_break
				read -p "$(input_cursor)" INSTALL_BREW_Q
				if [ "$INSTALL_BREW_Q" = "y" ] || [ "$INSTALL_BREW_Q" = "Y" ]; then
					status_msg "Installing Homebrew now..."

					# Install Homebrew
					/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

					# Ensure Homebrew is in the PATH (macOS Intel & Apple Silicon support)
					if [ -d "/opt/homebrew/bin" ]; then
						eval "$(/opt/homebrew/bin/brew shellenv)"
					elif [ -d "/usr/local/bin" ]; then
						eval "$(/usr/local/bin/brew shellenv)"
					fi

					success_msg "Homebrew installed successfully."
				else
					status_msg "MKCERT is required, and Homebrew is needed to install mkcert."
					warning_msg "Please install both manually to continue gracefully."
				fi
			fi
			;;
		Linux)
			line_break
			section_title "LINUX detected"
			if command -v apt >/dev/null 2>&1; then
				status_msg "Installing mkcert via apt..."
				sudo apt update && sudo apt install -y libnss3-tools mkcert
				success_msg "mkcert installed successfully."
			elif command -v dnf >/dev/null 2>&1; then
				status_msg "Installing mkcert via dnf..."
				sudo dnf install -y mkcert
				success_msg "mkcert installed successfully."
			elif command -v pacman >/dev/null 2>&1; then
				status_msg "Installing mkcert via pacman..."
				sudo pacman -Sy --noconfirm mkcert
				success_msg "mkcert installed successfully."
			else
				status_msg "No supported package manager found. Please install mkcert manually."
			fi
			if ! command -v certutil >/dev/null 2>&1; then
				warning_msg "certutil not found. mkcert may not be able to add certificates to the NSS trust store (e.g., Firefox). Please install manually."
			fi
			;;
		MINGW*|MSYS*|CYGWIN*)
		    line_break
		    section_title "WINDOWS POSIX detected"
		    line_break
		    status_msg "Detected Windows POSIX environment (Git Bash/MSYS)."

		    if ! command -v choco >/dev/null 2>&1 && ! command -v scoop >/dev/null 2>&1; then
		        status_msg "To continue the automated setup process, mkcert is required."
		        warning_msg "We recommend installing Chocolatey or Scoop package managers to simplify the installation process."

		        options="Chocolatey|Scoop|Quit"

		        # Display options
		        section_title "WINDOWS PACKAGE MANAGERS" ${C_Magenta}
		        i=1
		        OLD_IFS=$IFS; IFS='|' # Set delimiter for correct iteration
		        for option in $options; do
		            option_msg "$i. $option" ${C_Magenta}
		            i=$((i + 1))
		        done
		        IFS=$OLD_IFS
		        line_break
		        option_question "Which package manager would you like to install?"
		        line_break

		        # Read selection
		        while true; do
		            printf "%s " "$(input_cursor)"
		            read choice || { log_error "Input cancelled."; exit 1; }
		            # count options
		            total_options=$(printf '%s' "$options" | tr '|' '\n' | wc -l | tr -d '[:space:]')
		            case "$choice" in
		                *[!0-9]*|'') log_error "Invalid choice, please enter a number."; continue ;;
		                *) if [ "$choice" -lt 1 ] || [ "$choice" -gt "$total_options" ]; then
		                       log_error "Invalid choice, please try again."
		                       continue
		                   fi ;;
		            esac
		            selected_option=$(printf '%s' "$options" | tr '|' '\n' | sed -n "${choice}p")
		            input_cursor "Selected: ${C_Magenta}'$selected_option'${C_Reset}"
		            break
		        done

		        case "$selected_option" in
		            "Chocolatey")
		                status_msg "Installing Chocolatey..."
		                set -x
		                powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
		                  "Set-ExecutionPolicy Bypass -Scope Process -Force; \
		                   [Net.ServicePointManager]::SecurityProtocol = \
		                   [Net.ServicePointManager]::SecurityProtocol -bor 3072; \
		                   iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
		                set +x
		                success_msg "Chocolatey installed. Please close and re-run this script."
		                exit 0
		                ;;
		            "Scoop")
		                status_msg "Installing Scoop..."
		                set -x
		                powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \
		                  "iwr -useb get.scoop.sh | iex"
		                set +x
		                success_msg "Scoop installed. Please close and re-run this script."
		                exit 0
		                ;;
		            "Quit")
		                exit 0
		                ;;
		        esac
		    fi

		    if command -v choco >/dev/null 2>&1; then
		        status_msg "Installing mkcert via Chocolatey..."
		        choco install -y mkcert
		        success_msg "mkcert installed successfully via Chocolatey."
		    elif command -v scoop >/dev/null 2>&1; then
		        status_msg "Installing mkcert via Scoop..."
		        scoop install mkcert
		        success_msg "mkcert installed successfully via Scoop."
		    else
		        status_msg "Please install mkcert manually:"
		        status_msg " - With Chocolatey:   choco install mkcert"
		        status_msg " - With Scoop:        scoop install mkcert"
		        status_msg " - Or download mkcert.exe from: https://github.com/FiloSottile/mkcert/releases"
		    fi
		    ;;
		WSL*)
		    status_msg "Detected Windows Subsystem for Linux."
		    status_msg "Use your Linux package manager (apt/dnf/pacman) to install mkcert."
		    ;;
		*)
			status_msg "Unsupported OS. Please install mkcert manually."
			;;
	esac
fi

# INSTALL MKCERT LOCAL CA IF NEEDED
if command -v mkcert >/dev/null 2>&1; then
	success_msg "mkcert is already installed. Installing local CA..."
	line_break

	# mkcert -install
	add_mkcert_ca_root_to_trust

	success_msg "mkcert local CA is installed."
	line_break
else
	error_msg "Something went wrong and mkcert is not installed, please install mkcert manually and try again."
	exit 0
fi
