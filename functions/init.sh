#!/bin/sh
#####################################################
# CLI OPTIONS
: "${opt_debug:=false}"      ; export opt_debug # Enable/disable debug mode for multistack
: "${opt_debug_file_msg:=false}"   ; export opt_debug_file_msg # Enable/disable logs files sourced/used in runtime
: "${opt_line_breaks:=true}"        ; export opt_line_breaks # [true|false] for line breaks between messages
: "${opt_dividers:=true}"           ; export opt_dividers # [true|false] for line dividers between cli output
: "${opt_indent:=true}"             ; export opt_indent # [true|false] for indentation
: "${opt_left_wall:=true}"          ; export opt_left_wall # [true|false] for left wall "#"
: "${opt_wall_char:=#}"             ; export opt_wall_char # character to use for left wall
: "${opt_heading_char:=#}"          ; export opt_heading_char # character to use for left heading
: "${opt_open_docker_on_start:=true}" ; export opt_open_docker_on_start # [true|false] for opening Docker on start
: "${opt_sort:=time_asc}" ; export opt_sort # [alpha_asc|alpha_desc|time_asc|time_desc] stacks/containers sort order

if [ -n "$opt_indent" ] && [ "$opt_indent" = "true" ]; then
	export indent_one="   "
	export indent_two="    "
	export indent_three="     "
else
	export indent_one=""
	export indent_two=""
    export indent_three=""
fi
if [ -n "$opt_left_wall" ] && [ "$opt_left_wall" = "true" ]; then
    export opt_wall="${opt_wall_char}"
else
    export opt_wall=""
fi

#####################################################
# TERMINAL COLORS
export C_Reset=$(tput sgr0)
export C_Bold=$(tput bold)
export C_Underline=$(tput smul)
export C_Black=$(tput setaf 0)
export C_Red=$(tput setaf 1)
export C_Green=$(tput setaf 2)
export C_Yellow=$(tput setaf 3)
export C_Blue=$(tput setaf 4)
export C_Magenta=$(tput setaf 5)
export C_Cyan=$(tput setaf 6)
export C_White=$(tput setaf 7)
export C_BrightBlack=$(tput setaf 8)
export C_BrightRed=$(tput setaf 9)
export C_BrightGreen=$(tput setaf 10)
export C_BrightYellow=$(tput setaf 11)
export C_BrightBlue=$(tput setaf 12)
export C_BrightMagenta=$(tput setaf 13)
export C_BrightCyan=$(tput setaf 14)
export C_BrightWhite=$(tput setaf 15)
export C_Status="${C_BrightBlue}"

#####################################################
# HEADER
lxv_header() {
	 if [ -f "${PROJECT_ENV_FILE}" ] && [ ! "${INSTALLATION_COMPLETE}" = true ]; then
		line_break
		heading "WELCOME TO..."
	 fi
    typewriter "${indent_one}Y888P     Y8b Y8P  Y8bY  Y88Y " 0.5
    printf "\n"
    typewriter "${indent_one} 888        Y8P     Y8b  8P   " 1.5
    printf "\n"
    typewriter "${indent_one} 888  ,d    d8b      Y8.8Y    " 2.5
    printf "\n"
    typewriter "${indent_one} 888,d88  d8b Y8b     Y8P     " 3.5
    printf "\n"
    line_break
    typewriter "${indent_one}M U L T I S T A C K  L E M P" 9
    printf "\n"
	 if [ -f "${PROJECT_ENV_FILE}" ] && [ ! "${INSTALLATION_COMPLETE}" = true ]; then
		line_break
	    typewriter "${indent_one}👾 by Christopher Sample" 9
		printf "\n"
	    typewriter "${indent_one}🛸 http://github.com/studiolxv" 13
		printf "\n"
	fi
}


update_env_var() {
    # Write/replace variable in .env
    sleep 1
    ENV_FILE="$PROJECT_ENV_FILE"
    key="$1"
    val="${2:-true}"

    if [ -z "$key" ]; then
        warning_msg "No environment variable name provided to update_env_var()"
        return 1
    fi

    # Ensure the file exists or can be created
    if { [ -e "$ENV_FILE" ] && [ -w "$ENV_FILE" ]; } || { [ ! -e "$ENV_FILE" ] && touch "$ENV_FILE" >/dev/null 2>&1; }; then
        # Only update if the exact key=value pair is not already present
        if ! grep -q "^${key}=${val}$" "$ENV_FILE" 2>/dev/null; then
            # Remove any existing definitions for this key, then append the new value
            sed -i '' "/^${key}=/d" "$ENV_FILE"
            printf '%s=%s\n' "$key" "$val" >> "$ENV_FILE"
        fi
        success_msg "\"$key\" set to \"$val\" in ${ENV_FILE}"
    else
        warning_msg "${ENV_FILE} file not writable or missing... Please restart installation or update it manually."
        return 1
    fi
}

