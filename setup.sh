#!/bin/bash

#########################################
# LeadsFlow System - One-Step Setup Script
# Production-Ready Deployment Automation
#########################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

#########################################
# PHASE 1: Pre-Deployment Checks
#########################################

print_status "========== LeadsFlow Setup Script =========="
print_status "Checking system requirements..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
   print_error "This script must be run as root (use: sudo bash setup.sh)"
   exit 1
fi

# Check OS
if ! grep -q "Ubuntu" /etc/os-release; then
    print_warning "This script is optimized for Ubuntu. Your OS may not be supported."
fi

# Check disk space
DISK_AVAILABLE=$(df /opt 2>/dev/null | tail -1 | awk '{print $4}')
if [ "$DISK_AVAILABLE" -lt 100000000 ]; then
    print_error "Insufficient disk space. Need 100GB, have $(($DISK_AVAILABLE / 1024 / 1024))GB"
    exit 1
fi
print_success "Disk space check passed"

# Check RAM
RAM_AVAILABLE=$(free -m | awk 'NR==2 {print $2}')
if [ "$RAM_AVAILABLE" -lt 8000 ]; then
    print_warning "Recommended 8GB RAM, but you have ${RAM_AVAILABLE}MB. This may affect performance."
fi
print_success "RAM check passed (${RAM_AVAILABLE}MB)"

# Check CPU cores
CPU_CORES=$(nproc)
print_success "CPU cores: $CPU_CORES"

# Check ports
print_status "Checking if ports 80 and 443 are available..."
if netstat -tuln 2>/dev/null | grep -q ":80 " || netstat -tuln 2>/dev/null | grep -q ":443 "; then
    print_error "Ports 80 and/or 443 are already in use"
    exit 1
fi
print_success "Ports 80 and 443 are available"

#########################################
# PHASE 2: Prompt for Configuration
#########################################

print_status ""
print_status "========== Configuration Setup =========="

# Get domain name
print_status "Enter your domain name (e.g., leadsflowsys.online):"
read -p "> " DOMAIN

if [ -z "$DOMAIN" ]; then
    print_error "Domain cannot be empty"
    exit 1
fi

print_success "Domain set to: $DOMAIN"

# Get server IP
SERVER_IP=$(curl -s https://api.ipify.org)
if [ -z "$SERVER_IP" ]; then
    # Fallback to hostname if API call fails
    SERVER_IP=$(hostname -I | awk '{print $1}')
fi

print_status "Detected server IP: $SERVER_IP"
print_status "Please ensure your DNS provider has these A records:"
print_status "  @ A $SERVER_IP"
print_status "  * A $SERVER_IP"
read -p "Press ENTER after configuring DNS records..."

# Generate secure passwords
print_status ""
print_status "Generating secure credentials..."

POSTGRES_ROOT_PASSWORD=$(openssl rand -base64 32)
MAUTIC_DB_PASSWORD=$(openssl rand -base64 32)
N8N_DB_PASSWORD=$(openssl rand -base64 32)
METABASE_DB_PASSWORD=$(openssl rand -base64 32)
WAHA_DB_PASSWORD=$(openssl rand -base64 32)
TRAEFIK_ADMIN_PASSWORD=$(openssl rand -base64 12)
RABBITMQ_PASSWORD=$(openssl rand -base64 32)
N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 12)
WAHA_API_KEY=$(openssl rand -hex 32)
WAHA_DASHBOARD_PASSWORD=$(openssl rand -base64 12)
QDRANT_API_KEY=$(openssl rand -hex 32)
RABBITMQ_ERLANG_COOKIE=$(openssl rand -base64 32)

print_success "Passwords generated"

# Create Traefik basic auth
print_status "Creating Traefik authentication..."
mkdir -p config/traefik
echo "admin:$(openssl passwd -apr1 $TRAEFIK_ADMIN_PASSWORD)" > config/traefik/.htpasswd
print_success "Traefik auth configured"

#########################################
# PHASE 3: Create .env File
#########################################

print_status ""
print_status "========== Creating Configuration Files =========="

cat > .env << EOF
# ============================================
# LeadsFlow System - Environment Configuration
# ============================================

# TIMEZONE
TIMEZONE=Africa/Nairobi

# DOMAIN & SUBDOMAINS
DOMAIN=$DOMAIN
TRAEFIK_SUBDOMAIN=traefik
N8N_SUBDOMAIN=n8n
MAUTIC_SUBDOMAIN=mautic
METABASE_SUBDOMAIN=metabase
WAHA_SUBDOMAIN=waha
RABBITMQ_SUBDOMAIN=rabbitmq

