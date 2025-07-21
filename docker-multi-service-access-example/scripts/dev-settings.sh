#!/bin/bash

# Development Settings
# Modify these variables to configure which services run locally vs in Docker

# Service Configuration
# Set to 'true' to run locally in IDE, 'false' to run in Docker
export SERVICE_A_LOCAL=false      # Service A: true = IDE, false = Docker
export SERVICE_B_LOCAL=true      # Service B: true = IDE, false = Docker  
export UI_LOCAL=false            # UI: true = IDE, false = Docker

# Port Configuration for Local Services
export SERVICE_A_PORT=3000       # Port for Service A when running locally
export SERVICE_B_PORT=5001       # Port for Service B when running locally (changed from 5000 to avoid AirPlay conflict)
export UI_PORT=3001              # Port for UI when running locally

# Docker Configuration
export DOCKER_COMPOSE_FILE="docker-compose.generated.yml"

# Common Configurations
# Uncomment one of these presets or create your own:

# Preset 1: All services in Docker (production-like)
# export SERVICE_A_LOCAL=false
# export SERVICE_B_LOCAL=false
# export UI_LOCAL=false

# Preset 2: Service A local, others in Docker
# export SERVICE_A_LOCAL=true
# export SERVICE_B_LOCAL=false
# export UI_LOCAL=false

# Preset 3: All services local (full IDE development)
# export SERVICE_A_LOCAL=true
# export SERVICE_B_LOCAL=true
# export UI_LOCAL=true

# Preset 4: Services local, UI in Docker
# export SERVICE_A_LOCAL=true
# export SERVICE_B_LOCAL=true
# export UI_LOCAL=false

# Preset 5: Service A and UI local, Service B in Docker
# export SERVICE_A_LOCAL=true
# export SERVICE_B_LOCAL=false
# export UI_LOCAL=true 