#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# TRAEFIK DOCKER CONTAINER

#
# Deploy/Update Traefik
section_title "DEPLOYING TRAEFIK DOCKER CONTAINER"

# Regenerate override aliases before (re)starting
if command -v traefik_up >/dev/null 2>&1; then
    running_msg "% traefik_up" ${C_BrightBlue}
    traefik_up
else
    # Fallback if functions not loaded
    PROJECT_PATH=${PROJECT_PATH:-"$(pwd)"}
    STACKS_PATH=${STACKS_PATH:-"$PROJECT_PATH/stacks"}
    sh "$PROJECT_PATH/scripts/traefik/update-traefik-network-overrides.sh"
    OVERRIDE_YML="${LEMP_DIR}/${TRAEFIK_DIR}/docker-compose.override.yml"
    if [ -f "$OVERRIDE_YML" ]; then
        running_msg "% docker-compose -f ${TRAEFIK_DOCKER_YML_FILE} -f $OVERRIDE_YML up -d" ${C_BrightBlue}
        docker-compose -f "${TRAEFIK_DOCKER_YML_FILE}" -f "$OVERRIDE_YML" up -d
    else
        running_msg "% docker-compose -f ${TRAEFIK_DOCKER_YML_FILE} up -d" ${C_BrightBlue}
        docker-compose -f "${TRAEFIK_DOCKER_YML_FILE}" up -d
    fi
fi
line_break