# TRAEFIK
TRAEFIK_ADMIN_PASSWORD=$TRAEFIK_ADMIN_PASSWORD
TRAEFIK_LOG_LEVEL=INFO

# POSTGRESQL
POSTGRES_ROOT_PASSWORD=$POSTGRES_ROOT_PASSWORD
POSTGRES_ADMIN_USER=postgres
POSTGRES_DB=postgres

# MAUTIC DB
MAUTIC_DB_HOST=postgres
MAUTIC_DB_PORT=5432
MAUTIC_DB_NAME=mautic
MAUTIC_DB_USER=mauticuser
MAUTIC_DB_PASSWORD=$MAUTIC_DB_PASSWORD

# N8N DB
N8N_DB_HOST=postgres
N8N_DB_PORT=5432
N8N_DB_NAME=n8n
N8N_DB_USER=n8nuser
N8N_DB_PASSWORD=$N8N_DB_PASSWORD
N8N_DB_TYPE=postgresdb

# METABASE DB
METABASE_DB_HOST=postgres
METABASE_DB_PORT=5432
METABASE_DB_NAME=metabase
METABASE_DB_USER=metabaseuser
METABASE_DB_PASSWORD=$METABASE_DB_PASSWORD

# WAHA DB
WAHA_DB_HOST=postgres
WAHA_DB_PORT=5432
WAHA_DB_NAME=waha
WAHA_DB_USER=wahauser
WAHA_DB_PASSWORD=$WAHA_DB_PASSWORD

# RABBITMQ
RABBITMQ_DEFAULT_USER=mautic
RABBITMQ_DEFAULT_PASS=$RABBITMQ_PASSWORD
RABBITMQ_DEFAULT_VHOST=/
RABBITMQ_ERLANG_COOKIE=$RABBITMQ_ERLANG_COOKIE
RABBITMQ_HOST=rabbitmq

# MAUTIC
MAUTIC_URL=https://$MAUTIC_SUBDOMAIN.$DOMAIN
MAUTIC_ADMIN_USER=admin
MAUTIC_ADMIN_PASSWORD=\$(openssl rand -base64 12)
MAILER_FROM_EMAIL=noreply@$DOMAIN
MAILER_FROM_NAME=LeadsFlow
MAILER_TRANSPORT=smtp
MAILER_HOST=smtp.gmail.com
MAILER_PORT=587
MAILER_ENCRYPTION=tls
MAILER_USER=your-email@gmail.com
MAILER_PASSWORD=your-app-password
TRUSTED_HOSTS=$MAUTIC_SUBDOMAIN.$DOMAIN

# N8N
N8N_HOST=$N8N_SUBDOMAIN.$DOMAIN
N8N_PROTOCOL=https
N8N_PORT=443
N8N_EDITOR_BASE_URL=https://$N8N_SUBDOMAIN.$DOMAIN
N8N_WEBHOOK_TUNNEL_URL=https://$N8N_SUBDOMAIN.$DOMAIN
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=$N8N_BASIC_AUTH_PASSWORD
N8N_TIMEZONE=Africa/Nairobi

# METABASE
MB_JAVA_TIMEZONE=Africa/Nairobi

# WAHA
WAHA_API_KEY=$WAHA_API_KEY
WAHA_DASHBOARD_USERNAME=admin
WAHA_DASHBOARD_PASSWORD=$WAHA_DASHBOARD_PASSWORD

# QDRANT
QDRANT_API_KEY=$QDRANT_API_KEY

# DOCKER
RESTART_POLICY=unless-stopped

# API KEYS (Add after deployment)
# HUNTER_API_KEY=
# CLEARBIT_API_KEY=
# APOLLO_API_KEY=
# TWILIO_ACCOUNT_SID=
# TWILIO_AUTH_TOKEN=
# FIRECRAWL_API_KEY=
EOF

print_success ".env file created"

#########################################
# PHASE 4: Create Credentials Backup
#########################################

cat > CREDENTIALS.txt << EOF
# ============================================
# LeadsFlow System - CREDENTIALS BACKUP
# Generated: $(date)
# ============================================

⚠️  IMPORTANT: Keep this file safe! Store in password manager (LastPass, 1Password, etc.)

SERVER INFORMATION
==================
Server IP: $SERVER_IP
Domain: $DOMAIN
SSH Access: ssh root@$SERVER_IP

