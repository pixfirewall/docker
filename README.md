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
  - LocalStack (AWS Services Emulator)
  - SonarQube (port: 9000)
  - HAProxy (Load Balancer)

## 📋 Prerequisites

- Docker
- Docker Compose
- SSL certificates (placed in ./certs directory)

## 🔧 Configuration

1. Create the necessary environment files in the `env/` directory:
   - kong.env
   - keycloak.env
   - postgres.env
   - mongodb.env
   - nats.env
   - mosquitto.env
   - rabbitmq.env

2. SSL certificates should be placed in the directory specified by `SSL_CERTS_LOCATION` (defaults to ./certs)

## 🚀 Getting Started

1. Clone this repository:
```bash
git clone <repository-url>
```

2. Start all services:
```bash
docker compose up -d
```

3. To start specific services only:
```bash
docker compose up -d <service-name>
```

## 📁 Directory Structure
```
.
├── data/
│ ├── kong/
│ ├── keycloak/
│ ├── redis/
│ ├── postgres/
│ ├── mysql/
│ ├── mongodb/
│ ├── rabbitmq/
│ └── mosquitto/
├── env/
│ └── (environment files)
├── certs/
│ └── (SSL certificates)
└── docker-compose.yml
```

## 🔒 Security Notes

- SSL certificates are mounted where needed
- Services are configured with appropriate security settings
- Kong is configured with no-new-privileges security option

## 🛠 Service-Specific Configuration

### Kong
- Admin API: http://localhost:8001
- Proxy: http://localhost:8000
- Admin GUI: http://localhost:8002

### Keycloak
- Admin Console: https://localhost:8445

### Database Management
- Adminer: http://localhost:{MYSQL_ADMINER_PORT}
- MongoDB: mongodb://localhost:{MONGODB_PORT}
- PostgreSQL: postgresql://localhost:{POSTGRES_PORT}
- MySQL: mysql://localhost:{MYSQL_DATABASE_PORT}

### Message Brokers
- NATS: nats://localhost:4222
- RabbitMQ Management: http://localhost:15672
- MQTT: localhost:1883

### Development Tools
- PlantUML Server: http://localhost:8065
- LocalStack Dashboard: http://localhost:8055
- SonarQube: http://localhost:9000

## 🤝 Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the [LICENSE NAME] - see the LICENSE.md file for details