get_env_variable_value() {
	local var_name="$1"
	local file_name="${2:-$LEMP_ENV_FILE}"
	if [ -f "${file_name}" ]; then
		local var_value
		# Extract the value, remove surrounding quotes if they exist
		var_value=$(grep -E "^${var_name}=" "${file_name}" | cut -d '=' -f2- | sed -e 's/^"//' -e 's/"$//')
		if [ -n "${var_value}" ]; then
			echo "${var_value}"
		else
			return 1 # Indicate failure
		fi
	else
		return 1 # Indicate failure
	fi
}

rm_project_root_env() {
    local ENV_FILE="$PROJECT_ENV_FILE"
    if [ -f "$ENV_FILE" ]; then
        rm -f "$ENV_FILE"
        success_msg "Removed root environment file: $ENV_FILE"
    else
        warning_msg "Root environment file not found: $ENV_FILE"
    fi
}

make_scripts_executable() {
	# Ensure SCRIPTS_PATH is set
	if [ -z "$SCRIPTS_PATH" ]; then
		echo "❌ Error: SCRIPTS_PATH is not set."
		return 1
	fi

	# Ensure the directory exists
	if [ ! -d "$SCRIPTS_PATH" ]; then
		echo "❌ Error: Directory '$SCRIPTS_PATH' does not exist."
		return 1
	fi

	# Debugging: Show the directory being checked
	# echo "🔍 Checking scripts in: $SCRIPTS_PATH"

	# Loop through each script file in the directory
	find "$SCRIPTS_PATH" -type f | while IFS= read -r script; do
		# Check if the file is NOT already executable
		if [ ! -x "$script" ]; then
			echo "🔄 Changing permissions for: $script"
			chmod +x "$script" || echo "❌ Failed to modify: $script"
			ls -l "$script" # Verify permissions after change
		fi
	done
}


load_helper_functions() {

    # Ensure FUNCTION_PATH is valid
    if [ ! -d "$FUNCTIONS_PATH" ]; then
        echo "❌ Error: FUNCTIONS_PATH is not set cannot source functions!" >&2
        exit 1
    else
        if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
            debug_msg "✅ FUNCTIONS_PATH is set and functions can be sourced from:"
            debug_msg "↳$FUNCTIONS_PATH"
        fi

    fi

    # Ensure functions directory exists
    if [ -d "$FUNCTIONS_PATH/helpers" ]; then
        # Source each function file in the current shell
        for file in $(find "$FUNCTIONS_PATH/helpers" -type f -name "*.sh"); do
            if [ -f "$file" ]; then
            	debug_msg "📦 sourcing function file: $file"
                source "$file"
                # wait ensures any background processes (if applicable) complete first
                wait
            fi
        done
    else
        echo "❌ Error: Directory '$FUNCTIONS_PATH/helpers' does not exist." >&2
    fi
}


