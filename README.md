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

# 4. optional: tools + landing page with links to everything
docker compose --profile tools up -d homepage   # then open http://localhost:3080
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
| `tools` | `homepage` | Landing page with links and status of every service | 3080 |
| `tools` | `wiremock` | Mock HTTP APIs from JSON mappings | 8092 |
| `tools` | `vault` | HashiCorp Vault in dev mode (secrets, token `root`) | 8200 |
| `observability` | `prometheus` | Metrics of Kong, Keycloak, RabbitMQ, Postgres, Redis, MongoDB, NATS | 9090 |
| `observability` | `grafana` | Prometheus, Loki and Jaeger preconfigured, *Dev stack overview* dashboard | 3000 |
| `observability` | `jaeger` | Distributed tracing (OpenTelemetry OTLP receiver) | 16686 (UI), 4317 (gRPC), 4318 (HTTP) |
| `observability` | `loki` + `alloy` | Logs of all containers of this project, searchable in Grafana | 3100, 12345 |
| `observability` | `postgres-exporter`, `redis-exporter`, `mongodb-exporter`, `nats-exporter` | Database / broker metrics for Prometheus | internal |
| `observability` | `kong-observability` | One-shot: enables Kong's prometheus and opentelemetry plugins | |
| `kafka` | `kafka` | Apache Kafka, single node KRaft (no ZooKeeper) | 9094 |
| `kafka` | `kafka-ui` | Kafka web UI (topics, consumer groups, messages) | 8090 |
| `search` | `opensearch` | OpenSearch (Elasticsearch compatible API), security disabled | 9200 |
| `search` | `opensearch-dashboards` | OpenSearch web UI (Kibana fork) | 5601 |
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

# Kafka or OpenSearch together with their UI
docker compose --profile kafka up -d kafka kafka-ui
docker compose --profile search up -d opensearch opensearch-dashboards

# a single optional service (naming it enables its profile)
docker compose up -d mailpit
```

To enable profiles permanently, set `COMPOSE_PROFILES=tools,observability` in `.env`.

> Running everything at once needs a lot of memory (OpenSearch, Kafka, Keycloak, SonarQube are JVM based). Give Docker Desktop at least 8 GB, or start only what you need. The JVM heaps are capped for local use (`JAVA_OPTS_KC_HEAP` in `env/keycloak.env`, `KAFKA_HEAP_OPTS` in `env/kafka.env`, `OPENSEARCH_JAVA_OPTS` in `env/opensearch.env`) and Kong runs 2 nginx workers instead of one per CPU (`KONG_NGINX_WORKER_PROCESSES`).

`docker compose up -d --wait <services>` blocks until the services with a health check are healthy, handy in scripts.

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
docker compose --profile '*' down -v     # ... and remove the named volumes (grafana, prometheus, loki, kafka, opensearch, ...)
```

Database data is stored in bind mounts below `data/` (e.g. `data/postgres/data/pgdata`). Stop the service and delete that directory to start from scratch.

### package.json shortcuts

| Command | Runs |
|---|---|
| `yarn up` | `docker compose up -d` |
| `yarn tools` / `yarn obs` / `yarn all` | default services + tools / + observability / + every optional profile |
| `yarn kafka` / `yarn search` | Kafka + Kafka UI / OpenSearch + Dashboards |
| `yarn home` | landing page on http://localhost:3080 |
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
   - kafka.env
   - opensearch.env
   - vault.env
   - postgres-exporter.env
   - mongodb-exporter.env
   - nats.env
   - mosquitto.env
   - rabbitmq.env
   - plantuml.env

3. Kong, Keycloak, Postgres and Prometheus expect `ca.pem` / `ca.key` in the directory specified by `SSL_CERTS_LOCATION` (defaults to ./certs). Generate a self-signed pair (valid for `localhost`, `keycloak`, `kong` and `postgres`) with `./certs/generate_ca.sh`. Existing files are backed up to `certs/backup/` before being replaced.

