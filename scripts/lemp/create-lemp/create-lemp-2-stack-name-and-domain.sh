#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# LEMP STACK NAME & SERVER DOMAIN NAME
# Generates Random Default Domain Name
export LEMP_SERVER_DOMAIN_NAME_DEFAULT="$(shuf -n1 /usr/share/dict/words | tr '[:upper:]' '[:lower:]')-$(shuf -n1 /usr/share/dict/words | tr '[:upper:]' '[:lower:]')"
export LEMP_SERVER_DOMAIN_TLD_DEFAULT="test"

section_title "LEMP STACK NAME & LEMP DOMAIN NAME"

example_msg "EXAMPLE"
example_msg
example_msg "This example is using a ${C_Cyan}random word${C_Reset} generator to create a unique LEMP stack name and server domain name."
example_msg
example_msg "Random word: ${C_Cyan}${C_Underline}${LEMP_SERVER_DOMAIN_NAME_DEFAULT}${C_Reset}"
example_msg
example_msg "${C_Cyan}${C_Underline}\$LEMP_DIR: ${C_Reset}Names the directory in which the LEMP Stack files are located"
example_msg
example_msg "- ${STACKS_PATH}/${C_Cyan}${C_Underline}${LEMP_SERVER_DOMAIN_NAME_DEFAULT}${C_Reset}"
example_msg
example_msg "${C_Cyan}${C_Underline}\$LEMP_SERVER_DOMAIN_NAME: ${C_Reset}Names the local development domain (separate from the nested WordPress domains)"
example_msg
example_msg "- https://${C_Cyan}${C_Underline}${LEMP_SERVER_DOMAIN_NAME_DEFAULT}${C_Reset}.${LEMP_SERVER_DOMAIN_TLD_DEFAULT}"
line_break
warning_msg "NOTE: Do not add a period '.' or full TLD (ie. '.test', '.localhost')"
warning_msg "You will be prompted for this local development domain's top-level domain (TLD) in the next prompt."
warning_msg "leave blank to use the random word: ${C_Cyan}${C_Underline}${LEMP_SERVER_DOMAIN_NAME_DEFAULT}${C_Reset}"
line_break
section_title "ENTER NAME" ${C_Magenta}
option_question "Enter one name for both ${C_Magenta}${C_Underline}\$LEMP_DIR${C_Reset} & ${C_Magenta}${C_Underline}\$LEMP_SERVER_DOMAIN_NAME${C_Reset}:"
printf "%s" "$(input_cursor)"
read USER_INPUT_LEMP_SERVER_DOMAIN_NAME

if [ -z "$USER_INPUT_LEMP_SERVER_DOMAIN_NAME" ]; then
	# Default to "$LEMP_SERVER_DOMAIN_NAME_DEFAULT" if no input is provided
	input_cursor "🚨 No name provided. Using \"${C_Magenta}${C_Underline}${LEMP_SERVER_DOMAIN_NAME_DEFAULT}${C_Reset}\""
	export LEMP_SERVER_DOMAIN_NAME="${LEMP_SERVER_DOMAIN_NAME_DEFAULT}"
else
	input_cursor "Entered name: \"${C_Magenta}${C_Underline}${LEMP_SERVER_DOMAIN_NAME_DEFAULT}${C_Reset}\""
	export LEMP_SERVER_DOMAIN_NAME="${USER_INPUT_LEMP_SERVER_DOMAIN_NAME}"
fi

#####################################################
# USER INPUT: LEMP_SERVER_DOMAIN_TLD

# Prompt user to specify the preferred TLD for the site domain
line_break
section_title "LEMP DOMAIN TOP LEVEL DOMAIN (TLD)"
status_msg "Choose your local development Top-Level Domain (TLD), (e.g., \"localhost\")"
line_break

example_msg "${C_Cyan}EXAMPLE"
example_msg
example_msg "${C_Cyan}This example is using the input above${C_Reset}"
example_msg
example_msg "${C_Cyan}\$LEMP_SERVER_DOMAIN_TLD: ${C_Reset}Names the local development domain's top-level domain (TLD)"
example_msg
example_msg "- https://${LEMP_SERVER_DOMAIN_NAME}.${C_Cyan}${C_Underline}${LEMP_SERVER_DOMAIN_TLD_DEFAULT}${C_Reset}"
example_msg
line_break
warning_msg "NOTE: Do not add a period '.' only TLD (ie. 'test', 'localhost') "
warning_msg "If you enter \"localhost\" it automatically resolve to ${C_Underline}${HOSTS_FILE_LOOPBACK_IP}${C_Reset}${C_Yellow} without additional configuration on most system's host file."
warning_msg "Enter anything other than \"localhost\" such as \"${LEMP_SERVER_DOMAIN_TLD_DEFAULT}\" and we will attempt to make modifications to your hosts file automatically for your custom TLD."
warning_msg "leave this blank and hit enter to use default TLD: '${LEMP_SERVER_DOMAIN_TLD_DEFAULT}'"
line_break
section_title "ENTER TLD" ${C_Magenta}
option_question "Enter your preferred local development TLD, without the '.':"
printf "%s" "$(input_cursor)"
read USER_INPUT_LEMP_SERVER_DOMAIN_TLD


# If $USER_INPUT_LEMP_SERVER_DOMAIN_TLD is empty
if [ -z "$USER_INPUT_LEMP_SERVER_DOMAIN_TLD" ]; then
	input_cursor "🚨 No Top-Level Domain (TLD) provided. Using \"${C_Magenta}${C_Underline}${LEMP_SERVER_DOMAIN_TLD_DEFAULT}${C_Reset}\""
	export LEMP_SERVER_DOMAIN_TLD="${LEMP_SERVER_DOMAIN_TLD_DEFAULT}"
else
	input_cursor "Entered TLD: \"${C_Magenta}${C_Underline}${LEMP_SERVER_DOMAIN_TLD_DEFAULT}${C_Reset}\""
	export LEMP_SERVER_DOMAIN_TLD="${USER_INPUT_LEMP_SERVER_DOMAIN_TLD}"
fi
line_break

#####################################################
# FULL LEMP SERVER DOMAIN
# Construct the full site domain
export LEMP_SERVER_DOMAIN="${LEMP_SERVER_DOMAIN_NAME}.${LEMP_SERVER_DOMAIN_TLD}"

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-3-environment-lemp.sh"
