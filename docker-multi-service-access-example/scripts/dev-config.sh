#!/bin/bash

# Development Configuration Script
# This script dynamically generates docker-compose file based on configuration

# Source the settings file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/dev-settings.sh"

# Function to display current configuration
show_config() {
    echo "🔧 Current Development Configuration:"
    echo ""
    echo "📦 Services in Docker:"
    if [ "$SERVICE_A_LOCAL" = false ]; then echo "  ✅ Service A"; else echo "  ❌ Service A"; fi
    if [ "$SERVICE_B_LOCAL" = false ]; then echo "  ✅ Service B"; else echo "  ❌ Service B"; fi
    if [ "$UI_LOCAL" = false ]; then echo "  ✅ UI"; else echo "  ❌ UI"; fi
    echo ""
    echo "💻 Services in IDE:"
    if [ "$SERVICE_A_LOCAL" = true ]; then echo "  ✅ Service A (port $SERVICE_A_PORT)"; else echo "  ❌ Service A"; fi
    if [ "$SERVICE_B_LOCAL" = true ]; then echo "  ✅ Service B (port $SERVICE_B_PORT)"; else echo "  ❌ Service B"; fi
    if [ "$UI_LOCAL" = true ]; then echo "  ✅ UI (port $UI_PORT)"; else echo "  ❌ UI"; fi
    echo ""
}

