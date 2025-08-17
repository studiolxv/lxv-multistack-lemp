#!/bin/sh

#####################################################
# DOCKER IMAGES

# Fetch the latest minor versions of all major versions for a given Docker repository & optional tag filter
fetch_latest_minor_versions() {
	REPO="$1"
	TAG_FILTER="${2:-.*}" # Default to '.*' (match everything) if no filter is provided

	# Fetch image tags from Docker Hub API
	curl -s "https://registry.hub.docker.com/v2/repositories/library/${REPO}/tags?page_size=100" |
		jq -r '.results[].name' |
		grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$' |
		grep -E "${TAG_FILTER}" |
		sort -V | awk -F. '!seen[$1"."$2]++' # Keep only the latest minor version of each major version
}
export -f fetch_latest_minor_versions

fetch_all_latest_minor_versions() {
	REPO="$1"
	TAG_FILTER="${2:-.*}" # Default to '.*' (match everything if no filter is provided)
	PAGE=1
	IMAGES=""

	while :; do
		RESPONSE=$(curl -s "https://registry.hub.docker.com/v2/repositories/library/${REPO}/tags?page_size=100&page=${PAGE}")

		# Ensure valid JSON response
		if ! echo "$RESPONSE" | jq empty 2>/dev/null; then
			# error_msg "Error: Invalid JSON response from Docker Hub for $REPO"
			return 1
		fi

		# Extract tags and apply filter
		# TAGS=$(echo "$RESPONSE" | jq -r '.results[].name' | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?$')
		TAGS=$(echo "$RESPONSE" | grep -o '"name":"[^"]*"' | awk -F'"' '{print $4}' | grep -E '^[0-9]+\.[0-9]+|latest')

		# Apply additional filtering if TAG_FILTER is provided
		if [ -n "$TAG_FILTER" ] && [ "$TAG_FILTER" != ".*" ]; then
			TAGS=$(echo "$TAGS" | grep -E "$TAG_FILTER")
		fi

		# If no tags were found, break (end of pages)
		if [ -z "$TAGS" ]; then
			break
		fi

		# Append tags to images list
		IMAGES="$IMAGES\n$TAGS"

		# Check if there's another page
		if ! echo "$RESPONSE" | grep -q '"next":null'; then
			PAGE=$((PAGE + 1))
		else
			break
		fi
	done


	# Process the list:
	# 1. Sort numerically in descending order
	# 2. Keep only the latest minor version per major version
	echo "$IMAGES" | sort -Vr | awk -F. '!seen[$1"."$2]++'
}
export -f fetch_all_latest_minor_versions

# Generic function to fetch Docker images, optionally filtering by a tag pattern
fetch_all_docker_images() {
	REPO="$1"
	TAG_FILTER="${2:-.*}" # Default to '.*' (match everything) if no filter is provided
	PAGE=1
	IMAGES=""

	while :; do
		RESPONSE=$(curl -s "https://hub.docker.com/v2/repositories/library/${REPO}/tags/?page_size=100&page=${PAGE}")

		# Debug: Print the raw response to check for issues
		# echo "API Response: $RESPONSE" >&2 # Remove this once fixed

		# Ensure valid JSON before processing
		if ! echo "$RESPONSE" | jq empty 2>/dev/null; then
			# error_msg "Error: Invalid JSON response from Docker Hub."
			exit 1
		fi

		# Extract tags from response
		TAGS=$(echo "$RESPONSE" | jq -r '.results[].name' | grep -E "${TAG_FILTER}")

		# If no tags were found, break (end of pages)
		if [ -z "$TAGS" ]; then
			break
		fi

		# Append tags to images list
		IMAGES="$IMAGES\n$TAGS"

		# Check if there's another page
		if ! echo "$RESPONSE" | grep -q '"next":null'; then
			PAGE=$((PAGE + 1))
		else
			break
		fi
	done

	# Return sorted unique versions
	echo "$IMAGES" | sort -Vr | uniq
}
export -f fetch_all_docker_images

#####################################################
# OPEN DOCKER DESKTOP macOS

start_docker_desktop() {
	# Check if Docker is running
	if ! docker info >/dev/null 2>&1; then
		body_msg "🐳 Docker Desktop is not running. Starting it now..."
		# Start Docker Desktop application
		open -a "Docker"

		# Wait for Docker to be fully started
		while ! docker info >/dev/null 2>&1; do
			body_msg "⏳ Waiting for Docker to start..."
			sleep 3
		done

		log_success "🐳 Docker Desktop is now running!"
	else
		body_msg "🐳 Docker Desktop is already running!"
	fi
}
export -f start_docker_desktop

is_docker_compose_running() {
	docker_compose_yml_file=${1}
	# Check if any LEMP container is running
	if docker-compose -f "${docker_compose_yml_file}" ps | grep -q "Up"; then
		return 0 # True (running)
	else
		return 1 # False (not running)
	fi
}
export -f is_docker_compose_running

# Wait until a container is healthy (or at least running if no healthcheck)
# Example: wait_for_container_ready "some-container-name" 120 3
wait_for_container_ready() {
    cn=$1
    timeout=${2:-180}
    interval=${3:-2}
    elapsed=0

    while :; do
        health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cn" 2>/dev/null)
        running=$(docker inspect --format='{{.State.Running}}' "$cn" 2>/dev/null)

        if [ "$health" = "healthy" ] || { [ "$health" = "none" ] && [ "$running" = "true" ]; }; then
            return 0
        fi

        if [ "$elapsed" -ge "$timeout" ]; then
            return 1
        fi

        status_msg "Waiting for container '$cn' to be healthy/running... (${elapsed}s/${timeout}s)"
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done
}
export -f wait_for_container_ready