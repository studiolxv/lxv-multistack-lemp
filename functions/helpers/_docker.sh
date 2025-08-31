#!/bin/sh
#####################################################
# DOCKER

macos_launch_docker() {
    open -a "Docker Desktop"
}

is_docker_running_in_bg() {
    # Easiest: try to talk to the daemon
    if docker info >/dev/null 2>&1; then
        debug_success_msg "🐳 Docker is running"
        return 0
    fi
    
    # macOS check: Docker.app process running?
    if [ "$(uname)" = "Darwin" ]; then
        if pgrep -x "Docker" >/dev/null 2>&1; then
            debug_success_msg "🐳 Docker is running"
            return 0
        fi
    fi
    
    # Windows WSL2 check: docker.exe available and responsive?
    if command -v docker.exe >/dev/null 2>&1; then
        if docker.exe info >/dev/null 2>&1; then
            debug_success_msg "🐳 Docker is running"
            return 0
        fi
    fi
    
    # If we get here, not running
    debug_error_msg "🐳 Docker is not running"
    return 1
}

# Return 0 if the Docker Desktop *app UI* is running (even if the daemon is already up)
# This is distinct from docker/dockerd being available.
# Works on macOS, Linux (Docker Desktop for Linux), and Windows (from WSL/MSYS via powershell.exe).
is_docker_desktop_app_open() {
    os="$(uname -s 2>/dev/null || echo unknown)"
    case "$os" in
        Darwin)
            # Check for the GUI/Electron app process
            if pgrep -x "Docker Desktop" >/dev/null 2>&1; then
                debug_success_msg "🐳 Docker Desktop is running"
                return 0
            fi
            # Older builds report just "Docker" as the app name
            if pgrep -x "Docker" >/dev/null 2>&1; then
                debug_success_msg "🐳 Docker Desktop is running"
                return 0
            fi
            # Fallback: look for the app bundle’s executable path
            if pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1; then
                debug_success_msg "🐳 Docker Desktop is running"
                return 0
            fi
            debug_error_msg "🐳 Docker is not running"
            return 1
        ;;
        Linux)
            # Docker Desktop for Linux runs electron/backend processes under these names
            if pgrep -f "docker-desktop" >/dev/null 2>&1 || \
            pgrep -f "Docker Desktop" >/dev/null 2>&1 || \
            pgrep -f "com.docker.backend" >/dev/null 2>&1; then
                debug_success_msg "🐳 Docker Desktop is running"
                return 0
            fi
            debug_error_msg "🐳 Docker is not running"
            return 1
        ;;
        MINGW*|MSYS*|CYGWIN*)
            # On Git Bash/MSYS, try to detect Windows process via 'tasklist'
            if command -v tasklist >/dev/null 2>&1 && tasklist | grep -i "Docker Desktop" >/dev/null 2>&1; then
                debug_success_msg "🐳 Docker Desktop is running"
                return 0
            fi
            debug_error_msg "🐳 Docker is not running"
            return 1
        ;;
        *)
            # Likely WSL; use powershell.exe if available to query Windows processes
            if command -v powershell.exe >/dev/null 2>&1; then
                powershell.exe -NoProfile -Command \
                "$p=Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue; if($p){exit 0}else{exit 1}" \
                >/dev/null 2>&1
                return $?
            fi
            debug_error_msg "🐳 Docker is not running"
            return 1
        ;;
    esac
    
}
macos_docker_proc_running() {
    pgrep -f "/Applications/Docker.app/Contents/MacOS/Docker" >/dev/null 2>&1 || \
    pgrep -x Docker >/dev/null 2>&1
}
start_docker_desktop() {
    # Configurable timeout (seconds)
    : "${DOCKER_START_TIMEOUT:=300}"
    : "${DOCKER_POLL_INTERVAL:=3}"
    
    os="$(uname -s 2>/dev/null || echo unknown)"
    
    body_msg "🐳 Attempting to start Docker Desktop on your computer"
    case "$os" in
        Darwin)
            
            if ! is_docker_desktop_app_open || ! macos_docker_proc_running; then
                macos_launch_docker || warning_msg "⚠️ Failed to invoke Docker.app (check permissions/TCC) or try opening it manually."
            fi
        ;;
        Linux)
            # Detect WSL vs native Linux
            if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
                body_msg "🔎 Detected WSL"
                # Start Windows Docker Desktop from WSL; ignore output
                # (Path is default; adjust if installed elsewhere)
                powershell.exe -NoProfile -Command \
                "Start-Process -FilePath 'C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe' -WindowStyle Hidden" >/dev/null 2>&1 || true
            else
                body_msg "🔎 Detected Linux"
                # Try Docker Desktop for Linux (user service), then system dockerd
                (command -v systemctl >/dev/null 2>&1 && systemctl --user start docker-desktop 2>/dev/null) || true
                (command -v systemctl >/dev/null 2>&1 && systemctl start docker 2>/dev/null || service docker start 2>/dev/null || true)
            fi
        ;;
        MINGW*|MSYS*|CYGWIN*)
            body_msg "🔎 Detected Windows"
            cmd.exe /c "start \"\" \"C:\\Program Files\\Docker\\Docker\\Docker Desktop.exe\"" >/dev/null 2>&1 || true
        ;;
        *)
            warning_msg "⚠️ Unknown OS '$os'. Attempting to detect Docker readiness only…"
        ;;
    esac
    
    return 1
}

