# TRAEFIK

### 'DYNAMIC' CONFIGS
These config files correspond to one of the project's few Shell script auto-created Docker Compose container types:

#### CONFIG FILE NAME SYNTAX
```
 1. LEMP stack -> lemp-domain.yml
 2. Wordpress container -> lemp-domain-subdomain.yml
```
These two auto-created Docker Compose container types are connected to their own domain or subdomain through a Traefik 'dynamic' config file.

Each Docker compose container will need its own dynamic configuration file inside traefik/dynamic to serve the files from a browser through traefik.

Each configuration file sources their corresponding certificate and key files certs/*.crt & certs/*.key files to serve TLS protected domains and their subdomains to your Virtual Host domain.

These config .yml files are created automatically during the process after you select 'Create New \<docker_container>' Multistack Menu options list.