TRAEFIK DASHBOARD
==================
URL: https://traefik.$DOMAIN
Username: admin
Password: $TRAEFIK_ADMIN_PASSWORD

N8N AUTOMATION
==================
URL: https://n8n.$DOMAIN
Username: admin
Password: $N8N_BASIC_AUTH_PASSWORD

MAUTIC MARKETING
==================
URL: https://mautic.$DOMAIN
Username: admin
Password: (Generated during installation)

METABASE ANALYTICS
==================
URL: https://metabase.$DOMAIN

WAHA WHATSAPP
==================
Dashboard URL: https://waha.$DOMAIN/dashboard
API URL: https://waha.$DOMAIN/api/v1
API Key: $WAHA_API_KEY
Dashboard Username: admin
Dashboard Password: $WAHA_DASHBOARD_PASSWORD

DATABASE CREDENTIALS
==================
Host: postgres (internal) or $SERVER_IP:5432 (external)
Port: 5432
Admin User: postgres
Admin Password: $POSTGRES_ROOT_PASSWORD

Mautic DB: mautic / $MAUTIC_DB_PASSWORD
n8n DB: n8n / $N8N_DB_PASSWORD
Metabase DB: metabase / $METABASE_DB_PASSWORD

RABBITMQ MESSAGE QUEUE
==================
URL: https://rabbitmq.$DOMAIN
Username: mautic
Password: $RABBITMQ_PASSWORD

DNS CONFIGURATION REQUIRED
==================
Add these A records to your DNS provider:

Record Type | Name        | Value      | TTL
============|=============|============|=====
A           | @           | $SERVER_IP | 3600
A           | *           | $SERVER_IP | 3600

Verify propagation (wait 5-15 minutes):
nslookup $DOMAIN
nslookup n8n.$DOMAIN

NEXT STEPS
==================
1. Save this file securely (password manager)
2. Back up the .env file
3. Deploy: docker-compose up -d
4. Wait 5 minutes for all services to start
5. Access dashboards and complete initial setup

DEPLOYMENT COMMAND
==================
cd /opt/leadsflow-system
docker-compose up -d

MONITORING
==================
docker-compose ps          # View status
docker-compose logs -f     # View logs
docker-compose logs -f n8n # View specific service
EOF

print_success "CREDENTIALS.txt created"

#########################################
# PHASE 5: Docker Installation Check
#########################################

print_status ""
print_status "========== Docker Installation Check =========="

if ! command -v docker &> /dev/null; then
    print_warning "Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    print_success "Docker installed"
else
    print_success "Docker already installed: $(docker --version)"
fi

if ! command -v docker-compose &> /dev/null; then
    print_warning "Docker Compose not found. Installing..."
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
else
    print_success "Docker Compose already installed: $(docker-compose --version)"
fi

#########################################
# PHASE 6: Create Directory Structure
#########################################

print_status ""
print_status "========== Creating Directory Structure =========="

mkdir -p data/{postgres,rabbitmq,qdrant,mautic,n8n,metabase,traefik,waha}
mkdir -p config/{traefik,postgres,rabbitmq,mautic}
mkdir -p local-files

print_success "Directories created"

#########################################
# PHASE 7: Summary & Next Steps
#########################################

print_status ""
print_status "========== Setup Summary =========="

echo ""
echo -e "${GREEN}✓ LeadsFlow System setup complete!${NC}"
echo ""
echo "Configuration Details:"
echo "  Domain: $DOMAIN"
echo "  Server IP: $SERVER_IP"
echo "  Timezone: Africa/Nairobi"
echo ""
echo "Next Steps:"
echo "  1. Review .env file configuration"
echo "  2. Backup CREDENTIALS.txt securely"
echo "  3. Configure DNS A records (see above)"
echo "  4. Wait for DNS propagation (5-15 minutes)"
echo "  5. Deploy with: docker-compose up -d"
echo ""
echo "Check Status:"
echo "  docker-compose ps         # All services running?"
echo "  docker-compose logs -f    # Watch startup logs"
echo ""
echo "Access Dashboards:"
echo "  Traefik:  https://traefik.$DOMAIN"
echo "  n8n:      https://n8n.$DOMAIN"
echo "  Mautic:   https://mautic.$DOMAIN"
echo "  Metabase: https://metabase.$DOMAIN"
echo "  WAHA:     https://waha.$DOMAIN/dashboard"
echo ""
echo "Documentation:"
echo "  See LeadsFlow-Production-Deployment.md for detailed setup instructions"
echo ""

print_success "Setup script completed!"