typewriter() {
    # Expand backslash escapes (e.g., \033) into real bytes first
    text=$(printf '%b' "$1")
    delay_ms=${2:-1}

    # Convert ms -> seconds with 3 decimal precision
    delay_s=$(awk -v ms="$delay_ms" 'BEGIN{printf "%.3f", ms/1000}')

    i=1
    len=${#text}
    printf '%s' "${C_Status}${opt_wall}"
    while [ $i -le $len ]; do
        ch=${text:$((i-1)):1}

        # If we hit ESC (start of ANSI sequence), consume the sequence and print atomically
        if [ "$ch" = $'\033' ]; then
            seq=$'\033'
            i=$((i+1))
            while [ $i -le $len ]; do
                c=${text:$((i-1)):1}
                seq="$seq$c"
                i=$((i+1))
                # Most SGR color sequences end with 'm'; print when reached
                [ "$c" = "m" ] && break
            done
            printf '%s' "$seq"
            continue
        fi

        # Normal printable char: animate with delay
        printf '%s' "$ch"
        sleep "$delay_s"
        i=$((i+1))
    done
}


#####################################################
# GET PATHS
# Returns the path of the *current* script/source file.
current_file() {
  # bash: BASH_SOURCE[0] is the file being executed/sourced
  if [ -n "${BASH_SOURCE-}" ]; then
    printf '%s\n' "${BASH_SOURCE[0]}"
    return
  fi

  # zsh: use $funcfiletrace for sourced files
  if [ -n "${ZSH_VERSION-}" ]; then
    # if available, first entry is "path:line:function"
    if [ -n "${funcfiletrace+x}" ] && [ -n "${funcfiletrace[1]-}" ]; then
      printf '%s\n' "${funcfiletrace[1]%:*}"
    else
      printf '%s\n' "$0"
    fi
    return
  fi

  # ksh93: ${.sh.file} holds the current file
  # (guard with '2>/dev/null' so dash/ash don't error)
  if [ -n "${.sh.file-}" ] 2>/dev/null; then
    printf '%s\n' "${.sh.file}"
    return
  fi

  # dash/ash/other POSIX: best we have is $0
  printf '%s\n' "$0"
}

# Convenience: just the file name
current_basename() {
  bn="$(basename "$(current_file)")"
  printf '%s\n' "$bn"
}
#####################################################
# TERMINAL MESSAGES

line_break() {
if [ -n "$opt_line_breaks" ] && [ "$opt_line_breaks" = "true" ]; then
    echo "${C_Status}${opt_wall}${C_Reset}"
fi
}


line_break_debug() {
	if [ -n "$opt_line_breaks" ] && [ "$opt_line_breaks" = "true" ]; then
	    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
	        echo "${C_Status}${opt_wall}${C_Reset}"
	    fi
	fi
}


heading() {
    msg="$1"
    color="${2:-${C_Status}}"
    char="${3:-${opt_heading_char}}"
    length=${#msg}                                  # Get the length of the string
    hashes=$(printf "${char}%.0s" $(seq 1 $length)) # Generate a string of '#' of the same length
	if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
	    echo "${C_Status}${opt_wall}${char}${char}${char}${color}${hashes}${C_Reset}"
	fi
    line_break
    echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}${msg}"
    # echo "${C_Status}${opt_wall}${char}${char}${char}${color}${hashes}${C_Reset}"
    line_break
}


section_title() {
    msg="$1"
    color="${2:-${C_Status}}"
    length=${#msg}                            # Get the length of the string
    hashes=$(printf '_%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
    echo "${C_Status}${opt_wall}${indent_three}${color}${C_Reset}${msg}"
	if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
	    echo "${C_Status}${opt_wall}${indent_three}${color}${hashes}${C_Reset}"
	fi
    line_break
}

body_msg() {
    msg="$1"
    color="${2:-${C_Reset}}"
    echo "${C_Status}${opt_wall}${indent_three}${color}${msg}${C_Reset}"
}

status_msg() {
    msg="$1"
    color="${2:-${C_Reset}}"
    echo "${C_Status}${opt_wall}${color}${indent_three}${msg}${C_Reset}"
}

example_msg() {
    msg="$1"
    color="${2:-${C_Status}}"
    echo "${C_Status}${opt_wall}${color}${indent_three}| ${C_Reset}${msg}${C_Reset}"
}

info_msg() {
    msg="$1"
    color="${2:-${C_Status}}"
    echo "${C_Status}${opt_wall}${color}${indent_three}| ${C_Reset}${msg}${C_Reset}"
}

option_msg() {
    msg="$1"
    color="${2:-${C_BrightBlue}}"
    echo "${C_Status}${opt_wall}${color}${indent_three}> ${C_Reset}${msg}${C_Reset}"
}

option_question() {
    msg="$1"
    color="${2:-${C_Magenta}}"
    char="${3:->}"
    length=${#msg}                                  # Get the length of the string
    hashes=$(printf "${char}%.0s" $(seq 1 $length)) # Generate a string of '#' of the same length
    # echo "${C_Status}${opt_wall}${C_Reset}   ${color}  ${char}${char}${char}${char}${hashes}${C_Reset}"
    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}${C_Reset}${color}${char}${char}${char} ${C_Reset}${msg}"
}

input_cursor() {
    msg="$1"
    color="${2:-${C_Magenta}}"
    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}${color}>>>${C_Reset} ${msg}"
}

generating_msg() {
    msg="$1"
    # echo "${C_Status}${opt_wall}${C_Reset}   🤖${C_Status} ${msg} ${C_Reset}"
    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}✨${C_Status} ${msg} ${C_Reset}"
}

removing_msg() {
    msg="$1"
    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}❌${C_Red} ${msg} ${C_Reset}"
}