# Function to generate docker-compose file completely dynamically
generate_docker_compose() {
    echo "🔨 Generating docker-compose file dynamically..."
    
    cat > $DOCKER_COMPOSE_FILE << EOF
version: '3.8'

services:
  traefik:
    image: traefik:v3.4.4
    container_name: traefik-dev
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--providers.file.directory=/etc/traefik/dynamic"
      - "--providers.file.watch=true"
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/dynamic:/etc/traefik/dynamic:ro
    networks:
      - app-network
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF

    # Generate Service A definition
    if [ "$SERVICE_A_LOCAL" = "false" ]; then
        cat >> $DOCKER_COMPOSE_FILE << EOF

  service-a:
    build: ./service-a
    container_name: service-a-dev
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.service-a.rule=PathPrefix(\`/service-a\`)"
      - "traefik.http.routers.service-a.entrypoints=web"
      - "traefik.http.services.service-a.loadbalancer.server.port=3000"
      - "traefik.http.middlewares.service-a-stripprefix.stripprefix.prefixes=/service-a"
      - "traefik.http.routers.service-a.middlewares=service-a-stripprefix"
      - "traefik.http.routers.service-a-internal.rule=PathPrefix(\`/service-a-internal\`)"
      - "traefik.http.routers.service-a-internal.entrypoints=web"
      - "traefik.http.services.service-a.loadbalancer.server.port=3000"
      - "traefik.http.middlewares.service-a-internal-stripprefix.stripprefix.prefixes=/service-a-internal"
      - "traefik.http.routers.service-a-internal.middlewares=service-a-internal-stripprefix"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF
    fi

    # Generate Service B definition
    if [ "$SERVICE_B_LOCAL" = "false" ]; then
        cat >> $DOCKER_COMPOSE_FILE << EOF

  service-b:
    build: ./service-b
    container_name: service-b-dev
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.service-b.rule=PathPrefix(\`/service-b\`)"
      - "traefik.http.routers.service-b.entrypoints=web"
      - "traefik.http.services.service-b.loadbalancer.server.port=5001"
      - "traefik.http.middlewares.service-b-stripprefix.stripprefix.prefixes=/service-b"
      - "traefik.http.routers.service-b.middlewares=service-b-stripprefix"
      - "traefik.http.routers.service-b-internal.rule=PathPrefix(\`/service-b-internal\`)"
      - "traefik.http.routers.service-b-internal.entrypoints=web"
      - "traefik.http.services.service-b.loadbalancer.server.port=5001"
      - "traefik.http.middlewares.service-b-internal-stripprefix.stripprefix.prefixes=/service-b-internal"
      - "traefik.http.routers.service-b-internal.middlewares=service-b-internal-stripprefix"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF
    fi

    # Generate UI definition
    if [ "$UI_LOCAL" = "false" ]; then
        cat >> $DOCKER_COMPOSE_FILE << EOF

  ui:
    build: ./ui
    container_name: ui-dev
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.ui.rule=PathPrefix(\`/ui\`)"
      - "traefik.http.routers.ui.entrypoints=web"
      - "traefik.http.services.ui.loadbalancer.server.port=3001"
      - "traefik.http.middlewares.ui-stripprefix.stripprefix.prefixes=/ui"
      - "traefik.http.routers.ui.middlewares=ui-stripprefix"
    networks:
      - app-network
EOF
    fi

    cat >> $DOCKER_COMPOSE_FILE << EOF

networks:
  app-network:
    driver: bridge
EOF

    echo "✅ Generated $DOCKER_COMPOSE_FILE"
}

# Function to create Traefik dynamic configs for local services
create_traefik_configs() {
    echo "🔧 Creating Traefik dynamic configurations for local services..."
    
    mkdir -p traefik/dynamic
    
    # Clean up ALL existing configs first
    rm -f traefik/dynamic/*.yml
    
    # Generate Service A config if running locally
    if [ "$SERVICE_A_LOCAL" = "true" ]; then
        cat > "traefik/dynamic/service-a.yml" << EOF
http:
  routers:
    service-a:
      rule: "PathPrefix(\`/service-a\`)"
      service: "service-a"
      entryPoints:
        - "web"
      middlewares:
        - "service-a-stripprefix"
    
    # Internal routing for Service B to call Service A
    service-a-internal:
      rule: "PathPrefix(\`/service-a-internal\`)"
      service: "service-a-internal"
      entryPoints:
        - "web"
      middlewares:
        - "service-a-internal-stripprefix"
  
  middlewares:
    service-a-stripprefix:
      stripPrefix:
        prefixes:
          - "/service-a"
    
    service-a-internal-stripprefix:
      stripPrefix:
        prefixes:
          - "/service-a-internal"
  
  services:
    service-a:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:$SERVICE_A_PORT"
    
    service-a-internal:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:$SERVICE_A_PORT"
EOF
        echo "✅ Created traefik/dynamic/service-a.yml"
    fi
    
    # Generate Service B config if running locally
    if [ "$SERVICE_B_LOCAL" = "true" ]; then
        cat > "traefik/dynamic/service-b.yml" << EOF
http:
  routers:
    service-b:
      rule: "PathPrefix(\`/service-b\`)"
      service: "service-b"
      entryPoints:
        - "web"
      middlewares:
        - "service-b-stripprefix"
    
    # Internal routing for Service A to call Service B
    service-b-internal:
      rule: "PathPrefix(\`/service-b-internal\`)"
      service: "service-b-internal"
      entryPoints:
        - "web"
      middlewares:
        - "service-b-internal-stripprefix"
  
  middlewares:
    service-b-stripprefix:
      stripPrefix:
        prefixes:
          - "/service-b"
    
    service-b-internal-stripprefix:
      stripPrefix:
        prefixes:
          - "/service-b-internal"
  
  services:
    service-b:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:$SERVICE_B_PORT"
    
    service-b-internal:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:$SERVICE_B_PORT"
EOF
        echo "✅ Created traefik/dynamic/service-b.yml"
    fi
    
    # Generate UI config if running locally
    if [ "$UI_LOCAL" = "true" ]; then
        cat > "traefik/dynamic/ui.yml" << EOF
http:
  routers:
    ui:
      rule: "PathPrefix(\`/ui\`)"
      service: "ui"
      entryPoints:
        - "web"
      middlewares:
        - "ui-stripprefix"
  
  middlewares:
    ui-stripprefix:
      stripPrefix:
        prefixes:
          - "/ui"
  
  services:
    ui:
      loadBalancer:
        servers:
          - url: "http://host.docker.internal:$UI_PORT"
EOF
        echo "✅ Created traefik/dynamic/ui.yml"
    fi
    
    # Generate internal routing configs for Docker services
    # Service A internal routing (for Service B to call Service A)
    if [ "$SERVICE_A_LOCAL" = "false" ]; then
        # Don't create file-based config for Docker services - they use Docker labels
        echo "ℹ️  Service A is in Docker - using Docker labels for routing"
    fi
    
    # Service B internal routing (for Service A to call Service B)
    if [ "$SERVICE_B_LOCAL" = "false" ]; then
        # Don't create file-based config for Docker services - they use Docker labels
        echo "ℹ️  Service B is in Docker - using Docker labels for routing"
    fi
    
    # If no local services, create empty config to avoid Traefik errors
    if [ "$SERVICE_A_LOCAL" = "false" ] && [ "$SERVICE_B_LOCAL" = "false" ] && [ "$UI_LOCAL" = "false" ]; then
        cat > "traefik/dynamic/empty.yml" << EOF
# Empty config for when all services run in Docker
http:
  routers: {}
  middlewares: {}
  services: {}
EOF
        echo "ℹ️  Created empty config (all services in Docker)"
    fi
}

# Function to start services
start_services() {
    echo "🚀 Starting development environment..."
    
    # Stop any existing containers
    echo "🛑 Stopping existing containers..."
    docker-compose -f $DOCKER_COMPOSE_FILE down 2>/dev/null || true
    
    # Generate docker-compose file
    generate_docker_compose
    
    # Create Traefik configs for local services
    create_traefik_configs
    
    # Build and start services
    echo "🔨 Building and starting services..."
    docker-compose -f $DOCKER_COMPOSE_FILE up --build -d
    
    # Wait for services to be ready
    echo "⏳ Waiting for services to be ready..."
    sleep 10
    
    # Check service health
    echo "🏥 Checking service health..."
    
    # Check Service A
    if [ "$SERVICE_A_LOCAL" = false ]; then
        if curl -f http://localhost/service-a/health > /dev/null 2>&1; then
            echo "✅ Service A (Docker) is healthy"
        else
            echo "❌ Service A (Docker) health check failed"
        fi
    else
        echo "ℹ️  Service A is configured to run locally"
    fi
    
    # Check Service B
    if [ "$SERVICE_B_LOCAL" = false ]; then
        if curl -f http://localhost/service-b/health > /dev/null 2>&1; then
            echo "✅ Service B (Docker) is healthy"
        else
            echo "❌ Service B (Docker) health check failed"
        fi
    else
        echo "ℹ️  Service B is configured to run locally"
    fi
    
    # Check UI
    if [ "$UI_LOCAL" = false ]; then
        if curl -f http://localhost/ui > /dev/null 2>&1; then
            echo "✅ UI (Docker) is accessible"
        else
            echo "❌ UI (Docker) health check failed"
        fi
    else
        echo "ℹ️  UI is configured to run locally"
    fi
    
    echo ""
    echo "🎉 Development environment is ready!"
    echo ""
    show_access_info
}

# Function to show access information
show_access_info() {
    echo "📊 Access your services:"
    echo ""
    
    if [ "$SERVICE_A_LOCAL" = true ]; then
        echo "🔧 Service A (Local IDE):"
        echo "  - Direct: http://localhost:$SERVICE_A_PORT"
        echo "  - Via Traefik: http://localhost/service-a"
    else
        echo "🔧 Service A (Docker):"
        echo "  - Via Traefik: http://localhost/service-a"
    fi
    
    if [ "$SERVICE_B_LOCAL" = true ]; then
        echo "🔧 Service B (Local IDE):"
        echo "  - Direct: http://localhost:$SERVICE_B_PORT"
        echo "  - Via Traefik: http://localhost/service-b"
    else
        echo "🔧 Service B (Docker):"
        echo "  - Via Traefik: http://localhost/service-b"
    fi
    
    if [ "$UI_LOCAL" = true ]; then
        echo "📊 UI (Local IDE):"
        echo "  - Direct: http://localhost:$UI_PORT"
        echo "  - Via Traefik: http://localhost/ui"
    else
        echo "📊 UI (Docker):"
        echo "  - Via Traefik: http://localhost/ui"
    fi
    
    echo ""
    echo "📈 Traefik Dashboard: http://localhost:8080"
    echo ""
    
    echo "💡 Next steps for local services:"
    if [ "$SERVICE_A_LOCAL" = true ]; then
        echo "  - Open service-a directory in your IDE"
        echo "  - Run: cd service-a && go run main.go"
    fi
    
    if [ "$SERVICE_B_LOCAL" = true ]; then
        echo "  - Open service-b directory in your IDE"
        echo "  - Run: cd service-b && go run main.go"
    fi
    
    if [ "$UI_LOCAL" = true ]; then
        echo "  - Open ui directory in your IDE"
        echo "  - Run: cd ui && npm run dev"
    fi
    
    echo ""
    echo "🔧 Management commands:"
    echo "  - View logs: docker-compose -f $DOCKER_COMPOSE_FILE logs"
    echo "  - Restart: docker-compose -f $DOCKER_COMPOSE_FILE restart <service>"
    echo "  - Stop all: docker-compose -f $DOCKER_COMPOSE_FILE down"
    echo ""
}

# Main script logic
case "${1:-}" in
    "config")
        show_config
        ;;
    "start")
        start_services
        ;;
    "stop")
        echo "🛑 Stopping all services..."
        docker-compose -f $DOCKER_COMPOSE_FILE down
        echo "✅ Services stopped"
        ;;
    "logs")
        docker-compose -f $DOCKER_COMPOSE_FILE logs -f
        ;;
    "restart")
        echo "🔄 Restarting services..."
        docker-compose -f $DOCKER_COMPOSE_FILE restart
        echo "✅ Services restarted"
        ;;
    "clean")
        echo "🧹 Cleaning up generated files..."
        rm -f $DOCKER_COMPOSE_FILE
        rm -rf traefik/dynamic
        echo "✅ Cleaned up generated files"
        ;;
    "help"|"")
        echo "🚀 Multi-Service Development Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  config   - Show current configuration"
        echo "  start    - Start development environment"
        echo "  stop     - Stop all services"
        echo "  logs     - View service logs"
        echo "  restart  - Restart all services"
        echo "  clean    - Clean up generated files"
        echo "  help     - Show this help"
        echo ""
        echo "Configuration:"
        echo "  Edit scripts/dev-settings.sh to change which services run locally vs in Docker"
        echo "  Set SERVICE_A_LOCAL, SERVICE_B_LOCAL, UI_LOCAL to true/false"
        echo ""
        show_config
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac 