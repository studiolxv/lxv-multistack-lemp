#!/bin/sh

#####################################################
# TRAEFIK

# ---- Traefik helpers ----
traefik_update_overrides() {
  # Ensure env paths for the updater script
  PROJECT_PATH=${PROJECT_PATH:-"$(pwd)"}
  STACKS_PATH=${STACKS_PATH:-"$PROJECT_PATH/stacks"}
  sh "$PROJECT_PATH/scripts/traefik/update-traefik-network-overrides.sh"
}
export -f traefik_update_overrides

traefik_compose() {
  # Compose helper that always includes the override file if present
  BASE_YML="${TRAEFIK_DOCKER_YML_FILE}"
  OVERRIDE_YML="${LEMP_DIR}/${TRAEFIK_DIR}/docker-compose.override.yml"
  if [ -f "$OVERRIDE_YML" ]; then
    docker-compose -f "$BASE_YML" -f "$OVERRIDE_YML" "$@"
  else
    docker-compose -f "$BASE_YML" "$@"
  fi
}
export -f traefik_compose

traefik_up() {
  traefik_update_overrides
  traefik_compose up -d
}
export -f traefik_up

traefik_down() {
  traefik_compose down
}
export -f traefik_down

traefik_reload() {
  traefik_update_overrides
  traefik_compose up -d --force-recreate
}
export -f traefik_reload
