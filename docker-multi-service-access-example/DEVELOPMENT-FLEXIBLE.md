# Flexible Development Environment

## Overview

This project now uses a **dynamic docker-compose generation** approach that eliminates the need for multiple static docker-compose files. The system automatically generates the appropriate configuration based on your development preferences.

## Why This Approach?

### Before (Static Files)
- ❌ `docker-compose.yml` - All services in Docker
- ❌ `docker-compose.dev-mixed.yml` - Mixed local/Docker setup
- ❌ Confusing which file to use
- ❌ Manual maintenance of multiple files

### After (Dynamic Generation)
- ✅ Single script generates everything
- ✅ Configuration-driven approach
- ✅ Easy to switch between setups
- ✅ No static files to maintain

## How It Works

### 1. Configuration (`scripts/dev-settings.sh`)
```bash
# Set which services run locally vs in Docker
export SERVICE_A_LOCAL=false      # Docker
export SERVICE_B_LOCAL=true      # Local IDE
export UI_LOCAL=false            # Docker
```

### 2. Dynamic Generation (`scripts/dev-config.sh`)
The script:
- Reads configuration from `dev-settings.sh`
- Generates `docker-compose.generated.yml` dynamically
- Creates Traefik configs for local services
- Starts the environment

### 3. Flexible Options
You can configure any combination:
- **All Docker**: Production-like environment
- **All Local**: Full IDE development
- **Mixed**: Some local, some Docker (current default)

## Usage

### Quick Start
```bash
# Show current configuration
./scripts/dev-config.sh config

# Start development environment
./scripts/dev-config.sh start

# Stop all services
./scripts/dev-config.sh stop
```

### Configuration Presets
Edit `scripts/dev-settings.sh` to use these presets:

#### Preset 1: All Docker (Production-like)
```bash
export SERVICE_A_LOCAL=false
export SERVICE_B_LOCAL=false
export UI_LOCAL=false
```

#### Preset 2: Mixed Mode (Current)
```bash
export SERVICE_A_LOCAL=false
export SERVICE_B_LOCAL=true
export UI_LOCAL=false
```

#### Preset 3: All Local (Full IDE)
```bash
export SERVICE_A_LOCAL=true
export SERVICE_B_LOCAL=true
export UI_LOCAL=true
```

## Benefits

### 🎯 **Simplicity**
- One script handles everything
- No confusion about which file to use
- Clear configuration in one place

### 🔄 **Flexibility**
- Easy to switch between setups
- Mix local and Docker services
- Perfect for different development scenarios

### 🛠️ **Maintainability**
- No static files to maintain
- Configuration-driven approach
- Easy to extend with new services

### 🚀 **Developer Experience**
- Clear commands and feedback
- Automatic health checks
- Helpful error messages

## Commands

| Command | Description |
|---------|-------------|
| `config` | Show current configuration |
| `start` | Start development environment |
| `stop` | Stop all services |
| `logs` | View service logs |
| `restart` | Restart all services |
| `clean` | Clean up generated files |
| `help` | Show help |

## Generated Files

The script generates these files dynamically:
- `docker-compose.generated.yml` - Docker Compose configuration
- `traefik/dynamic/*.yml` - Traefik dynamic configurations for local services

## Local Development

When services are configured to run locally:

### Service A (Go)
```bash
cd service-a
go run main.go
```

### Service B (Go)
```bash
cd service-b
go run main.go
```

### UI (React)
```bash
cd ui
npm install
npm run dev
```

## Access Points

### Via Traefik (Recommended)
- Service A: `http://localhost/service-a`
- Service B: `http://localhost/service-b`
- UI: `http://localhost/ui`
- Traefik Dashboard: `http://localhost:8080`

### Direct Access (Local Services)
- Service A: `http://localhost:3000` (if local)
- Service B: `http://localhost:5001` (if local)
- UI: `http://localhost:3001` (if local)

## Troubleshooting

### Common Issues

1. **Port Conflicts**: Check if local ports are already in use
2. **Service Not Found**: Ensure local services are running
3. **Traefik Issues**: Restart Traefik container

### Debug Commands
```bash
# Check configuration
./scripts/dev-config.sh config

# View logs
./scripts/dev-config.sh logs

# Clean and restart
./scripts/dev-config.sh clean
./scripts/dev-config.sh start
```

## Migration from Static Files

If you were using the old static files:

1. **Remove old files**: Already done automatically
2. **Use new commands**: `./scripts/dev-config.sh start`
3. **Configure settings**: Edit `scripts/dev-settings.sh`
4. **Enjoy simplicity**: One script handles everything!

## Future Extensions

The dynamic approach makes it easy to add:
- New services
- Different environments (staging, testing)
- Custom configurations
- Additional development tools

Just update the configuration and the script handles the rest! 