list_item_msg() {
    msg="$1"
    echo "${C_Status}${opt_wall}${C_Yellow}${indent_three}●${C_Reset} ${msg} ${C_Reset}"
}


warning_msg() {
    msg="$1"
    echo "${C_Status}${opt_wall}${indent_three}🚧 ${C_Yellow}> ${msg} ${C_Reset}"
}

cat_msg() {
    file="$1"
    color="${2:-${C_BrightYellow}}"

    if [ ! -f "$file" ]; then
        warning_msg "File '$file' not found."
        return 1
    fi
    body_msg "✏️  Writing contents of '$file':" ${color}
    body_msg "|${indent_one}" ${color}
    while IFS= read -r line || [ -n "$line" ]; do
        body_msg "|${indent_one}${line}" ${color}
    done <"$file"
}

celebrate_msg() {
    msg="$1"
    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}🎉${C_Green} ${msg} ${C_Reset}"
}

success_msg() {
    msg="$1"
    # echo "${C_Status}${opt_wall}${C_Reset}${indent_three}✅${C_Green} ${msg} ${C_Reset}"
    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}${C_Green}✔︎ ${C_Reset}${msg}"
}

#############################################
# DEBUG
debug_title() {
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
        msg="$1"
        color="${2:-${C_Status}}"
        length=${#msg}                            # Get the length of the string
        hashes=$(printf '_%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
        echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${C_Reset}${msg}"
		if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
			echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}${hashes}${C_Reset}"
		fi
        line_break
    fi
}

debug_msg() {
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
        msg="$1"
        color="${2:-${C_Reset}}"
        echo "${C_Status}${opt_wall}${indent_three}< ${color}${msg} ${C_Status}>${C_Reset}"
    fi
}


running_msg() {
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
        msg="$1"
        color="${2:-${C_Reset}}"
        length=${#msg}                            # Get the length of the string
        hashes=$(printf '>%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
        echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${C_Reset}${msg}${C_Reset}"
		if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
			echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}${hashes}${C_Reset}"
		fi
        line_break
    fi
}


debug_file_msg() {
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ] && [ "$opt_debug_file_msg" = "true" ]; then
        msg="$1"
        color="${2:-${C_Yellow}}"
        length=${#msg}                            # Get the length of the string
        hashes=$(printf '~%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
		if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
			echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}~~~${hashes}${C_Reset}"
		fi
		echo "${C_Status}${opt_wall}${C_Reset}${indent_one}📄 ${C_Reset}${msg}"
		if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
			echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}~~~${hashes}${C_Reset}"
		fi
        line_break
    fi
}


changed_to_dir_msg() {
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
        msg="$1"
        color="${2:-${C_Status}}"
        char="${3:->}"
        line_break
        length=${#msg}                                  # Get the length of the string
        hashes=$(printf "${char}%.0s" $(seq 1 $length)) # Generate a string of '#' of the same length
		if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
	        echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}${hashes}${C_Reset}"
		fi
        echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}Changed to Directory: ${C_Reset}${msg}"
		if [ -n "$opt_dividers" ] && [ "$opt_dividers" = "true" ]; then
	        echo "${C_Status}${opt_wall}${C_Reset}${indent_one}${color}${hashes}${C_Reset}"
		fi
    fi
}

wait_msg() {
	printf '%s' "${C_Status}${opt_wall}${C_Reset}${indent_three}⏳ ${C_Yellow}${1}${C_Reset}"
}
debug_success_msg() {
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
        msg="$1"
        echo "${C_Status}${opt_wall}${C_Reset}${indent_three}${C_Green}✔︎ < ${C_Reset}${msg} ${C_Green}>${C_Reset}"
    fi
}

debug_error_msg() {
	if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
	    msg="$1"
	    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}🚨 ${C_Red}ERROR: ${msg}"
	fi
}

error_msg() {
    msg="$1"
    echo "${C_Status}${opt_wall}${C_Reset}${indent_three}🚨 ${C_Red}ERROR: ${msg}"
}

error_function_msg() {
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
        echo "${C_Status}${opt_wall}${C_Reset}${indent_three}🚸 ${C_Yellow}${C_Reset}Function '$1' is already defined!" >&2
    fi
}

# Helper: log + exit on fatal
_die(){ warning_msg "❌ $*"; exit 1; }
