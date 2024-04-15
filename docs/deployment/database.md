---
title: Database Configuration
nav_order: 2
parent: Deployment
---
# Database Configuration
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Database Configuration
The database configuration lives in `config/database.yml`. Inferno uses the
[Sequel gem](http://sequel.jeremyevans.net/) to communicate with the database,
which offers [the following configuration
options](http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-General+connection+options).

## PostgreSQL
Inferno defaults to using SQLite, which is not suitable for use in a multi-user
deployment. Multi-user deployments should use PostgreSQL instead.

### PostgreSQL with Docker
Rather than setting up a separate PostgreSQL service, you can run it via
`docker compose` along with the rest of Inferno's services. To do so:
* Add `gem 'pg'` to `Gemfile`
* Add the following entry to `docker-compose.yml`:
```yaml
  inferno_db:
    image: postgres:14.1-alpine
    mem_limit: 600m
    restart: unless-stopped
    volumes:
      - ./data/pg:/var/lib/postgresql/data
    environment:
      POSTGRES_HOST_AUTH_METHOD: trust
      POSTGRES_DB: inferno_production
```
* Add `inferno_db` to the `depends_on` for `inferno` and `worker` services in
  `docker-compose.yml`. For example:
```yaml
  inferno:
    # ...
    depends_on:
      - validator_service
      - inferno_db
  worker:
    # ...
    depends_on:
      - redis
      - inferno_db
```
* Use the following for the production configuration in `config/database.yml`:
```yaml
production:
  adapter: postgres
  database: inferno_production
  max_connections: 10
  user: postgres
  host: inferno_db
```

### PostgreSQL with a Separate Service
If you have an existing PostgreSQL service that you would like to use, you can
use it with the following steps:

* Add `gem 'pg'` to `Gemfile`
* In `config/database.yml`, change the `adapter` in the `production` entry to
  `postgres`, and supply the `database`, `user`, `password`, `host`, and `port`
  for the PostgreSQL database

**Note**: If you are using replication, for example with AWS RDS, you may
encounter the error `cannot update table "schema_info" because
it does not have a replica identity` when first setting up Inferno.
If this occurs, run the following command in the database:
```sql
ALTER TABLE schema_info REPLICA IDENTITY FULL;
```