4. On first start Postgres runs `data/postgres/init/*.sh`, which creates the `kong` and `keycloak` databases.

5. On first start Keycloak imports the realms in `data/keycloak/import/` (see [Keycloak](#keycloak)).

## 🛠 URLs and Credentials

| Service | URL | Credentials |
|---|---|---|
| Kong proxy | http://localhost:8000, https://localhost:8443 | |
| Kong Admin API | http://localhost:8001 | |
| Kong Manager | http://localhost:8002 | |
| Keycloak | https://localhost:8445 | `admin` / `admin` (realm `dev`: `dev` / `dev`) |
| PostgreSQL | `postgresql://test:test@localhost:5432/postgres` | `test` / `test` |
| MySQL | `mysql://root:test@localhost:3306` | `root` / `test` |
| MongoDB | `mongodb://root:password@localhost:27017` | `root` / `password` |
| Redis | `redis://localhost:6379` | |
| Adminer | http://localhost:8080 (server: `postgres` or `mysql`) | database credentials |
| NATS | `nats://lf-test:<NATS_PASSWORD>@localhost:4222`, monitoring http://localhost:8222 | see `.env` |
| NATS UI | http://localhost:31311 | |
| RabbitMQ | `amqp://test:test@localhost:5672`, management http://localhost:15672 | `test` / `test` |
| MQTT (Mosquitto) | `mqtt://localhost:1883`, websockets `ws://localhost:9001` | user from `data/mosquitto/mosquitto.passwd` |
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
| Loki / Alloy | http://localhost:3100, http://localhost:12345 | |
| Homepage | http://localhost:3080 | |
| WireMock | http://localhost:8092 (admin API: `/__admin`) | |
| Vault | http://localhost:8200 | token `root` |
| Kafka | `localhost:9094` (host), `kafka:9092` (containers) | |
| Kafka UI | http://localhost:8090 | |
| OpenSearch | http://localhost:9200 | |
| OpenSearch Dashboards | http://localhost:5601 | |

From inside other containers use the service name as host, e.g. `postgres:5432`, `redis:6379`, `mailpit:1025`, `jaeger:4318`.

## 🧰 Service Notes

### Kong
- Uses a custom image with the [kong-oidc](https://github.com/pixfirewall/kong-oidc) plugin.
- `kong-setup` runs the database migrations and has to finish before `kong` starts; `docker compose up -d kong` takes care of the ordering (and waits for Postgres to be healthy).
- `data/kong/kong.yaml` is a declarative configuration example. Kong runs in database mode, so it is only loaded when `KONG_DECLARATIVE_CONFIG` is enabled in `env/kong.env`.

### Keycloak
- A `dev` realm is imported on first start (`data/keycloak/import/dev-realm.json`) with
  - user `dev` / `dev`
  - confidential client `kong-oidc` (secret in the realm file, the same as in `data/kong/kong.yaml`) with password grant and service account enabled
  - an audience mapper adding `kong-oidc` to the `aud` claim: current Keycloak versions only allow a client to introspect tokens it is an audience of, without it Kong's oidc plugin rejects every token
  - email sent to Mailpit (`mailpit:1025`), so start the `tools` profile to receive password reset / verification mails
- Get a token and use it through Kong:
  ```bash
  TOKEN=$(curl -s --cacert certs/ca.pem https://localhost:8445/realms/dev/protocol/openid-connect/token \
    -d grant_type=password -d client_id=kong-oidc -d client_secret=fVnDuSnOY8Z0i6Celg089lqccLK5ZSb5 \
    -d username=dev -d password=dev | jq -r .access_token)
  curl -H "Authorization: Bearer $TOKEN" http://localhost:8000/<route protected by the oidc plugin>
  ```
- `KC_HOSTNAME` is the full public URL (`https://localhost:8445`), so tokens have the same issuer whether Keycloak is called from the host or from a container (`https://keycloak:8443`).
- Realms are only imported when they don't exist yet. To re-import after changing the file, delete the realm in the admin console and restart Keycloak.
- Export a realm you configured in the UI: `docker compose exec keycloak /opt/keycloak/bin/kc.sh export --realm dev --dir /tmp/export --optimized` and `docker compose cp keycloak:/tmp/export ./data/keycloak/import`.

### LocalStack
- Pinned to `4.14`, newer releases require a LocalStack account: export `LOCALSTACK_AUTH_TOKEN` in your shell and bump `LOCALSTACK_VERSION` in `.env`.
- Scripts in `data/localstack/init/*.sh` run once LocalStack is ready (e.g. to create buckets / queues).

### RedisInsight
- The connection to the `redis` service is preconfigured; it shows up after accepting the terms on the first visit.

### Homepage
- http://localhost:3080 lists every service with its link, credentials and container status (green = running).
- Edit `data/homepage/services.yaml` to add your own applications; changes are picked up without restart.

### WireMock
- Every JSON file in `data/wiremock/mappings/` is a stub, response bodies can live in `data/wiremock/__files/`. Response templating is enabled.
  ```bash
  curl http://localhost:8092/hello/world          # {"message":"Hello world", ...}
  curl -X POST http://localhost:8092/__admin/mappings/reset   # reload the mapping files
  ```
- Point an application or a Kong service at `http://wiremock:8080` to mock an upstream.

### Vault
- Dev mode: in-memory, unsealed, **all data is lost on restart**. Root token `root`.
  ```bash
  docker compose exec vault vault kv put secret/my-app db_password=s3cret
  curl -H "X-Vault-Token: root" http://localhost:8200/v1/secret/data/my-app
  ```

### Kafka
- Single broker in KRaft mode, topics are auto-created. Clients on the host connect to `localhost:9094`, containers to `kafka:9092`.
  ```bash
  docker compose exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic demo
  echo 'hello' | docker compose exec -T kafka /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic demo
  docker compose exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic demo --from-beginning --max-messages 1
  ```

### OpenSearch
- Single node without TLS / authentication, heap limited to 512 MB (`env/opensearch.env`).
  ```bash
  curl -X PUT 'http://localhost:9200/products/_doc/1' -H 'content-type: application/json' -d '{"name":"keyboard"}'
  curl 'http://localhost:9200/products/_search?q=name:keyboard'
  ```
- On Linux OpenSearch needs `sudo sysctl -w vm.max_map_count=262144` on the host.

### MQTT
- `mosquitto` listens for MQTT on 1883 and MQTT over websockets on 9001 (e.g. for browser clients), both require the user from `data/mosquitto/mosquitto.passwd`.

### Observability
Start it with `docker compose --profile observability up -d`, it includes everything below.

- **Dashboard**: Grafana (http://localhost:3000) ships a *Dev stack overview* dashboard (folder *Dev stack*) with scrape target status, Kong traffic and latency, Keycloak, Postgres, Redis, MongoDB, RabbitMQ, NATS and a searchable log panel. Dashboards in `data/grafana/dashboards/` are loaded automatically; import more community dashboards via *Dashboards → New → Import*, e.g. `7424` (Kong), `10991` (RabbitMQ), `9628` (Postgres), `763` (Redis).
- **Metrics**: Prometheus (http://localhost:9090/targets) scrapes Kong, Keycloak, RabbitMQ, Postgres, Redis, MongoDB, NATS, Loki and Alloy. The configuration is `data/prometheus/prometheus.yml`, reload it after changes with `curl -X POST http://localhost:9090/-/reload`.
- **Logs**: Alloy ships the logs of all containers of this compose project to Loki. Search them in Grafana → *Explore* → *Loki*, e.g. `{service="kong"} |= "error"`.
- **Traces**: the `kong-observability` one-shot enables Kong's `prometheus` and `opentelemetry` plugins (script: `data/kong/observability-plugins.sh`), so every request proxied by Kong shows up in Jaeger (http://localhost:16686) as service `kong`. Your own applications can export OpenTelemetry traces to `http://localhost:4318` (or `http://jaeger:4318` from a container), e.g. with `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`.
- To enable the Kong plugins again, e.g. after resetting the Postgres data: `docker compose --profile observability up kong-observability`.

### HAProxy
Not started by default. Add `data/haproxy/haproxy.cfg` and run `docker compose --profile haproxy up -d haproxy` (exposed on 5673 / 15673 so it does not clash with RabbitMQ).

## 🩺 Troubleshooting

- **`port is already allocated` / `address already in use`**: another process uses the host port. Change the port in `.env` (e.g. `GRAFANA_PORT=3001`, `POSTGRES_PORT=5433`) or stop the other process (`lsof -nP -iTCP:<port> -sTCP:LISTEN`).
- **`kong` does not start**: check `docker compose logs kong-setup`; the migrations need Postgres and the `kong` database. On an existing Postgres data directory created before the init script existed, create it manually: `docker compose exec postgres psql -U test -c 'CREATE DATABASE kong'` (same for `keycloak`).
- **Keycloak / Kong TLS errors**: run `./certs/generate_ca.sh` and restart the services. Trust `certs/ca.pem` in your OS / browser, or use `curl --cacert certs/ca.pem`.
- **Apple Silicon**: `mysql` (5.7) and `sonarqube` (8.9) only exist for amd64 and run emulated, so they start slower.
- **Grafana data source changes are not picked up**: provisioning is read at startup, run `docker compose restart grafana`.
- **Grafana panels show `Plugin not registered`**: Grafana downloads some data source plugins (e.g. Prometheus) from grafana.com on its first start. If that download failed (offline, slow machine), run `docker compose restart grafana`.
- **A container is `unhealthy`**: `docker inspect --format '{{json .State.Health}}' <container>` shows the output of the last health checks.
- **OpenSearch / Kafka exit with code 137**: out of memory, increase the memory of Docker Desktop or start fewer services.
- **Keycloak token rejected by Kong**: the realm `dev` is imported only on the first start of a fresh Keycloak database; check that it exists at https://localhost:8445/admin.

## ✅ CI

`.github/workflows/ci.yml` runs on every pull request:
- **lint**: `docker compose config` for all profiles, ShellCheck, Hadolint, JSON / Prometheus / Alloy config validation
- **smoke test**: builds the custom images, starts Postgres, Kong, Keycloak, Redis, RabbitMQ and the test app with `--wait` and checks their endpoints

Dependabot (`.github/dependabot.yml`) opens weekly pull requests for image, npm and GitHub Actions updates.

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
│ ├── keycloak/import/  (realms imported on first start)
│ ├── prometheus/    (prometheus.yml scrape configuration)
│ ├── grafana/       (provisioned data sources and dashboards)
│ ├── alloy/         (log collection configuration)
│ ├── homepage/      (landing page configuration)
│ └── wiremock/      (API mock mappings and response files)
├── env/
│ └── (environment files)
├── certs/
│ ├── generate_ca.sh
│ └── (SSL certificates)
├── .github/         (CI workflow, Dependabot)
├── test-node/       (tiny express app that logs incoming requests)
└── docker-compose.yml
```

## 🔒 Security Notes

- SSL certificates are mounted where needed
- All credentials in this repository (`.env`, `env/*.env`, `data/kong/kong.yaml`, `data/mosquitto/mosquitto.passwd`) are for local development only, never reuse them anywhere else
- Kong is configured with no-new-privileges security option
- `dozzle`, `homepage`, `alloy` and `localstack` get access to the Docker socket; don't expose them beyond your machine
- `vault` runs in dev mode with a well-known root token

## 📄 License

This project is licensed under the MIT License (see `package.json`).
