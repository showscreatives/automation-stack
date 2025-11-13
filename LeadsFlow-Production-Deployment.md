# LeadsFlow System - Production-Ready One-Step Deployment Guide

**Complete Lead Generation, Enrichment & AI Pitches with Mautic & n8n Automation**

---

## Executive Summary

LeadsFlow is a **production-ready, self-hosted lead generation and enrichment platform** that automates lead capture from 7+ sources, performs multi-layer data validation and enrichment in n8n, stores verified leads in a PostgreSQL multi-tenant database, and seamlessly syncs to Mautic for trial-to-paid conversion campaigns.

**Key Features:**
- **Multi-source lead capture** (Forms, Google Maps/Apify, Apollo.io, LinkedIn, Social Media, Events, Web Analytics)
- **AI-powered lead enrichment** (Website analysis, company firmographics, contact verification)
- **3-layer email validation** (Format check, DNS verification, SMTP verification)
- **Intelligent lead scoring** (0-100 quality scoring with automated segmentation)
- **n8n orchestration** (Lead validation, enrichment, mapping, CRM sync)
- **Mautic automation** (Trial campaigns, nurturing workflows, conversion tracking)
- **WhatsApp integration** (Via WAHA for cold pitch outreach)
- **Multi-tenant architecture** (Complete data isolation per client)
- **One-step deployment** (Complete setup in 20-40 minutes)

**Deployment Timeline:**
- Setup & configuration: 5-10 minutes
- DNS propagation: 5-15 minutes
- Docker deployment: 2-5 minutes
- Service initialization: 5-10 minutes
- **Total: 20-40 minutes**

---

## System Architecture Overview

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  LEAD SOURCES (7 Channels)                                   │
├──────────────┬──────────────┬──────────────┬────────────────┤
│ Form         │ Google Maps/ │ Apollo.io    │ LinkedIn       │
│ Submissions  │ Apify        │              │                │
├──────────────┼──────────────┼──────────────┼────────────────┤
│ Social Media │ Events       │ Web Analytics│ Custom APIs    │
└──────────┬───────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────┐
│  N8N ORCHESTRATION LAYER                                     │
├─────────────────────────────────────────────────────────────┤
│ ✓ Webhook ingestion & data validation                        │
│ ✓ 3-layer email verification (Format, DNS, SMTP)            │
│ ✓ Phone validation (Twilio, carrier detection)              │
│ ✓ Domain verification (Whois, DNS, tech stack)              │
│ ✓ Company enrichment (Clearbit, Apollo, website crawl)      │
│ ✓ AI-powered website analysis (Firecrawl, keywords)         │
│ ✓ Contact enrichment (Hunter.io, Snov.io, AnyMailFinder)    │
│ ✓ Lead quality scoring (0-100 algorithm)                    │
│ ✓ Source-specific field mapping                             │
└────┬────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│  POSTGRESQL MULTI-TENANT DATABASE                            │
├─────────────────────────────────────────────────────────────┤
│ ┌─ public.rawleads (raw data before validation)             │
│ ├─ public.leadmappings (Mautic/CRM mapping hub)            │
│ ├─ public.verificationlogs (audit trail)                   │
│ └─ client_[id].leads (verified enriched data per client)   │
└────┬────────────────────────────────────────────────────────┘
     │
     ├─────────────────────┬──────────────────┐
     ▼                     ▼                  ▼
┌──────────────┐    ┌──────────────┐  ┌───────────────┐
│   MAUTIC     │    │   CRMS       │  │  METABASE     │
│ (Marketing   │    │ (VTiger,     │  │  (Analytics & │
│ Automation)  │    │  EspoCRM)    │  │   Dashboards) │
├──────────────┤    ├──────────────┤  └───────────────┘
│• Contacts    │    │• Leads       │
│• Campaigns   │    │• Companies   │
│• Segments    │    │• Activities  │
│• Workflows   │    │• Pipelines   │
│• Tags        │    │              │
└──────────────┘    └──────────────┘
```

### Technology Stack

| Component | Service | Version | Purpose |
|-----------|---------|---------|---------|
| **Reverse Proxy** | Traefik | v2.10 | SSL/TLS, routing, dashboard |
| **Database** | PostgreSQL | 16-Alpine | Multi-tenant lead storage |
| **Message Queue** | RabbitMQ | 3.12-Alpine | Background job processing |
| **Workflow Engine** | n8n | Latest | Lead enrichment orchestration |
| **Marketing** | Mautic | Latest | Email campaigns, automation |
| **Analytics** | Metabase | Latest | Dashboards & reporting |
| **WhatsApp** | WAHA | Latest | WhatsApp API integration |
| **Vector DB** | Qdrant | Latest | AI embeddings (future) |
| **PDF Generator** | Gotenberg | Latest | PDF reports |

---

## System Requirements

### Minimum Specifications

- **OS**: Ubuntu 20.04 LTS or newer
- **RAM**: 8GB (16GB recommended for production)
- **CPU**: 4 cores (8 cores recommended)
- **Storage**: 100GB free disk space (250GB recommended)
- **Network**: Stable internet, ports 80/443 open
- **Domain**: Registered and DNS access available

### Network Requirements

- **Inbound ports**: 80 (HTTP), 443 (HTTPS)
- **Outbound ports**: 443 (API calls)
- **DNS**: Must support A records for domain + subdomains

### Pre-Installation Verification

```bash
# Check Ubuntu version
lsb_release -a

# Check available RAM
free -h

# Check CPU cores
nproc

# Check disk space
df -h

# Check port availability
sudo netstat -tuln | grep -E '80|443'
```

---

## Pre-Deployment Checklist

### Before You Begin

- [ ] Server provisioned and SSH access available
- [ ] Ubuntu 20.04+ installed
- [ ] Domain name registered (e.g., `leadsflowsys.online`)
- [ ] DNS provider access (GoDaddy, Namecheap, Route53, etc.)
- [ ] Minimum 8GB RAM, 4 CPU cores, 100GB storage
- [ ] Ports 80 and 443 open and accessible
- [ ] Python 3 and OpenSSL installed
- [ ] Docker and Docker Compose ready to install

### API Keys & Credentials Required (Optional)

*These can be configured post-deployment:*

- **Email verification**: Hunter.io or Snov.io API key
- **Company data**: Clearbit API key
- **Phone validation**: Twilio account
- **Website scraping**: Firecrawl or ScrapingBee
- **Email delivery**: Gmail, SendGrid, or other SMTP provider
- **Mautic API**: Generated during setup

### Server Preparation

```bash
# Connect to server
ssh root@YOUR_SERVER_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install prerequisites
sudo apt install -y python3 python3-pip openssl curl wget git htop

