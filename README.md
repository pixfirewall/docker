# Development Environment Setup

This repository contains a Docker Compose configuration for a local development environment: an API gateway, identity provider, databases, message brokers and optional developer / observability tools.

## ⚡ Quick Start

```bash
git clone git@github.com:pixfirewall/docker.git && cd docker

# 1. generate the self-signed certificate used by Kong, Keycloak and Postgres
./certs/generate_ca.sh

# 2. start what you need, e.g. the gateway + identity provider (postgres starts automatically)
docker compose up -d kong keycloak

# 3. check the status
docker compose ps
```

Everything is configured with local defaults, no extra setup is required.

## 🚀 Services

### Default services

Started by a plain `docker compose up -d`:

| Group | Service | Host ports |
|---|---|---|
| API Gateway | `kong` (+ `kong-setup` running the migrations) | 8000-8002, 8443-8444 |
| Authentication | `keycloak` | 8445 |
| Databases | `postgres`, `mysql`, `mongodb`, `redis` | 5432, 3306, 27017, 6379 |
| Message brokers | `nats` (+ `nui` UI), `rabbitmq`, `mosquitto` | 4222, 8222, 31311, 5672, 15672, 1883, 9001 |
| Development tools | `adminer`, `plantuml-server`, `localstack`, `sonarqube`, `test` | 8080, 8065, 4566, 4510-4559, 9000, 3007 |

### Optional services (profiles)

