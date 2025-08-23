#!/bin/sh
#####################################################
# TERMINAL MESSAGES

line_break() {
	echo "${C_Status}#${C_Reset}"
}
export -f line_break

line_break_debug() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		echo "${C_Status}#${C_Reset}"
	fi
}
export -f line_break_debug

heading() {
	msg="$1"
	color="${2:-${C_Status}}"
	char="${3:-=}"
	length=${#msg}                                  # Get the length of the string
	hashes=$(printf "${char}%.0s" $(seq 1 $length)) # Generate a string of '#' of the same length
	echo "${C_Status}#${char}${char}${char}${color}${hashes}${C_Reset}"
	line_break
	echo "${C_Status}#${C_Reset}   ${color}${msg}"
	# echo "${C_Status}#${char}${char}${char}${color}${hashes}${C_Reset}"
	line_break
}
export -f heading

section_title() {
	msg="$1"
	color="${2:-${C_Status}}"
	length=${#msg}                            # Get the length of the string
	hashes=$(printf '_%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
	echo "${C_Status}#   ${color}  ${C_Reset}${msg}"
	echo "${C_Status}#   ${color}  ${hashes}${C_Reset}"
	line_break
}
export -f section_title

debug_title() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		msg="$1"
		color="${2:-${C_Status}}"
		length=${#msg}                            # Get the length of the string
		hashes=$(printf '_%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
		echo "${C_Status}#${C_Reset}   ${C_Reset}${msg}"
		echo "${C_Status}#${C_Reset}   ${color}${hashes}${C_Reset}"
		line_break
	fi
}
export -f debug_title

running_msg() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		msg="$1"
		color="${2:-${C_Reset}}"
		length=${#msg}                            # Get the length of the string
		hashes=$(printf '>%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
		echo "${C_Status}#${C_Reset}   ${C_Reset}${msg}${C_Reset}"
		echo "${C_Status}#${C_Reset}   ${color}${hashes}${C_Reset}"
		line_break
	fi
}
export -f running_msg

file_msg() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		msg="$1"
		color="${2:-${C_Yellow}}"
		length=${#msg}                            # Get the length of the string
		hashes=$(printf '~%.0s' $(seq 1 $length)) # Generate a string of '#' of the same length
		echo "${C_Status}#${C_Reset}   ${color}~~~${hashes}${C_Reset}"
		echo "${C_Status}#${C_Reset}   📄 ${C_Reset}${msg}"
		echo "${C_Status}#${C_Reset}   ${color}~~~${hashes}${C_Reset}"
		line_break
	fi
}
export -f file_msg

changed_to_dir_msg() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		msg="$1"
		color="${2:-${C_Cyan}}"
		char="${3:->}"
		line_break
		length=${#msg}                                  # Get the length of the string
		hashes=$(printf "${char}%.0s" $(seq 1 $length)) # Generate a string of '#' of the same length
		echo "${C_Status}#${C_Reset}   ${color}${hashes}${C_Reset}"
		echo "${C_Status}#${C_Reset}   ${color}Changed to Directory: ${C_Reset}${msg}"
		echo "${C_Status}#${C_Reset}   ${color}${hashes}${C_Reset}"
	fi
}
export -f changed_to_dir_msg

body_msg() {
	msg="$1"
	color="${2:-${C_Reset}}"
	echo "${C_Status}#     ${color}${msg}${C_Reset}"
}
export -f body_msg

status_msg() {
	msg="$1"
	color="${2:-${C_Reset}}"
	echo "${C_Status}#${color}     ${msg}${C_Reset}"
}
export -f status_msg

example_msg() {
	msg="$1"
	color="${2:-${C_Status}}"
	echo "${C_Status}#${color}     | ${C_Reset}${msg}${C_Reset}"
}
export -f example_msg

info_msg() {
	msg="$1"
	color="${2:-${C_Status}}"
	echo "${C_Status}#${color}     | ${C_Reset}${msg}${C_Reset}"
}
export -f info_msg

option_msg() {
	msg="$1"
	color="${2:-${C_BrightBlue}}"
	echo "${C_Status}#${color}     > ${C_Reset}${msg}${C_Reset}"
}
export -f option_msg

option_question() {
	msg="$1"
	color="${2:-${C_Magenta}}"
	char="${3:->}"
	length=${#msg}                                  # Get the length of the string
	hashes=$(printf "${char}%.0s" $(seq 1 $length)) # Generate a string of '#' of the same length
	# echo "${C_Status}#${C_Reset}   ${color}  ${char}${char}${char}${char}${hashes}${C_Reset}"
	echo "${C_Status}#${C_Reset}   ${C_Reset}  ${color}${char}${char}${char} ${C_Reset}${msg}"

}
export -f option_question

input_cursor() {
	msg="$1"
	color="${2:-${C_Magenta}}"
	echo "${C_Status}#${C_Reset}   ${color}  >>>${C_Reset} ${msg}"
}
export -f input_cursor

generating_msg() {
	msg="$1"
	# echo "${C_Status}#${C_Reset}   🤖${C_Cyan} ${msg} ${C_Reset}"
	echo "${C_Status}#${C_Reset}     ✨${C_Cyan} ${msg} ${C_Reset}"
}
export -f generating_msg

removing_msg() {
	msg="$1"
	echo "${C_Status}#${C_Reset}     ❌${C_Red} ${msg} ${C_Reset}"
}
export -f removing_msg

list_item_msg() {
	msg="$1"
	echo "${C_Status}#${C_Yellow}     ●${C_Reset} ${msg} ${C_Reset}"
}
export -f list_item_msg

warning_msg() {
	msg="$1"
	echo "${C_Status}#     ${C_Yellow}> ${msg} ${C_Reset}"
}
export -f warning_msg

cat_msg() {
	file="$1"
	color="${2:-${C_BrightYellow}}"

	if [ ! -f "$file" ]; then
		warning_msg "File '$file' not found."
		return 1
	fi
	body_msg "✏️  Writing contents of '$file':" ${color}
	body_msg "|   " ${color}
	while IFS= read -r line || [ -n "$line" ]; do
		body_msg "|   ${line}" ${color}
	done <"$file"
}
export -f cat_msg

celebrate_msg() {
	msg="$1"
	echo "${C_Status}#${C_Reset}     🎉${C_Green} ${msg} ${C_Reset}"
}
export -f celebrate_msg

success_msg() {
	msg="$1"
	# echo "${C_Status}#${C_Reset}     ✅${C_Green} ${msg} ${C_Reset}"
	echo "${C_Status}#${C_Reset}     ${C_Green}✔︎ ${C_Reset}${msg}"
}
debug_success_msg() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		msg="$1"
		# echo "${C_Status}#${C_Reset}     ✅${C_Green} ${msg} ${C_Reset}"
		echo "${C_Status}#${C_Reset}     ${C_Green}✔︎ < ${C_Reset}${msg}"
	fi
}
export -f debug_success_msg

# EXAMPLE: log_error "Example Error Message" $(basename "$0") $(caller | cut -d' ' -f1)
error_msg() {
	msg="$1"
	echo "${C_Status}#${C_Reset}     🚨 ${C_Red}ERROR: ${msg}"
}
export -f error_msg

error_function_msg() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		echo "${C_Status}#${C_Reset}     🚸 ${C_Yellow}${C_Reset}Function '$1' is already defined!" >&2
	fi
}
export -f error_function_msg

debug_msg() {
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		msg="$1"
		color="${2:-${C_Reset}}"
		echo "${C_Status}#     < ${color}${msg}${C_Reset} >"
	fi
}
export -f debug_msg