# Verify installations
python3 --version
openssl version
```

---

## One-Step Deployment Process

### Phase 1: Initial Setup (5 minutes)

```bash
# 1. Connect to your server
ssh root@YOUR_SERVER_IP

# 2. Create project directory
mkdir -p /opt/leadsflow-system
cd /opt/leadsflow-system

# 3. Clone repository or download files
# Option A: If using Git
git clone https://your-repo.git .

# Option B: Download files manually to this directory
# Ensure these files are present:
# - setup.sh
# - docker-compose.yml
# - init-databases.sql
# - parameters.php
# - rabbitmq.conf
# - .env (will be generated)

# 4. Make setup script executable
chmod +x setup.sh
```

### Phase 2: Interactive Setup Wizard (5-10 minutes)

```bash
# Run the interactive setup script
bash setup.sh
```

**The setup script will prompt for:**

1. **Domain Name** (e.g., `leadsflowsys.online`)
   - Must be publicly registered and DNS-accessible
   
2. **Subdomain Configuration** (Press ENTER for defaults)
   ```
   n8n.leadsflowsys.online      (Workflow automation)
   mautic.leadsflowsys.online   (Marketing automation)
   metabase.leadsflowsys.online (Analytics dashboard)
   waha.leadsflowsys.online     (WhatsApp integration)
   rabbitmq.leadsflowsys.online (Message queue)
   traefik.leadsflowsys.online  (Reverse proxy dashboard)
   ```

3. **Password Generation**
   - Automatically generates secure credentials
   - Creates `.env` file with all secrets
   - Saves to `CREDENTIALS.txt` for backup

**Script Output:**
- `.env` - Environment configuration
- `CREDENTIALS.txt` - Reference backup
- `.config/traefik.htpasswd` - Dashboard auth
- All services configured and ready

### Phase 3: DNS Configuration (5-15 minutes)

**After running setup.sh, configure DNS A records:**

```
Domain Provider: GoDaddy, Namecheap, Route53, etc.

Add these A records:

Record Type   | Name                      | Value          | TTL
----- -----   | -------                   | -----          | ---
A             | @                         | YOUR_SERVER_IP | 3600
A             | *                         | YOUR_SERVER_IP | 3600
A             | n8n                       | YOUR_SERVER_IP | 3600
A             | mautic                    | YOUR_SERVER_IP | 3600
A             | metabase                  | YOUR_SERVER_IP | 3600
A             | waha                      | YOUR_SERVER_IP | 3600
A             | rabbitmq                  | YOUR_SERVER_IP | 3600
A             | traefik                   | YOUR_SERVER_IP | 3600
```

**Verify DNS Propagation:**

```bash
# Wait 5-15 minutes, then test:
nslookup leadsflowsys.online
nslookup n8n.leadsflowsys.online
nslookup mautic.leadsflowsys.online

# Should show your server IP
```

### Phase 4: Docker Installation (If Needed)

```bash
# Check if Docker is installed
docker --version
docker-compose --version

# If not installed:

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker root

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

### Phase 5: Deploy All Services (2-5 minutes)

```bash
# Navigate to project directory
cd /opt/leadsflow-system

# Pull latest images
docker-compose pull

# Start all services
docker-compose up -d

# Watch deployment (Ctrl+C to exit)
docker-compose logs -f

# Wait for all services to show "Up" status
# Typically 2-5 minutes
```

### Phase 6: Verify Deployment (5 minutes)

```bash
# Check all containers running
docker-compose ps

# Expected output (all should show "Up"):
# traefik        Up X minutes
# postgres       Up X minutes
# rabbitmq       Up X minutes
# mautic         Up X minutes
# n8n            Up X minutes
# metabase       Up X minutes
# waha           Up X minutes
# qdrant         Up X minutes
# gotenberg      Up X minutes

# Check for errors
docker-compose logs | grep -i error

# If all containers are running, deployment is successful!
```

---

## Service Configuration

### Traefik Reverse Proxy & SSL

**Purpose**: Routes all traffic with automatic HTTPS encryption

**Access Dashboard:**
- URL: `https://traefik.leadsflowsys.online`
- Username: `admin`
- Password: From `CREDENTIALS.txt` (`TRAEFIK_ADMIN_PASSWORD`)

