---
title: SSL Configuration
nav_order: 3
parent: Deployment
---
# SSL Configuration
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Serving Inferno with SSL
Inferno uses nginx as a reverse proxy, and it can be configured to serve Inferno
with SSL.

### Configuring nginx for HTTPS
In `config/nginx.conf`, there is a `server block` which starts like this:
```nginx
  server {
    # ...
    listen 80;
```
Right below `listen 80;`, add the following to serve Inferno with SSL:
```nginx
    listen 443 default_server ssl;

    ssl_certificate /etc/ssl/certs/inferno/inferno.crt;
    ssl_certificate_key /etc/ssl/certs/inferno/inferno.key;
    ssl_protocols TLSv1.2 TLSv1.3;
```

### Adding Certificate to nginx
Once the nginx configuration has been updated, a certificate needs to be mounted
into its docker image. In `docker-compose.yml`, update the `volumes` list to
include the certificates:
```yaml
  nginx:
    image: nginx
    volumes:
      - ./config/nginx.conf:/etc/nginx/nginx.conf
      # Replace LOCAL_CERT_PATH with the path to a folder containing inferno.crt
      # and inferno.key
      - LOCAL_CERT_PATH:/etc/ssl/certs/inferno:ro
    # ...
```
