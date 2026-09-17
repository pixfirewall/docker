# Development Environment Setup

This repository contains a Docker Compose configuration for setting up a comprehensive development environment with multiple services.

## 🚀 Services

The environment includes the following services:

- **API Gateway**
  - Kong Gateway (ports: 8000-8002, 8443-8444)
  - Kong Setup (migrations)

- **Authentication**
  - Keycloak (port: 8445)

- **Databases**
  - PostgreSQL (port: configurable)
  - MySQL (port: configurable)
  - MongoDB (port: configurable)
  - Redis (port: 6379)

- **Message Brokers**
  - NATS (ports: 4222, 8222)
  - RabbitMQ (ports: 5672, 15672)
  - Mosquitto (MQTT) (ports: 1883, 9001)

- **Development Tools**
  - Adminer (Database Management)
  - PlantUML Server (port: 8065)
  - LocalStack (AWS Services Emulator) (port: 4566)
  - SonarQube (port: 9000)
  - HAProxy (Load Balancer, opt-in via the `haproxy` profile)
  - NATS UI (port: 31311)

## 📋 Prerequisites

- Docker
- Docker Compose
- OpenSSL (to generate the development certificate)

## 🔧 Configuration

1. `.env` holds the variables used by `docker-compose.yml` itself (host ports, image versions, build args, NATS credentials).

2. Runtime configuration of each service lives in the `env/` directory:
   - kong.env
   - keycloak.env
   - postgres.env
   - mysql.env
   - mongodb.env
   - nats.env
   - mosquitto.env
   - rabbitmq.env
   - plantuml.env

3. Kong, Keycloak and Postgres expect `ca.pem` / `ca.key` in the directory specified by `SSL_CERTS_LOCATION` (defaults to ./certs). Generate a self-signed pair (valid for `localhost`, `keycloak`, `kong` and `postgres`) with `./certs/generate_ca.sh`. Existing files are backed up to `certs/backup/` before being replaced.

4. On first start Postgres runs `data/postgres/init/*.sh`, which creates the `kong` and `keycloak` databases.

## 🚀 Getting Started

1. Clone this repository:
```bash
git clone <repository-url>
```

2. Generate the certificate:
```bash
./certs/generate_ca.sh
```

3. Start all services:
```bash
docker compose up -d
```

4. To start specific services only:
```bash
docker compose up -d <service-name>
```

`kong-setup` runs the Kong database migrations and has to finish before `kong` starts; `docker compose up -d kong` takes care of the ordering (and waits for Postgres to be healthy).

The `package.json` scripts are shortcuts for the most used commands, e.g. `yarn kong`, `yarn kc`, `yarn logs`, `yarn down`.

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
│ └── sonarqube/
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

## 🛠 Service-Specific Configuration

### Kong
- Admin API: http://localhost:8001
- Proxy: http://localhost:8000
- Admin GUI: http://localhost:8002

### Keycloak
- Admin Console: https://localhost:8445 (bootstrap admin: `admin` / `admin`, see `env/keycloak.env`)

### Database Management
- Adminer: http://localhost:{MYSQL_ADMINER_PORT} (default 8080)
- MongoDB: mongodb://localhost:{MONGODB_PORT}
- PostgreSQL: postgresql://localhost:{POSTGRES_PORT}
- MySQL: mysql://localhost:{MYSQL_DATABASE_PORT}

### Message Brokers
- NATS: nats://localhost:4222 (monitoring: http://localhost:8222, UI: http://localhost:31311)
- RabbitMQ Management: http://localhost:15672
- MQTT: localhost:1883

### Development Tools
- PlantUML Server: http://localhost:8065
- LocalStack: http://localhost:4566 (health: http://localhost:4566/_localstack/health)
  - Pinned to `4.14`, newer releases require a LocalStack account: export `LOCALSTACK_AUTH_TOKEN` and bump `LOCALSTACK_VERSION` in `.env`
- SonarQube: http://localhost:9000
- Test node app: http://localhost:3007/health

### HAProxy
Not started by default. Add `data/haproxy/haproxy.cfg` and run `docker compose --profile haproxy up -d haproxy` (exposed on 5673 / 15673 so it does not clash with RabbitMQ).

## 📄 License

This project is licensed under the MIT License (see `package.json`).