is_docker_compose_running() {
    docker_compose_yml_file=${1}
    # Check if any LEMP container is running
    if docker-compose -f "${docker_compose_yml_file}" ps | grep -q "Up"; then
        return 0 # True (running)
    else
        return 1 # False (not running)
    fi
}

is_docker_compose_service_running(){
    if [ -z `docker-compose ps -q <service_name>` ] || [ -z `docker ps -q --no-trunc | grep $(docker-compose ps -q <service_name>)` ]; then
        return 1
    else
        return 0
    fi
}

docker_cli_ok() {
    # Ensure docker CLI exists
    command -v docker >/dev/null 2>&1
}

docker_ready() {
    # Try without sudo first; on some Linux hosts dockerd requires group membership
    docker info >/dev/null 2>&1 && return 0
    # Last resort, non-interactive sudo if available
    command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1
}
wait_for_docker_daemon_ready() {
    timeout=${1:-180}
    interval=${2:-1}
    wait_elapsed=0
    if ! docker info >/dev/null 2>&1; then
        wait_msg "Waiting for Docker daemon to be ready "
    else
        return 0
    fi
    while :; do
        if [ "$wait_elapsed" -ge 4 ]; then
            return 1
        fi
        if docker info >/dev/null 2>&1; then
            printf '%s\n' "(${wait_elapsed}s)"
            line_break
            return 0
        fi
        printf '%s' "."
        
        sleep "$interval"
        export wait_elapsed=$((wait_elapsed + interval))
    done
}


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

# Returns "running", "down", or "missing" for the given container
check_container_status() {
    container="$1"
    
    if ! docker inspect -f '{{.State.Status}}' "$container" >/dev/null 2>&1; then
        printf '%s\n' 'missing'
        return 0
    fi
    
    status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)
    printf '%s\n' "$status"
    
}

# Usage:
#   check_compose_stack_status <STACK_NAME> [--with-partial]
# Returns: running | down | missing  (or partial if --with-partial)
check_compose_stack_status() {
    project="$1"
    mode="$2"   # optional: --with-partial
    
    if [ -z "$project" ]; then
        echo "missing"
        return 0
    fi
    
    # All containers that belong to this compose project
    cids=$(docker ps -a -q --filter "label=com.docker.compose.project=${project}")
    
    # No containers = missing stack
    if [ -z "$cids" ]; then
        echo "missing"
        return 0
    fi
    
    total=0
    running=0
    
    # Count states
    for id in $cids; do
        total=$((total+1))
        # st=$(docker inspect -f '{{.State.Status}}' "$id" 2>/dev/null || echo unknown)
        # [ "$st" = "running" ] && running=$((running+1))
        st=$(docker inspect -f '{{if .State.Running}}{{if .State.Health}}{{.State.Health.Status}}{{else}}running{{end}}{{else}}stopped{{end}}' "$id")
        [ "$st" = "healthy" ] && running=$((running+1))
    done
    
    if [ "$running" -eq "$total" ]; then
        echo "running"
        elif [ "$running" -eq 0 ]; then
        echo "down"
    else
        if [ "$mode" = "--with-partial" ]; then
            echo "partial"
        else
            # collapse partial into down for tri-state behavior
            echo "down"
        fi
    fi
}


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

fetch_all_latest_minor_versions() {
    REPO="$1"
    TAG_FILTER="${2:-.*}" # Default to '.*' (match everything if no filter is provided)
    PAGE=1
    IMAGES=""
    
    while :; do
        RESPONSE=$(curl -s "https://registry.hub.docker.com/v2/repositories/library/${REPO}/tags?page_size=100&page=${PAGE}")
        
        # Ensure valid JSON response
        if ! echo "$RESPONSE" | jq empty 2>/dev/null; then
            # debug_error_msg "Error: Invalid JSON response from Docker Hub for $REPO"
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
            # debug_error_msg "Error: Invalid JSON response from Docker Hub."
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