Not started unless their [profile](https://docs.docker.com/compose/how-tos/profiles/) is enabled:

| Profile | Service | Purpose | Host ports |
|---|---|---|---|
| `tools` | `mailpit` | Catches every email sent via SMTP and shows it in a web UI | 1025 (SMTP), 8025 (UI) |
| `tools` | `mongo-express` | MongoDB web UI | 8081 |
| `tools` | `redisinsight` | Redis web UI | 5540 |
| `tools` | `dozzle` | Live logs of all containers in the browser | 8888 |
| `observability` | `prometheus` | Scrapes metrics of Kong, Keycloak, RabbitMQ | 9090 |
| `observability` | `grafana` | Dashboards, Prometheus and Jaeger preconfigured | 3000 |
| `observability` | `jaeger` | Distributed tracing (OpenTelemetry OTLP receiver) | 16686 (UI), 4317 (gRPC), 4318 (HTTP) |
| `haproxy` | `haproxy` | Load balancer in front of RabbitMQ (bring your own config) | 5673, 15673 |

## 📋 Prerequisites

- Docker with Docker Compose v2 (`docker compose version`)
- OpenSSL (to generate the development certificate)
- Optional: `yarn` or `npm` for the shortcuts in `package.json`

## ▶️ Running

### Start services

```bash
# every default service
docker compose up -d

# only the services you need (dependencies such as postgres are started automatically)
docker compose up -d kong keycloak redis

# default services + optional tools
docker compose --profile tools up -d

# default services + tools + observability
docker compose --profile tools --profile observability up -d

# a single optional service (naming it enables its profile)
docker compose up -d mailpit
```

To enable profiles permanently, set `COMPOSE_PROFILES=tools,observability` in `.env`.

### Inspect

```bash
docker compose ps                  # status / health
docker compose logs -f kong        # follow the logs of a service
docker compose exec postgres psql -U test -d postgres   # open a shell / client inside a container
```

Or start `dozzle` and open http://localhost:8888 to follow all logs in the browser.

### Stop and reset

```bash
docker compose --profile '*' down        # stop and remove all containers (data is kept)
docker compose --profile '*' down -v     # ... and remove the named volumes (grafana, prometheus, redisinsight)
```

Database data is stored in bind mounts below `data/` (e.g. `data/postgres/data/pgdata`). Stop the service and delete that directory to start from scratch.

### package.json shortcuts

| Command | Runs |
|---|---|
| `yarn up` | `docker compose up -d` |
| `yarn tools` / `yarn obs` / `yarn all` | default services + tools / observability / both |
| `yarn kong`, `yarn kc`, `yarn pg`, `yarn ad`, `yarn ls`, `yarn sq` | start Kong, Keycloak, Postgres, Adminer, LocalStack, SonarQube |
| `yarn ps`, `yarn logs` | status, follow logs |
| `yarn down` | stop everything, including optional services |
| `yarn certs` | (re)generate the certificate |

`npm run <script>` works the same way.

## 🔧 Configuration

1. `.env` holds the variables used by `docker-compose.yml` itself (host ports, image versions, build args, NATS credentials, profiles). Most values have defaults in `docker-compose.yml` (`${VAR:-default}`), so override only what you need, e.g. a host port that is already in use.

2. Runtime configuration of each service lives in the `env/` directory:
   - kong.env
   - keycloak.env
   - postgres.env
   - mysql.env
   - mongodb.env
   - mongo-express.env
   - grafana.env
   - nats.env
   - mosquitto.env
   - rabbitmq.env
   - plantuml.env

3. Kong, Keycloak, Postgres and Prometheus expect `ca.pem` / `ca.key` in the directory specified by `SSL_CERTS_LOCATION` (defaults to ./certs). Generate a self-signed pair (valid for `localhost`, `keycloak`, `kong` and `postgres`) with `./certs/generate_ca.sh`. Existing files are backed up to `certs/backup/` before being replaced.

4. On first start Postgres runs `data/postgres/init/*.sh`, which creates the `kong` and `keycloak` databases.

## 🛠 URLs and Credentials

| Service | URL | Credentials |
|---|---|---|
| Kong proxy | http://localhost:8000, https://localhost:8443 | |
| Kong Admin API | http://localhost:8001 | |
| Kong Manager | http://localhost:8002 | |
| Keycloak | https://localhost:8445 | `admin` / `admin` |
| PostgreSQL | `postgresql://test:test@localhost:5432/postgres` | `test` / `test` |
| MySQL | `mysql://root:test@localhost:3306` | `root` / `test` |
| MongoDB | `mongodb://root:password@localhost:27017` | `root` / `password` |
| Redis | `redis://localhost:6379` | |
| Adminer | http://localhost:8080 (server: `postgres` or `mysql`) | database credentials |
| NATS | `nats://lf-test:<NATS_PASSWORD>@localhost:4222`, monitoring http://localhost:8222 | see `.env` |
| NATS UI | http://localhost:31311 | |
| RabbitMQ | `amqp://test:test@localhost:5672`, management http://localhost:15672 | `test` / `test` |
| MQTT (Mosquitto) | `mqtt://localhost:1883` | user from `data/mosquitto/mosquitto.passwd` |
| PlantUML | http://localhost:8065 | |
| LocalStack | http://localhost:4566 (health: `/_localstack/health`) | |
| SonarQube | http://localhost:9000 | `admin` / `admin` |
| Test node app | http://localhost:3007/health | |
| Mailpit | http://localhost:8025, SMTP `localhost:1025` (from containers: `mailpit:1025`) | any / none |
| mongo-express | http://localhost:8081 | `admin` / `admin` |
| RedisInsight | http://localhost:5540 | |
| Dozzle | http://localhost:8888 | |
| Prometheus | http://localhost:9090 | |
| Grafana | http://localhost:3000 | `admin` / `admin` |
| Jaeger | http://localhost:16686, OTLP `localhost:4317` (gRPC) / `localhost:4318` (HTTP) | |

From inside other containers use the service name as host, e.g. `postgres:5432`, `redis:6379`, `mailpit:1025`, `jaeger:4318`.

## 🧰 Service Notes

### Kong
- Uses a custom image with the [kong-oidc](https://github.com/pixfirewall/kong-oidc) plugin.
- `kong-setup` runs the database migrations and has to finish before `kong` starts; `docker compose up -d kong` takes care of the ordering (and waits for Postgres to be healthy).
- `data/kong/kong.yaml` is a declarative configuration example. Kong runs in database mode, so it is only loaded when `KONG_DECLARATIVE_CONFIG` is enabled in `env/kong.env`.

### Keycloak
- To send emails (password reset, verification) to Mailpit: *Realm settings → Email*, host `mailpit`, port `1025`, no SSL/authentication.

### LocalStack
- Pinned to `4.14`, newer releases require a LocalStack account: export `LOCALSTACK_AUTH_TOKEN` in your shell and bump `LOCALSTACK_VERSION` in `.env`.
- Scripts in `data/localstack/init/*.sh` run once LocalStack is ready (e.g. to create buckets / queues).

### RedisInsight
- The connection to the `redis` service is preconfigured; it shows up after accepting the terms on the first visit.

### Observability
Start it with `docker compose --profile observability up -d` (Kong, Keycloak and RabbitMQ should be running to have something to look at).

- **Metrics**: Prometheus scrapes RabbitMQ and Keycloak out of the box. Kong only exposes metrics once its Prometheus plugin is enabled:
  ```bash
  curl -X POST http://localhost:8001/plugins -d name=prometheus
  ```
  Check the targets at http://localhost:9090/targets. The scrape configuration is `data/prometheus/prometheus.yml`, reload it after changes with `curl -X POST http://localhost:9090/-/reload`.
- **Dashboards**: Grafana comes with the Prometheus and Jaeger data sources. Import community dashboards via *Dashboards → New → Import*, e.g. `7424` (Kong) or `10991` (RabbitMQ).
- **Tracing**: enable the OpenTelemetry plugin in Kong to send a trace for every proxied request to Jaeger:
  ```bash
  curl -X POST http://localhost:8001/plugins \
    -H 'content-type: application/json' \
    -d '{"name":"opentelemetry","config":{"endpoint":"http://jaeger:4318/v1/traces","resource_attributes":{"service.name":"kong"}}}'
  ```
  Your own applications can export OpenTelemetry traces to `http://localhost:4318` (or `http://jaeger:4318` from a container), e.g. with `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`.

### HAProxy
Not started by default. Add `data/haproxy/haproxy.cfg` and run `docker compose --profile haproxy up -d haproxy` (exposed on 5673 / 15673 so it does not clash with RabbitMQ).

## 🩺 Troubleshooting

- **`port is already allocated` / `address already in use`**: another process uses the host port. Change the port in `.env` (e.g. `GRAFANA_PORT=3001`, `POSTGRES_PORT=5433`) or stop the other process (`lsof -nP -iTCP:<port> -sTCP:LISTEN`).
- **`kong` does not start**: check `docker compose logs kong-setup`; the migrations need Postgres and the `kong` database. On an existing Postgres data directory created before the init script existed, create it manually: `docker compose exec postgres psql -U test -c 'CREATE DATABASE kong'` (same for `keycloak`).
- **Keycloak / Kong TLS errors**: run `./certs/generate_ca.sh` and restart the services. Trust `certs/ca.pem` in your OS / browser, or use `curl --cacert certs/ca.pem`.
- **Apple Silicon**: `mysql` (5.7) and `sonarqube` (8.9) only exist for amd64 and run emulated, so they start slower.
- **Grafana data source changes are not picked up**: provisioning is read at startup, run `docker compose restart grafana`.

## 📁 Directory Structure
```
.
├── data/
│ ├── kong/          (custom image with the kong-oidc plugin, kong.yaml)
│ ├── keycloak/
│ ├── localstack/    (init/ holds scripts run once LocalStack is ready)
│ ├── redis/
│ ├── postgres/      (init/ holds first-start database scripts)
│ ├── mysql/
│ ├── mongodb/
│ ├── rabbitmq/      (custom image with the delayed message exchange plugin)
│ ├── mosquitto/
│ ├── nuidb/
│ ├── plantuml/
│ ├── sonarqube/
│ ├── prometheus/    (prometheus.yml scrape configuration)
│ └── grafana/       (provisioned data sources)
├── env/
│ └── (environment files)
├── certs/
│ ├── generate_ca.sh
│ └── (SSL certificates)
├── test-node/       (tiny express app that logs incoming requests)
└── docker-compose.yml
```

## 🔒 Security Notes

- SSL certificates are mounted where needed
- All credentials in this repository (`.env`, `env/*.env`, `data/kong/kong.yaml`, `data/mosquitto/mosquitto.passwd`) are for local development only, never reuse them anywhere else
- Kong is configured with no-new-privileges security option
- `dozzle` and `localstack` get access to the Docker socket; don't expose them beyond your machine

## 📄 License

This project is licensed under the MIT License (see `package.json`).