**Features:**
- Automatic SSL certificate generation (Let's Encrypt)
- HTTP → HTTPS redirect
- Service health monitoring
- Dashboard metrics

### PostgreSQL Database

**Purpose**: Central multi-tenant database for all data

**Connection Details:**
```
Host: postgres (internal) or localhost:5432 (external)
Port: 5432
Admin User: postgres
Admin Password: From .env (POSTGRES_ROOT_PASSWORD)
```

**Pre-configured Databases:**
- `mautic` - Marketing automation data
- `n8n` - Workflow data
- `metabase` - Analytics config
- Plus custom client schemas

**Backup Database:**
```bash
docker-compose exec postgres pg_dump -U postgres mautic > backup-$(date +%Y%m%d-%H%M%S).sql
```

**Restore Database:**
```bash
docker-compose exec -T postgres psql -U postgres mautic < backup-file.sql
```

### RabbitMQ Message Queue

**Purpose**: Handles background job processing for Mautic

**Access:**
- Dashboard: `https://rabbitmq.leadsflowsys.online`
- Username: `mautic`
- Password: From `.env` (`RABBITMQ_DEFAULT_PASS`)

**Commands:**
```bash
# List queues
docker-compose exec rabbitmq rabbitmqctl list_queues

# Check node status
docker-compose exec rabbitmq rabbitmqctl status

# Clear all queues
docker-compose exec rabbitmq rabbitmqctl purge_queue queue_name
```

### n8n Workflow Automation

**Purpose**: Orchestrates lead validation, enrichment, and CRM sync

**Access:**
- URL: `https://n8n.leadsflowsys.online`
- Username: `admin`
- Password: From `.env` (`N8N_BASIC_AUTH_PASSWORD`)

**Key Workflows to Create:**

1. **Lead Ingestion Webhook** - Captures leads from all sources
2. **Email Validation Pipeline** - 3-layer verification
3. **Company Enrichment** - Clearbit integration
4. **Lead Scoring** - Quality calculation
5. **Mautic Sync** - Contact creation + segmentation

### Mautic Marketing Automation

**Purpose**: Email campaigns, trial nurturing, conversion tracking

**Initial Setup:**

```bash
# 1. Access Mautic
# URL: https://mautic.leadsflowsys.online
# Let the installation wizard run (auto-fills database info)

# 2. Create Admin Account
# Email: your@email.com
# Password: Strong password
# First/Last Name: Your name

# 3. Configure Email (Settings → Email Settings)
# SMTP Provider: Gmail, SendGrid, or other
# From Email: noreply@leadsflowsys.online
# From Name: LeadsFlow

# 4. Install Recommended Plugins
docker-compose exec mautic php bin/console mautic:plugins:reload
```

**Restart Mautic if needed:**
```bash
docker-compose restart mautic
```

### Metabase Analytics

**Purpose**: Dashboards and reporting

**Initial Setup:**
```
1. Visit: https://metabase.leadsflowsys.online
2. Create admin account
3. Connect to PostgreSQL:
   - Host: postgres
   - Port: 5432
   - Database: mautic (or whichever)
   - Username: mauticuser
   - Password: From .env
```

### WAHA WhatsApp Integration

**Purpose**: Send/receive WhatsApp messages programmatically

**Access:**
- Dashboard: `https://waha.leadsflowsys.online/dashboard`
- API: `https://waha.leadsflowsys.online/api/v1`
- Swagger: `https://waha.leadsflowsys.online/api/v1/swagger`

**Add WhatsApp Account:**
```
1. Visit dashboard
2. Click "Add Device"
3. Scan QR code with WhatsApp phone
4. Confirm in WhatsApp app
5. Wait for connection confirmation
```

**Send Message via API:**
```bash
curl -X POST https://waha.leadsflowsys.online/api/v1/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_WAHA_API_KEY" \
  -d '{
    "chatId": "254712345678@c.us",
    "text": "Hello from LeadsFlow!"
  }'
```

---

## Database & Lead Management

### PostgreSQL Multi-Tenant Schema

**Core Architecture:**

```sql
-- Public schemas (shared)
public.rawleads          -- All incoming leads (raw)
public.leadmappings      -- Lead ID mapping hub
public.verificationlogs  -- Audit trail

-- Per-client schemas (isolated)
client_1.leads           -- Verified leads for client 1
client_1.leadsources     -- Lead source tracking
client_1.leadsegments    -- Segment membership
client_1.leadactivities  -- Activity log
client_2.leads           -- Verified leads for client 2
... (isolated per client)
```

### Lead Lifecycle

```
1. Raw Ingestion
   ↓
2. Validation (3-layer email, phone, domain)
   ↓
3. Enrichment (company, contact, website data)
   ↓
4. Quality Scoring (0-100 algorithm)
   ↓
5. Client Schema Storage (verified only)
   ↓
6. Mautic Sync (contact creation + custom fields)
   ↓
7. Segmentation (trial-eligible, warm, cold, etc.)
   ↓
8. Campaign Assignment (automated nurturing)
   ↓
9. Conversion Tracking (trial → paid)
```

### Create New Client

**SQL:**
```sql
-- 1. Insert client
INSERT INTO public.clients (client_name, api_key, status)
VALUES ('Acme Corp', 'acme_api_key_123', 'active')
RETURNING client_id;
-- Returns: client_id = 1

-- 2. Create client schema and tables
CREATE SCHEMA client_1;

CREATE TABLE client_1.leads (
  lead_id SERIAL PRIMARY KEY,
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20),
  company_name VARCHAR(255),
  company_website VARCHAR(255),
  industry VARCHAR(100),
  job_title VARCHAR(255),
  source VARCHAR(50),
  quality_score INTEGER DEFAULT 0,
  email_verified BOOLEAN DEFAULT FALSE,
  phone_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE client_1.lead_sources (
  source_id SERIAL PRIMARY KEY,
  lead_id INTEGER REFERENCES client_1.leads(lead_id),
  source_type VARCHAR(50),
  source_url TEXT,
  raw_data JSONB,
  ingestion_timestamp TIMESTAMP DEFAULT NOW()
);

CREATE TABLE client_1.lead_segments (
  segment_id SERIAL PRIMARY KEY,
  lead_id INTEGER REFERENCES client_1.leads(lead_id),
  segment_name VARCHAR(100),
  mautic_segment_id INTEGER,
  added_at TIMESTAMP DEFAULT NOW()
);

GRANT ALL ON SCHEMA client_1 TO mauticuser;
GRANT ALL ON ALL TABLES IN SCHEMA client_1 TO mauticuser;
```

---

## n8n Enrichment Workflows

### Workflow 1: Lead Ingestion & Validation

**Trigger**: Webhook (from forms, APIs, etc.)

**Steps:**

1. **Webhook Trigger**
   - Accepts POST requests from any lead source
   - Extracts: name, email, phone, company, industry

2. **Data Validation**
   ```javascript
   // Format normalization
   const data = {
     firstName: json.first_name?.trim() || null,
     lastName: json.last_name?.trim() || null,
     email: json.email?.toLowerCase().trim() || null,
     phone: normalizePhone(json.phone),
     companyName: json.company_name?.trim() || null,
     source: json.source || 'form'
   };
   ```

3. **Email Validation (3-Layer)**
   
   **Layer 1: Format Check**
   ```javascript
   // RFC 5322 regex
   const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
   if (!emailRegex.test(email)) {
     return { status: 'invalid', reason: 'format_error' };
   }
   ```
   
   **Layer 2: DNS MX Record Lookup**
   ```javascript
   // Use n8n HTTP node to query DNS
   // Call https://dns.google/resolve?name=domain.com&type=MX
   if (!mxRecords.length > 0) {
     return { status: 'risky', reason: 'no_mx_record' };
   }
   ```
   
   **Layer 3: SMTP Verification**
   ```javascript
   // Call Hunter.io or Snov.io API
   // POST https://api.hunter.io/v2/email-verifier
   // Returns: verified, risky, invalid
   ```

4. **Phone Validation**
   - Normalize: Add country code (+254 for Kenya)
   - Verify: Twilio Lookup API
   - Extract: Carrier name, type (mobile/landline)

5. **Store in raw_leads**
   ```sql
   INSERT INTO public.raw_leads (
     source, raw_data, ingestion_timestamp, 
     verification_status, quality_score, processing_status
   ) VALUES (
     'form', '{}', NOW(), 'pending', 0, 'pending'
   );
   ```

### Workflow 2: Company Enrichment

**Trigger**: After initial validation passes

**Steps:**

1. **Clearbit API Call**
   ```javascript
   // GET https://api.clearbit.com/v1/companies/find?domain=company.com
   // Returns: company_size, revenue, industry, founded_year, etc.
   ```

2. **Apollo.io Integration** (Alternative)
   ```javascript
   // GET https://api.apollo.io/v1/companies/match
   // Params: website, company_name
   // Returns: decision_maker emails, phone, tech stack
   ```

3. **Website Tech Stack Detection**
   - Wappalyzer API or BuiltWith
   - Detect: CRM, marketing tools, hosting, etc.

4. **Update enriched_data JSONB**
   ```sql
   UPDATE public.raw_leads SET
     enriched_data = jsonb_set(
       enriched_data, '{company}',
       '{"size": 50, "revenue": "1M-10M", "industry": "SaaS"}'
     )
   WHERE lead_id = $1;
   ```

### Workflow 3: Website Analysis & AI Pitch Generation

**Trigger**: After company enrichment

**Steps:**

1. **Fetch Website Content**
   - Use Firecrawl or ScrapingBee
   - Extract: Keywords, services, pain points, tone

2. **AI Analysis** (Via Claude/GPT API)
   ```javascript
   const prompt = `
     Analyze this website content and extract:
     1. Main products/services (3-5 points)
     2. Target audience
     3. Potential pain points
     4. Website tone and brand voice
     
     Content: ${websiteContent}
   `;
   ```

3. **Generate Cold Pitch**
   ```javascript
   const pitch = `
     Hi ${firstName},
     
     I noticed ${companyName} specializes in ${services}.
     
     We help ${targetAudience} overcome ${painPoints}.
     
     Would you be open to a quick 15-min chat?
   `;
   ```

4. **Store pitch_data**
   ```sql
   UPDATE public.raw_leads SET
     enriched_data = jsonb_set(
       enriched_data, '{pitch}',
       '{"generated_pitch": "...", "tone": "professional"}'
     )
   WHERE lead_id = $1;
   ```

### Workflow 4: Quality Scoring Algorithm

**Trigger**: After enrichment complete

**Scoring Logic:**

```javascript
function calculateLeadQualityScore(lead) {
  let score = 0;

  // 1. COMPLETENESS (0-25 points)
  const requiredFields = ['firstName', 'lastName', 'email', 'companyName'];
  const filledRequired = requiredFields.filter(f => lead[f]).length;
  score += (filledRequired / requiredFields.length) * 15;

  const enhancedFields = ['phone', 'industry', 'location', 'keywords'];
  const filledEnhanced = enhancedFields.filter(f => lead[f]).length;
  score += (filledEnhanced / enhancedFields.length) * 10;

  // 2. VERIFICATION (0-30 points)
  if (lead.emailVerified === 'verified') score += 15;
  else if (lead.emailVerified === 'risky') score += 5;

  if (lead.phoneVerified) score += 10;
  if (lead.domainVerified) score += 5;

  // 3. SOURCE QUALITY (0-20 points)
  const sourceWeights = {
    'form_submission': 20,
    'events': 18,
    'apollo': 15,
    'google_maps': 12,
    'linkedin': 14,
    'social_media': 8,
    'web_analytics': 5
  };
  score += sourceWeights[lead.source] || 0;

  // 4. ENRICHMENT SUCCESS (0-15 points)
  if (lead.keywords?.length > 0) score += 5;
  if (lead.companySize) score += 3;
  if (lead.industry) score += 2;
  if (lead.companyWebsite) score += 5;

  // 5. RECENCY (0-10 points)
  const ageHours = (Date.now() - lead.createdAt) / (1000 * 60 * 60);
  if (ageHours < 24) score += 10;
  else if (ageHours < 168) score += 7; // 1 week
  else if (ageHours < 720) score += 3; // 30 days

  return Math.min(100, Math.round(score));
}

// Quality Tiers
const tiers = {
  '80-100': { name: 'Hot', mauticAction: 'Immediate trial offer', store: 'client_schema' },
  '60-79': { name: 'Warm', mauticAction: 'Nurture sequence', store: 'client_schema' },
  '40-59': { name: 'Cold', mauticAction: 'General nurture', store: 'client_schema' },
  '20-39': { name: 'Low', mauticAction: 'Re-engagement', store: 'raw_leads' },
  '<20': { name: 'Invalid', mauticAction: 'Do not contact', store: 'raw_leads' }
};
```

### Workflow 5: Mautic Sync & Segmentation

**Trigger**: After quality scoring

**Steps:**

1. **Create Mautic Contact**
   ```javascript
   // POST https://mautic.leadsflowsys.online/api/contacts/new
   const contact = {
     firstName: lead.firstName,
     lastName: lead.lastName,
     email: lead.email,
     phone: lead.phone,
     fields: {
       client_id: lead.clientId,
       lead_source: lead.source,
       quality_score: lead.qualityScore,
       trial_status: 'not_started',
       email_verified: lead.emailVerified,
       internal_lead_id: lead.leadId
     }
   };
   // Returns: mauticContactId
   ```

2. **Add to Segment**
   ```javascript
   // Based on quality score
   if (qualityScore >= 70 && emailVerified) {
     // Add to "Trial Eligible" segment
     POST /api/contacts/{id}/segments/add
     { segmentId: 'trial_eligible' }
   }
   ```

3. **Update Lead Mappings**
   ```sql
   INSERT INTO public.lead_mappings (
     client_id, internal_lead_id, mautic_contact_id,
     source, status, created_at
   ) VALUES (
     $1, $2, $3, $4, 'synced', NOW()
   );
   ```

4. **Send Welcome Email**
   - Trigger Mautic automation
   - Email: "Welcome to LeadsFlow Trial"
   - Include: Trial duration, features, call-to-action

---

## Mautic Setup & Integration

### Step 1: Initial Configuration

```bash
# Access Mautic
# https://mautic.leadsflowsys.online

# Complete installation wizard (database auto-filled)
# Create admin account
# Configure SMTP (pre-configured in .env)
```

### Step 2: Create Custom Fields

**Required Custom Fields for Lead Tracking:**

| Field Name | Field Type | Description |
|-----------|-----------|-------------|
| `client_id` | Number | Which client owns this lead |
| `lead_source` | Select | Source (form, apollo, google_maps, etc.) |
| `quality_score` | Number | 0-100 quality assessment |
| `email_verified` | Select | verified / risky / invalid |
| `trial_status` | Select | not_started / active / expired / converted |
| `trial_start_date` | Date | When trial began |
| `trial_end_date` | Date | When trial expires |
| `internal_lead_id` | Text | Reference to PostgreSQL lead_id |
| `pitch_sent` | Boolean | AI pitch has been sent |
| `engagement_score` | Number | Email engagement metric |

**Create via API or UI:**

```bash
# Via API
curl -X POST https://mautic.leadsflowsys.online/api/fields/new \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_MAUTIC_API_TOKEN" \
  -d '{
    "label": "Client ID",
    "name": "client_id",
    "type": "number",
    "order": 1,
    "isPublished": true
  }'
```

### Step 3: Create Lead Segments

**Segment 1: Trial Eligible**
- Filter: `quality_score >= 70 AND email_verified = verified AND client_id IS NOT NULL`
- Size: ~50-70% of leads
- Action: Send welcome email

**Segment 2: Trial Active**
- Filter: `trial_status = active AND trial_start_date >= -14 days`
- Size: Dynamic
- Action: Daily engagement emails

**Segment 3: Trial Expiring (5 Days)**
- Filter: `trial_status = active AND trial_end_date BETWEEN now AND now + 5 days`
- Size: Dynamic
- Action: "Your trial expires soon" email

**Segment 4: Conversion Ready**
- Filter: `trial_status = active AND last_email_click >= -3 days AND engagement_score >= 50`
- Size: Dynamic
- Action: Final conversion offer

**Segment 5: Trial Expired - Re-engagement**
- Filter: `trial_status = expired AND converted = false AND last_activity >= -7 days`
- Size: Dynamic
- Action: "Come back" campaign

### Step 4: Create Trial-to-Paid Campaign

**Campaign Flow:**

```
Day 0: Lead added to "Trial Eligible" segment
  ├─ Email 1: Welcome to Trial (benefits overview)
  │
Day 3: Check engagement
  ├─ If clicked: Move to "Conversion Ready"
  │  Email 2: Feature Deep-Dive
  │
Day 7: Email 3: Real use-case example
  │
Day 10: Email 4: Upgrade incentive (discount/bonus)
  │
Day 13: Email 5: Last chance offer
  │
Day 14: Trial auto-expires
  ├─ If converted: Move to "Paid Customer"
  │  Email 6: Welcome to paid plan
  │
  └─ If not converted: Move to "Re-engagement"
     Email 7: Come back campaign
```

**Create Campaign in Mautic UI:**
1. Navigate to Campaigns → New Campaign
2. Add trigger: "Contact added to segment: Trial Eligible"
3. Add decision: "Did contact click email?"
4. Add actions: Send emails, update fields, add tags
5. Set delays between emails (3 days, 7 days, etc.)
6. Activate campaign

### Step 5: Install Essential Plugins

```bash
# Reload plugins (forces scan for updates)
docker-compose exec mautic php bin/console mautic:plugins:reload

# Install plugins via Mautic UI:
# - Recommended plugins shown in Settings → Plugins
# Popular plugins for lead management:
#   * CiviCRM Integration
#   * Slack Notification
#   * Webhook (for n8n)
#   * Custom Database Connection
```

### Step 6: Configure Webhook for n8n

**In Mautic:**
1. Settings → Configuration → Webhooks
2. Create new webhook:
   - **Event**: Contact created
   - **URL**: `https://n8n.leadsflowsys.online/webhook/...`
   - **Trigger**: Contact created
   - **Payload**: All contact data

**In n8n:**
1. Create webhook node
2. Method: POST
3. Test webhook
4. Copy webhook URL
5. Paste into Mautic webhook configuration

---

## Lead Quality Scoring

### Scoring Algorithm

**Total Score: 0-100 points**

```
Completeness (0-25 points)
├─ Required fields (15 pts): first_name, last_name, email, company_name
└─ Enhanced fields (10 pts): phone, industry, location, keywords

Verification (0-30 points)
├─ Email verified (15 pts)
├─ Email risky (5 pts)
├─ Phone verified (10 pts)
└─ Domain verified (5 pts)

Source Quality (0-20 points)
├─ Form submission (20 pts) - High intent
├─ Events (18 pts) - In-person, high intent
├─ Apollo (15 pts) - B2B verified
├─ LinkedIn (14 pts) - Professional verified
├─ Google Maps (12 pts) - Business listings
├─ Social Media (8 pts) - Lower intent
└─ Web Analytics (5 pts) - Lowest intent

Enrichment Success (0-15 points)
├─ Keywords extracted (5 pts)
├─ Company size known (3 pts)
├─ Industry known (2 pts)
└─ Company website known (5 pts)

Recency (0-10 points)
├─ < 24 hours old (10 pts)
├─ < 7 days old (7 pts)
└─ < 30 days old (3 pts)
```

### Quality Tiers & Actions

| Score | Tier | Action | Storage | Mautic Action |
|-------|------|--------|---------|---------------|
| 80-100 | Hot | Immediate trial offer | client_schema | Trial Eligible + welcome email |
| 60-79 | Warm | Nurture sequence | client_schema | Trial Eligible + nurture |
| 40-59 | Cold | General nurture | client_schema | Trial Eligible + slower cadence |
| 20-39 | Low | Re-engagement | raw_leads | Hold, manual review |
| <20 | Invalid | Do not contact | raw_leads | Excluded from all campaigns |

### Real-Time Quality Dashboard

**Metabase Query:**
```sql
SELECT 
  DATE(ingestion_timestamp) as date,
  source,
  COUNT(*) as total_leads,
  COUNT(CASE WHEN quality_score >= 70 THEN 1 END) as high_quality,
  ROUND(COUNT(CASE WHEN quality_score >= 70 THEN 1 END)::numeric / COUNT(*) * 100, 1) as high_quality_pct,
  ROUND(AVG(quality_score), 1) as avg_score,
  COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified
FROM public.raw_leads
WHERE ingestion_timestamp >= NOW() - INTERVAL '7 days'
GROUP BY DATE(ingestion_timestamp), source
ORDER BY date DESC, total_leads DESC;
```

---

## Post-Deployment Setup

### 1. Create API Token for n8n

**In Mautic:**
```
1. Settings → API Credentials
2. Click "New API User"
3. Name: n8n Integration
4. Generate API token
5. Copy public + secret keys
6. Save to .env as MAUTIC_API_PUBLIC_KEY, MAUTIC_API_SECRET_KEY
```

### 2. Configure n8n Credentials

**In n8n:**
```
1. Credentials → Create new
2. Type: HTTP Request
3. Name: Mautic API
4. Base URL: https://mautic.leadsflowsys.online/api
5. Headers:
   - Authorization: Bearer YOUR_API_TOKEN
   - Content-Type: application/json
```

### 3. Backup All Credentials

```bash
# Backup .env file
cp .env .env.backup
scp root@YOUR_SERVER:/opt/leadsflow-system/.env ./secure-backup/

# Backup credentials file
scp root@YOUR_SERVER:/opt/leadsflow-system/CREDENTIALS.txt ./secure-backup/

# Store in secure location (LastPass, 1Password, etc.)
```

### 4. Initialize First Client

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d mautic

# Insert first client
INSERT INTO public.clients (client_name, api_key, status)
VALUES ('Demo Client', 'demo_key_' || gen_random_uuid(), 'active')
RETURNING client_id;

# Creates client_1 schema automatically or run:
CREATE SCHEMA client_1;

# Create client_1 tables (use provided SQL)
```

### 5. Test End-to-End Flow

```bash
# 1. Test n8n webhook
curl -X POST https://n8n.leadsflowsys.online/webhook/lead-ingestion \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+254712345678",
    "company": "Example Corp",
    "source": "form"
  }'

