traefik/traefik.yml
This config enables Traefik to watch for new routing files in dynamic/.

traefik/docker-compose.yml
This ensures that Traefik dynamically loads routing rules from the dynamic/ directory.

traefik/dynamic/example-one.yml
- One file per LEMP stack server (LEMP_DOMAIN_NAME.yml)
- Each LEMP stack will have its own config file inside 'traefik/dynamic'
- This file routes requests to Nginx & phpMyAdmin inside example-one.test.