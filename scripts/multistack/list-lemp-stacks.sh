#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

section_title "Listing Active LEMP Stacks"
line_break

# Loop through stacks
for stack in ../stacks/*; do
	[[ -d "$stack" ]] || continue
	STACK_NAME=$(basename "$stack")
	ENV_FILE="$stack/.env"

	if [[ -f "$ENV_FILE" ]]; then
		source "$ENV_FILE"
		status_msg "LEMP Stack: ${STACK_NAME}"
		echo "  - Primary Domain: ${LEMP_SERVER_DOMAIN_NAME}"
		echo "  - Network: ${LEMP_NETWORK_NAME}"

		# Check for WordPress containers
		for wp in "$stack/containers/"*; do
			[[ -d "$wp" ]] || continue
			WP_NAME=$(basename "$wp")
			WP_ENV="$wp/.env"

			if [[ -f "$WP_ENV" ]]; then
				source "$WP_ENV"
				echo "  - WordPress Site: ${WORDPRESS_DOMAIN_NAME}"
			fi
		done

		echo ""
	fi
done