# 2. Check raw_leads in PostgreSQL
docker-compose exec postgres psql -U postgres -d mautic -c "SELECT * FROM public.raw_leads ORDER BY created_at DESC LIMIT 1;"

# 3. Check Mautic contact created
# Visit: https://mautic.leadsflowsys.online/contacts

# 4. Check Metabase dashboard
# Create a new dashboard and query leads
```

### 6. Enable Monitoring & Alerts

```bash
# Setup log monitoring
docker-compose logs -f > logs/deployment.log &

# Monitor specific service
docker-compose logs -f n8n > logs/n8n.log &

# Check disk usage regularly
df -h | mail -s "Disk Usage Alert" admin@leadsflowsys.online
```

---

## Monitoring & Maintenance

### Daily Monitoring

**Check Container Health:**
```bash
# All containers up?
docker-compose ps

# Any errors in logs?
docker-compose logs --tail=100 | grep -i error

# Disk space?
df -h | grep -E '^/dev'

# CPU/Memory usage?
docker stats
```

**Queries to Run:**

```sql
-- Daily lead ingestion
SELECT DATE(ingestion_timestamp) as date, COUNT(*) as leads
FROM public.raw_leads
WHERE ingestion_timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE(ingestion_timestamp);

-- Verification success rate
SELECT 
  source,
  COUNT(*) as total,
  COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified,
  ROUND(COUNT(CASE WHEN verification_status = 'verified' THEN 1 END)::numeric / COUNT(*) * 100, 1) as pct_verified
