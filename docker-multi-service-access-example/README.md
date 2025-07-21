# Multi-Service Application with Traefik

A microservices application with two Go services communicating internally and exposing APIs externally, all running in Docker containers with Traefik as a reverse proxy and load balancer. The UI is built with React and Vite. **No nginx required - everything is handled by Traefik!**

## Architecture

- **Service A**: Go service with Gin framework
- **Service B**: Go service with Gin framework  
- **Traefik**: Reverse proxy, load balancer, and API gateway (replaces nginx)
- **UI**: React application with Vite, served by a simple Node.js server

### Key Features
- **No nginx dependency**: Everything is handled by Traefik
- **Dynamic configuration**: Traefik reads configuration from files
- **Service discovery**: Automatic service discovery via Docker labels
- **Health checks**: Built-in health monitoring
- **Flexible routing**: Path-based and host-based routing
- **Flexible development**: Mix local IDE and Docker services

### Migration from nginx to Traefik
This project previously used nginx as a reverse proxy, but has been migrated to use Traefik exclusively. The benefits include:

- **Simplified architecture**: One reverse proxy instead of two
- **Better service discovery**: Automatic discovery via Docker labels
- **Dynamic configuration**: Hot-reload of configuration files
- **Built-in monitoring**: Traefik dashboard with real-time metrics
- **Modern features**: Middleware support, automatic SSL, and more

The migration involved:
1. Removing nginx containers and configurations
2. Using Traefik's file provider for dynamic configuration
3. Configuring host services via dynamic YAML files
4. Updating development scripts to generate Traefik configs

## Services

### Service A
- **Port**: 8080 (internal)
- **Endpoints**:
  - `GET /health` - Health check
  - `GET /data` - Get service data
  - `POST /items` - Create item
  - `GET /items` - Get all items
  - `GET /call-service-b` - Call Service B
  - `GET /call-both` - Call both services

### Service B
- **Port**: 8080 (internal)
- **Endpoints**:
  - `GET /health` - Health check
  - `GET /data` - Get service data
  - `POST /process` - Process data
  - `GET /call-service-a` - Call Service A

### UI Application
- **Port**: 3000 (internal)
- **Framework**: React with Vite
- **Server**: Node.js with `serve` package
- **Features**:
  - Dashboard with service health monitoring
  - Individual service testing
  - Cross-service communication testing

## Access Patterns

### Via Traefik (Recommended)
- **Service A**: `http://localhost/service-a/` or `http://service-a.localhost/`
- **Service B**: `http://localhost/service-b/` or `http://service-b.localhost/`
- **UI**: `http://localhost/ui/`
- **Traefik Dashboard**: `http://localhost:8080/`

### Direct Access (Development)
- **Service A**: `http://localhost:3000/` (if exposed)
- **Service B**: `http://localhost:5001/` (if exposed)
- **UI**: `http://localhost:3001/` (if exposed)

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Go 1.21+ (for local development)

### Development Setup
```bash
# Clone the repository
git clone <repository-url>
cd multi-service-treafik

# Start the development environment
./scripts/dev-config.sh start

# Or manually configure and start:
./scripts/dev-config.sh config  # Show current config
./scripts/dev-config.sh start   # Start services
```

### Configuration
Edit `scripts/dev-settings.sh` to configure which services run locally vs in Docker:

```bash
# Set to 'true' to run locally in IDE, 'false' to run in Docker
export SERVICE_A_LOCAL=false      # Service A: true = IDE, false = Docker
export SERVICE_B_LOCAL=true      # Service B: true = IDE, false = Docker  
export UI_LOCAL=false            # UI: true = IDE, false = Docker
```

## Development

### Flexible Development Environment
The project supports flexible development configurations:

1. **All Docker**: All services run in containers (production-like)
2. **Mixed Mode**: Some services in Docker, others in IDE
3. **All Local**: All services run locally in IDE

### Local Development
For services configured to run locally:

```bash
# Service A (if configured locally)
cd service-a
go run main.go

# Service B (if configured locally)  
cd service-b
go run main.go

# UI (if configured locally)
cd ui
npm install
npm run dev
```

### Building Services
```bash
# Build all services
docker-compose -f docker-compose.generated.yml build

# Build individual services
docker-compose -f docker-compose.generated.yml build service-a
docker-compose -f docker-compose.generated.yml build service-b
docker-compose -f docker-compose.generated.yml build ui
```

### Testing Services
```bash
# Test Service A health
curl http://localhost/service-a/health

# Test Service B health  
curl http://localhost/service-b/health

# Test cross-service communication
curl http://localhost/service-a/call-service-b
```

## UI Features

The React UI provides:

1. **Dashboard**: Real-time monitoring of service health
2. **Service Testing**: Individual endpoint testing for each service
3. **Cross-Service Testing**: Testing communication between services
4. **Modern UI**: Clean, responsive design with real-time updates

## Network Configuration

All services run on a single Docker network (`app-network`) for simplified communication:

- **Traefik**: Routes external traffic to services
- **Service A**: Communicates with Service B via Traefik
- **Service B**: Communicates with Service A via Traefik
- **UI**: Communicates with services via Vite proxy

## Development Scripts

### Available Commands
```bash
./scripts/dev-config.sh config   # Show current configuration
./scripts/dev-config.sh start    # Start development environment
./scripts/dev-config.sh stop     # Stop all services
./scripts/dev-config.sh logs     # View service logs
./scripts/dev-config.sh restart  # Restart all services
./scripts/dev-config.sh clean    # Clean up generated files
./scripts/dev-config.sh help     # Show help
```

### Configuration Presets
The `scripts/dev-settings.sh` file includes several preset configurations:

1. **All Docker** (production-like): All services in containers
2. **Mixed Mode**: Some local, some Docker (current default)
3. **All Local**: All services in IDE for full development
4. **Custom**: Mix and match as needed

## Troubleshooting

### Common Issues

1. **Gateway Timeout**: Restart Traefik to refresh service IP mappings
   ```bash
   docker-compose -f docker-compose.generated.yml restart traefik
   ```

2. **Service Unavailable**: Check service health
   ```bash
   docker-compose -f docker-compose.generated.yml ps
   docker-compose -f docker-compose.generated.yml logs service-a
   ```

3. **UI Not Loading**: Check if UI container is running
   ```bash
   docker-compose -f docker-compose.generated.yml logs ui
   ```

### Health Checks
All services include health checks:
- **Services**: Check `/health` endpoint
- **UI**: Check if server responds on port 3000

### Logs
```bash
# View all logs
docker-compose -f docker-compose.generated.yml logs

# View specific service logs
docker-compose -f docker-compose.generated.yml logs service-a
docker-compose -f docker-compose.generated.yml logs service-b
docker-compose -f docker-compose.generated.yml logs ui
docker-compose -f docker-compose.generated.yml logs traefik
```

## Cleanup

```bash
# Stop and remove containers
docker-compose -f docker-compose.generated.yml down

# Remove all containers, networks, and volumes
docker-compose -f docker-compose.generated.yml down -v

# Remove images
docker-compose -f docker-compose.generated.yml down --rmi all

# Clean up generated files
./scripts/dev-config.sh clean
``` 