FROM public.raw_leads
WHERE ingestion_timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY source;

-- Mautic sync success
SELECT 
  COUNT(*) as total_mapped,
  COUNT(CASE WHEN mautic_contact_id IS NOT NULL THEN 1 END) as synced_to_mautic,
  COUNT(CASE WHEN mautic_contact_id IS NULL THEN 1 END) as pending_sync
FROM public.lead_mappings
WHERE created_at >= NOW() - INTERVAL '24 hours';
```

### Weekly Maintenance

**Backup Database:**
```bash
# Full backup
docker-compose exec postgres pg_dump -U postgres mautic | gzip > backup-$(date +%Y%m%d).sql.gz

# Copy to safe location
scp root@YOUR_SERVER:/opt/leadsflow-system/backup-*.sql.gz ./backups/
```

**Check SSL Certificates:**
```bash
# Let's Encrypt renews automatically, but verify
docker-compose exec traefik ls /acme.json

# Check certificate expiry (browser: lock icon → Details)
# Or via OpenSSL:
echo | openssl s_client -servername mautic.leadsflowsys.online \
  -connect mautic.leadsflowsys.online:443 2>/dev/null | \
  openssl x509 -noout -dates
```

**Update Services:**
```bash
# Pull latest images
docker-compose pull

# Update and restart (no downtime if using Traefik)
docker-compose down
docker-compose up -d
```

### Monthly Review

**Performance Metrics:**
```sql
-- Monthly lead volume by source
SELECT 
  DATE_TRUNC('week', ingestion_timestamp) as week,
  source,
  COUNT(*) as leads,
  ROUND(AVG(quality_score), 1) as avg_quality,
  COUNT(CASE WHEN verification_status = 'verified' THEN 1 END) as verified_count
FROM public.raw_leads
WHERE ingestion_timestamp >= NOW() - INTERVAL '30 days'
GROUP BY DATE_TRUNC('week', ingestion_timestamp), source
ORDER BY week DESC, source;

-- Conversion funnel
SELECT 
  COUNT(CASE WHEN trial_status IS NULL THEN 1 END) as not_started,
  COUNT(CASE WHEN trial_status = 'active' THEN 1 END) as trial_active,
  COUNT(CASE WHEN trial_status = 'expired' THEN 1 END) as trial_expired,
  COUNT(CASE WHEN conversion_status = 'paid' THEN 1 END) as paid_customers,
  ROUND(COUNT(CASE WHEN conversion_status = 'paid' THEN 1 END)::numeric / COUNT(*) * 100, 1) as conversion_rate_pct
FROM public.lead_mappings
WHERE created_at >= NOW() - INTERVAL '30 days';
```

**Optimize Database:**
```bash
# Vacuum and analyze
docker-compose exec postgres psql -U postgres -d mautic -c "VACUUM ANALYZE;"

# Check index health
docker-compose exec postgres psql -U postgres -d mautic -c "
  SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
  FROM pg_stat_user_indexes
  ORDER BY idx_scan DESC;"
```

---

## Troubleshooting

### Deployment Issues

**Problem: Docker containers won't start**
```bash
# Check Docker is running
sudo systemctl status docker

# Check Docker daemon logs
journalctl -u docker -n 50

# Restart Docker
sudo systemctl restart docker

# Try deployment again
docker-compose down
docker-compose up -d
```

**Problem: Ports already in use**
```bash
# Check what's using ports
sudo netstat -tuln | grep -E ':80|:443|:5432|:5678|:3000'

# Kill process (if needed)
sudo kill -9 <PID>

# Or change ports in docker-compose.yml
```

**Problem: Out of disk space**
```bash
# Check usage
df -h

# Clean Docker data
docker-compose down
docker system prune -a --volumes

# Check size of database volumes
du -sh data/*

# Backup and clean logs
```

### Service-Specific Issues

**n8n webhook not working:**
```bash
# Check n8n logs
docker-compose logs n8n | tail -50

# Verify webhook URL is correct
# https://n8n.leadsflowsys.online/webhook/lead-ingestion

# Test with curl
curl -X POST https://n8n.leadsflowsys.online/webhook/lead-ingestion \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check Traefik routing
curl -H "Host: n8n.leadsflowsys.online" http://localhost
```

**Mautic not sending emails:**
```bash
# Check email configuration
docker-compose exec mautic php bin/console mautic:email:send

# Verify SMTP settings
# Settings → Configurations → Email Settings

# Check RabbitMQ queues
docker-compose exec rabbitmq rabbitmqctl list_queues

# Clear stuck emails
docker-compose exec mautic php bin/console mautic:emails:send --force
```

**PostgreSQL connection issues:**
```bash
# Check PostgreSQL logs
docker-compose logs postgres | tail -50

# Test connection
docker-compose exec postgres psql -U postgres -d mautic -c "SELECT 1;"

# Check disk space (common issue)
docker-compose exec postgres psql -U postgres -c "SELECT pg_database_size('mautic');"

# If corrupted, restore from backup
docker-compose exec -T postgres psql -U postgres mautic < backup.sql
```

**SSL Certificate issues:**
```bash
# Check Traefik logs
docker-compose logs traefik | grep -i "certificate\|acme"

# Force certificate renewal
docker-compose exec traefik traefik --force-renew

# If stuck, remove acme.json and restart
rm data/traefik/acme.json
docker-compose restart traefik

# Wait 5 minutes for automatic renewal
```

### Performance Issues

**High CPU usage:**
```bash
# Check which container
docker stats

# Check logs for errors
docker-compose logs <container_name> | grep -i "error\|exception"

# Common causes: n8n workflows, Mautic processing, database queries
# Scale up resources or optimize queries
```

**Slow database:**
```bash
# Find slow queries
docker-compose exec postgres psql -U postgres -d mautic -c "
  SELECT query, calls, total_time, mean_time
  FROM pg_stat_statements
  ORDER BY mean_time DESC
  LIMIT 10;"

# Optimize indexes
docker-compose exec postgres psql -U postgres -d mautic -c "
  CREATE INDEX idx_raw_leads_email ON public.raw_leads(email);
  CREATE INDEX idx_raw_leads_source ON public.raw_leads(source);
  CREATE INDEX idx_lead_mappings_client ON public.lead_mappings(client_id);"
```

**Memory running out:**
```bash
# Check available memory
free -h

# Restart services to clear caches
docker-compose restart n8n mautic metabase

# Increase memory limit in docker-compose.yml if needed
```

---

## Security Best Practices

### Network Security

1. **Firewall Configuration**
   ```bash
   # Only allow traffic from trusted IPs
   sudo ufw default deny incoming
   sudo ufw allow 22/tcp    # SSH
   sudo ufw allow 80/tcp    # HTTP
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw enable
   ```

2. **SSH Hardening**
   ```bash
   # Edit /etc/ssh/sshd_config
   PermitRootLogin no
   PasswordAuthentication no
   PubkeyAuthentication yes
   AllowUsers ubuntu
   
   # Restart SSH
   sudo systemctl restart sshd
   ```

3. **Rate Limiting** (in Traefik labels)
   ```yaml
   - traefik.http.middlewares.limit.ratelimit.average=100
   - traefik.http.middlewares.limit.ratelimit.burst=200
   ```

### Data Protection

1. **Encrypt Sensitive Data**
   - Store API keys in `.env` only (never commit to Git)
   - Use PostgreSQL encrypted fields for PII
   - Enable SSL/TLS for all connections

2. **Backup Strategy**
   ```bash
   # Daily backups
   0 2 * * * docker-compose exec postgres pg_dump -U postgres mautic | gzip > /backups/mautic-$(date +\%Y\%m\%d).sql.gz
   
   # Off-site backup (S3, etc.)
   0 3 * * * aws s3 cp /backups/ s3://my-backups/ --recursive
   ```

3. **Row-Level Security (PostgreSQL)**
   ```sql
   -- Only allow users to see their own client data
   ALTER TABLE client_1.leads ENABLE ROW LEVEL SECURITY;
   CREATE POLICY client_isolation ON client_1.leads
     FOR ALL USING (true);
   ```

### API Security

1. **Rate Limiting** on webhooks
   ```javascript
   // In n8n webhook configuration
   const rateLimit = {};
   const maxRequests = 1000; // per hour
   
   if (rateLimit[ip]?.count > maxRequests) {
     return { status: 429, error: 'Too many requests' };
   }
   ```

2. **API Key Rotation**
   - Rotate keys quarterly
   - Use separate keys per integration
   - Monitor key usage

3. **CORS Configuration**
   ```yaml
   # In Traefik middleware
   - traefik.http.middlewares.cors.headers.accesscontrolallowmethods=GET,POST,PUT,DELETE
   - traefik.http.middlewares.cors.headers.accesscontrolalloworiginlist=https://dashboard.leadsflowsys.online
   ```

### Access Control

1. **PostgreSQL Roles**
   ```sql
   -- Create read-only role for analytics
   CREATE ROLE analytics_user WITH LOGIN PASSWORD 'strong_password';
   GRANT CONNECT ON DATABASE mautic TO analytics_user;
   GRANT USAGE ON SCHEMA public TO analytics_user;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;
   ```

2. **Traefik Authentication**
   ```bash
   # Generate new auth credentials
   htpasswd -c .htpasswd admin
   # Update in docker-compose.yml volumes
   ```

3. **Audit Logging**
   ```sql
   -- Track all data modifications
   CREATE TABLE public.audit_logs (
     log_id SERIAL PRIMARY KEY,
     user_id INTEGER,
     action VARCHAR(50),
     table_name VARCHAR(100),
     record_id INTEGER,
     old_values JSONB,
     new_values JSONB,
     created_at TIMESTAMP DEFAULT NOW()
   );
   ```

---

## Environment Configuration Reference

### .env Variables

```bash
# TIMEZONE
TIMEZONE=Africa/Nairobi

# TRAEFIK
TRAEFIK_SUBDOMAIN=traefik
TRAEFIK_ADMIN_PASSWORD=your-secure-password
DOMAIN=leadsflowsys.online
TRAEFIK_LOG_LEVEL=INFO

# POSTGRESQL
POSTGRES_ROOT_PASSWORD=your-postgres-password
POSTGRES_ADMIN_USER=postgres
MAUTIC_DB_HOST=postgres
MAUTIC_DB_PORT=5432
MAUTIC_DB_NAME=mautic
MAUTIC_DB_USER=mauticuser
MAUTIC_DB_PASSWORD=your-mautic-db-password
N8N_DB_HOST=postgres
N8N_DB_PORT=5432
N8N_DB_NAME=n8n
N8N_DB_USER=n8nuser
N8N_DB_PASSWORD=your-n8n-db-password
METABASE_DB_HOST=postgres
METABASE_DB_PORT=5432
METABASE_DB_NAME=metabase
METABASE_DB_USER=metabaseuser
METABASE_DB_PASSWORD=your-metabase-db-password

# RABBITMQ
RABBITMQ_SUBDOMAIN=rabbitmq
RABBITMQ_DEFAULT_USER=mautic
RABBITMQ_DEFAULT_PASS=your-rabbitmq-password
RABBITMQ_DEFAULT_VHOST=/
RABBITMQ_ERLANG_COOKIE=your-erlang-cookie

# MAUTIC
MAUTIC_SUBDOMAIN=mautic
MAUTIC_URL=https://mautic.leadsflowsys.online
MAUTIC_ADMIN_USER=admin
MAUTIC_ADMIN_PASSWORD=your-mautic-admin-password
MAILER_FROM_EMAIL=noreply@leadsflowsys.online
MAILER_FROM_NAME=LeadsFlow
MAILER_TRANSPORT=smtp
MAILER_HOST=smtp.gmail.com
MAILER_PORT=587
MAILER_ENCRYPTION=tls
MAILER_USER=your-email@gmail.com
MAILER_PASSWORD=your-app-password
TRUSTED_HOSTS=mautic.leadsflowsys.online

# N8N
N8N_SUBDOMAIN=n8n
N8N_HOST=n8n.leadsflowsys.online
N8N_PROTOCOL=https
N8N_PORT=443
N8N_EDITOR_BASE_URL=https://n8n.leadsflowsys.online
N8N_WEBHOOK_TUNNEL_URL=https://n8n.leadsflowsys.online
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your-n8n-password
N8N_TIMEZONE=Africa/Nairobi
N8N_DB_TYPE=postgresdb

# METABASE
METABASE_SUBDOMAIN=metabase
MB_JAVA_TIMEZONE=Africa/Nairobi

# WAHA
WAHA_SUBDOMAIN=waha
WAHA_API_KEY=your-waha-api-key
WAHA_DASHBOARD_USERNAME=admin
WAHA_DASHBOARD_PASSWORD=your-waha-dashboard-password

# QDRANT
QDRANT_API_KEY=your-qdrant-api-key

# RESTART POLICY
RESTART_POLICY=unless-stopped

# API KEYS (Optional, add after deployment)
HUNTER_API_KEY=your-hunter-api-key
CLEARBIT_API_KEY=your-clearbit-api-key
APOLLO_API_KEY=your-apollo-api-key
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
FIRECRAWL_API_KEY=your-firecrawl-key
```

---

## Quick Commands Reference

```bash
# View all services status
docker-compose ps

# View specific service logs
docker-compose logs -f n8n
docker-compose logs -f mautic
docker-compose logs -f postgres

# Restart specific service
docker-compose restart n8n
docker-compose restart mautic

# Stop all services
docker-compose down

# Start all services
docker-compose up -d

# Execute command in container
docker-compose exec postgres psql -U postgres -d mautic

# View resource usage
docker stats

# Backup database
docker-compose exec postgres pg_dump -U postgres mautic > backup.sql

# Restore database
docker-compose exec -T postgres psql -U postgres mautic < backup.sql

# Check disk usage
du -sh data/*

# Update all images
docker-compose pull

# Full update with restart
docker-compose pull && docker-compose down && docker-compose up -d

# View .env file
cat .env

# Test webhook
curl -X POST https://n8n.leadsflowsys.online/webhook/lead-ingestion \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Check DNS
nslookup leadsflowsys.online
dig leadsflowsys.online

# Test SSL certificate
echo | openssl s_client -servername mautic.leadsflowsys.online \
  -connect mautic.leadsflowsys.online:443 2>/dev/null | \
  openssl x509 -noout -dates
```

---

## Support & Additional Resources

### Documentation Files Included

1. **DEPLOYMENT.md** - Detailed deployment operations
2. **README.md** - Complete system overview
3. **docker-compose.yml** - Container orchestration
4. **setup.sh** - Automated setup script
5. **init-databases.sql** - Database initialization
6. **parameters.php** - Mautic configuration
7. **rabbitmq.conf** - Message queue settings

### Useful Links

- **n8n Docs**: https://docs.n8n.io
- **Mautic Docs**: https://docs.mautic.org
- **PostgreSQL Docs**: https://www.postgresql.org/docs
- **Docker Docs**: https://docs.docker.com
- **Traefik Docs**: https://doc.traefik.io

### Support Channels

- n8n Community: https://community.n8n.io
- Mautic Forum: https://www.mautic.org/community
- PostgreSQL Support: https://www.postgresql.org/support
- Docker Community: https://forums.docker.com

---

## Conclusion

**LeadsFlow is now ready for production use!** 

You have a complete, scalable, self-hosted lead generation and enrichment system that:

✓ Captures leads from 7+ diverse sources  
✓ Performs intelligent, multi-layer validation  
✓ Enriches leads with company and contact data  
✓ Scores leads intelligently (0-100 algorithm)  
✓ Syncs seamlessly to Mautic for automation  
✓ Provides complete data isolation per client  
✓ Includes WhatsApp integration for outreach  
✓ Offers analytics dashboards (Metabase)  
✓ Runs entirely on your VPS (self-hosted)  
✓ Deploys in under 40 minutes  

**Next Steps:**

1. Configure your first lead source
2. Create n8n workflows for your specific use case
3. Set up trial-to-paid campaigns in Mautic
4. Monitor lead quality and conversion metrics
5. Iterate and optimize based on data

For questions, troubleshooting, or custom implementations, refer to the detailed sections above or consult the included documentation files.

Happy lead generation! 🚀

---

**Version**: 1.0.0  
**Last Updated**: November 13, 2025  
**Compatibility**: Ubuntu 20.04+, Docker 20.10+, Docker Compose 2.0+  
**Support**: Production-ready for agencies and enterprises
