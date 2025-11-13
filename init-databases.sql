-- =====================================================
-- LeadsFlow System - PostgreSQL Initialization Script
-- Multi-tenant Lead Management Database
-- =====================================================

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- =====================================================
-- PUBLIC SCHEMAS (Shared Across All Clients)
-- =====================================================

-- =====================================================
-- 1. Clients Management
-- =====================================================

CREATE TABLE public.clients (
    client_id SERIAL PRIMARY KEY,
    client_name VARCHAR(255) NOT NULL UNIQUE,
    api_key UUID NOT NULL UNIQUE DEFAULT uuid_generate_v4(),
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    max_leads_per_month INTEGER DEFAULT 10000,
    trial_period_days INTEGER DEFAULT 14,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_clients_status ON public.clients(status);
CREATE INDEX idx_clients_api_key ON public.clients(api_key);

-- =====================================================
-- 2. Raw Lead Ingestion (Before Validation)
-- =====================================================

CREATE TABLE public.raw_leads (
    lead_id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES public.clients(client_id) ON DELETE CASCADE,
    source VARCHAR(50) NOT NULL DEFAULT 'form',
    raw_data JSONB NOT NULL,
    ingestion_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    verification_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'risky', 'invalid')),
    quality_score INTEGER DEFAULT 0 CHECK (quality_score >= 0 AND quality_score <= 100),
    processing_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'complete', 'failed')),
    error_message TEXT,
    processed_at TIMESTAMP,
    stored_in_client_schema BOOLEAN DEFAULT FALSE,
    enriched_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_raw_leads_client_id ON public.raw_leads(client_id);
CREATE INDEX idx_raw_leads_source ON public.raw_leads(source);
CREATE INDEX idx_raw_leads_verification_status ON public.raw_leads(verification_status);
CREATE INDEX idx_raw_leads_quality_score ON public.raw_leads(quality_score);
CREATE INDEX idx_raw_leads_ingestion_timestamp ON public.raw_leads(ingestion_timestamp);
CREATE INDEX idx_raw_leads_processing_status ON public.raw_leads(processing_status);

-- =====================================================
-- 3. Lead ID Mapping Hub (Integration IDs)
-- =====================================================

CREATE TABLE public.lead_mappings (
    mapping_id SERIAL PRIMARY KEY,
    client_id INTEGER NOT NULL REFERENCES public.clients(client_id) ON DELETE CASCADE,
    internal_lead_id INTEGER NOT NULL REFERENCES public.raw_leads(lead_id) ON DELETE CASCADE,
    source VARCHAR(50) NOT NULL,
    mautic_contact_id INTEGER,
    crm_lead_id INTEGER,
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    domain_verified BOOLEAN DEFAULT FALSE,
    quality_score INTEGER DEFAULT 0,
    sync_status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (sync_status IN ('pending', 'synced', 'failed', 'partial')),
    conversion_status VARCHAR(50) DEFAULT 'new' CHECK (conversion_status IN ('new', 'trial', 'paid', 'churned')),
    last_sync_at TIMESTAMP,
    sync_error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    next_retry_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lead_mappings_client_id ON public.lead_mappings(client_id);
CREATE INDEX idx_lead_mappings_internal_lead_id ON public.lead_mappings(internal_lead_id);
CREATE INDEX idx_lead_mappings_mautic_contact_id ON public.lead_mappings(mautic_contact_id);
CREATE INDEX idx_lead_mappings_sync_status ON public.lead_mappings(sync_status);
CREATE INDEX idx_lead_mappings_conversion_status ON public.lead_mappings(conversion_status);

-- =====================================================
-- 4. Verification Audit Trail
-- =====================================================

CREATE TABLE public.verification_logs (
    log_id SERIAL PRIMARY KEY,
    lead_id INTEGER NOT NULL REFERENCES public.raw_leads(lead_id) ON DELETE CASCADE,
    verification_type VARCHAR(50) NOT NULL CHECK (verification_type IN ('email_format', 'dns_lookup', 'smtp_verify', 'phone_verify', 'domain_verify')),
    status VARCHAR(50) NOT NULL CHECK (status IN ('verified', 'risky', 'invalid', 'failed')),
    verification_value VARCHAR(255),
    api_provider VARCHAR(100),
    api_response JSONB,
    error_message TEXT,
    verification_timestamp TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verification_logs_lead_id ON public.verification_logs(lead_id);
CREATE INDEX idx_verification_logs_verification_type ON public.verification_logs(verification_type);
CREATE INDEX idx_verification_logs_status ON public.verification_logs(status);

-- =====================================================
-- 5. Lead Processing Error Tracking
-- =====================================================

CREATE TABLE public.sync_errors (
    error_id SERIAL PRIMARY KEY,
    lead_id INTEGER NOT NULL REFERENCES public.raw_leads(lead_id) ON DELETE CASCADE,
    error_type VARCHAR(100) NOT NULL,
    error_message TEXT NOT NULL,
    stacktrace TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    next_retry_at TIMESTAMP,
    resolution_status VARCHAR(50) DEFAULT 'open' CHECK (resolution_status IN ('open', 'resolved', 'ignored')),
    resolved_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sync_errors_lead_id ON public.sync_errors(lead_id);
CREATE INDEX idx_sync_errors_error_type ON public.sync_errors(error_type);
CREATE INDEX idx_sync_errors_resolution_status ON public.sync_errors(resolution_status);

-- =====================================================
-- 6. API Key Management for n8n & Integrations
-- =====================================================

CREATE TABLE public.api_credentials (
    credential_id SERIAL PRIMARY KEY,
    client_id INTEGER REFERENCES public.clients(client_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    credential_type VARCHAR(50) NOT NULL,
    encrypted_value TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP,
    UNIQUE(client_id, service_name, credential_type)
);

CREATE INDEX idx_api_credentials_client_id ON public.api_credentials(client_id);
CREATE INDEX idx_api_credentials_service_name ON public.api_credentials(service_name);
CREATE INDEX idx_api_credentials_is_active ON public.api_credentials(is_active);

-- =====================================================
-- CLIENT-SPECIFIC SCHEMAS (Isolated per Client)
-- =====================================================

-- =====================================================
-- Create function to initialize client schema
-- =====================================================

CREATE OR REPLACE FUNCTION create_client_schema(
    client_id_input INTEGER,
    client_name_input VARCHAR
) RETURNS void AS $$
DECLARE
    schema_name VARCHAR;
BEGIN
    schema_name := 'client_' || client_id_input;
    
    -- Create schema
    EXECUTE 'CREATE SCHEMA IF NOT EXISTS ' || schema_name;
    
    -- =====================================================
    -- Client Leads Table
    -- =====================================================
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.leads (
            lead_id SERIAL PRIMARY KEY,
            client_id INTEGER NOT NULL DEFAULT %L,
            internal_raw_lead_id INTEGER,
            
            -- Contact Information
            first_name VARCHAR(100),
            last_name VARCHAR(100),
            email VARCHAR(255) UNIQUE,
            phone VARCHAR(20),
            
            -- Company Information
            company_name VARCHAR(255),
            company_website VARCHAR(500),
            company_size VARCHAR(50),
            industry VARCHAR(100),
            revenue_range VARCHAR(50),
            founded_year INTEGER,
            
            -- Contact Role
            job_title VARCHAR(255),
            job_seniority VARCHAR(50),
            department VARCHAR(100),
            
            -- Lead Attributes
            source VARCHAR(50) NOT NULL,
            lead_source_details JSONB DEFAULT ''::jsonb,
            quality_score INTEGER DEFAULT 0,
            
            -- Verification Status
            email_verified BOOLEAN DEFAULT FALSE,
            email_verification_status VARCHAR(50) DEFAULT ''pending'',
            phone_verified BOOLEAN DEFAULT FALSE,
            phone_carrier VARCHAR(100),
            domain_verified BOOLEAN DEFAULT FALSE,
            
            -- Enrichment Data
            tech_stack JSONB DEFAULT ''[]''::jsonb,
            social_links JSONB DEFAULT ''{}''::jsonb,
            keywords TEXT[],
            
            -- AI Generated Content
            pitch_generated TEXT,
            pitch_tone VARCHAR(50),
            pain_points TEXT[],
            
            -- Engagement
            engagement_score INTEGER DEFAULT 0,
            last_activity_at TIMESTAMP,
            
            -- Trial Tracking
            trial_status VARCHAR(50) DEFAULT ''not_started'',
            trial_start_date DATE,
            trial_end_date DATE,
            trial_notes TEXT,
            
            -- Timestamps
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
    ', schema_name, client_id_input);
    
    EXECUTE format('CREATE INDEX idx_%I_leads_email ON %I.leads(email)', schema_name, schema_name);
    EXECUTE format('CREATE INDEX idx_%I_leads_source ON %I.leads(source)', schema_name, schema_name);
    EXECUTE format('CREATE INDEX idx_%I_leads_quality_score ON %I.leads(quality_score)', schema_name, schema_name);
    EXECUTE format('CREATE INDEX idx_%I_leads_trial_status ON %I.leads(trial_status)', schema_name, schema_name);
    EXECUTE format('CREATE INDEX idx_%I_leads_created_at ON %I.leads(created_at)', schema_name, schema_name);
    
    -- =====================================================
    -- Client Lead Sources
    -- =====================================================
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.lead_sources (
            source_id SERIAL PRIMARY KEY,
            lead_id INTEGER NOT NULL REFERENCES %I.leads(lead_id) ON DELETE CASCADE,
            source_type VARCHAR(50) NOT NULL,
            source_url TEXT,
            source_data JSONB,
            raw_payload JSONB,
            ingestion_timestamp TIMESTAMP NOT NULL DEFAULT NOW()
        )
    ', schema_name, schema_name);
    
    EXECUTE format('CREATE INDEX idx_%I_lead_sources_lead_id ON %I.lead_sources(lead_id)', schema_name, schema_name);
    EXECUTE format('CREATE INDEX idx_%I_lead_sources_source_type ON %I.lead_sources(source_type)', schema_name, schema_name);
    
    -- =====================================================
    -- Client Lead Segments (Mautic Mapping)
    -- =====================================================
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.lead_segments (
            segment_id SERIAL PRIMARY KEY,
            lead_id INTEGER NOT NULL REFERENCES %I.leads(lead_id) ON DELETE CASCADE,
            segment_name VARCHAR(100) NOT NULL,
            mautic_segment_id INTEGER,
            added_at TIMESTAMP NOT NULL DEFAULT NOW(),
            removed_at TIMESTAMP
        )
    ', schema_name, schema_name);
    
    EXECUTE format('CREATE INDEX idx_%I_lead_segments_lead_id ON %I.lead_segments(lead_id)', schema_name, schema_name);
    EXECUTE format('CREATE INDEX idx_%I_lead_segments_segment_name ON %I.lead_segments(segment_name)', schema_name, schema_name);
    
    -- =====================================================
    -- Client Lead Activities
    -- =====================================================
    EXECUTE format('
        CREATE TABLE IF NOT EXISTS %I.lead_activities (
            activity_id SERIAL PRIMARY KEY,
            lead_id INTEGER NOT NULL REFERENCES %I.leads(lead_id) ON DELETE CASCADE,
            activity_type VARCHAR(50) NOT NULL,
            description TEXT,
            activity_data JSONB,
            activity_timestamp TIMESTAMP NOT NULL DEFAULT NOW()
        )
    ', schema_name, schema_name);
    
    EXECUTE format('CREATE INDEX idx_%I_lead_activities_lead_id ON %I.lead_activities(lead_id)', schema_name, schema_name);
    EXECUTE format('CREATE INDEX idx_%I_lead_activities_type ON %I.lead_activities(activity_type)', schema_name, schema_name);
    
    -- =====================================================
    -- Grant permissions
    -- =====================================================
    EXECUTE format('GRANT ALL ON SCHEMA %I TO mauticuser', schema_name);
    EXECUTE format('GRANT ALL ON ALL TABLES IN SCHEMA %I TO mauticuser', schema_name);
    EXECUTE format('GRANT ALL ON ALL SEQUENCES IN SCHEMA %I TO mauticuser', schema_name);
    EXECUTE format('GRANT ALL ON ALL FUNCTIONS IN SCHEMA %I TO mauticuser', schema_name);
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Initialize for Mautic Database
-- =====================================================

CREATE DATABASE mautic;
CREATE USER mauticuser WITH PASSWORD 'MAUTIC_DB_PASSWORD_PLACEHOLDER';

ALTER ROLE mauticuser SET client_encoding TO 'utf8';
ALTER ROLE mauticuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE mauticuser SET default_transaction_deferrable TO 'on';
ALTER ROLE mauticuser SET timezone TO 'UTC';

GRANT ALL PRIVILEGES ON DATABASE mautic TO mauticuser;

-- =====================================================
-- Initialize for n8n Database
-- =====================================================

CREATE DATABASE n8n;
CREATE USER n8nuser WITH PASSWORD 'N8N_DB_PASSWORD_PLACEHOLDER';

ALTER ROLE n8nuser SET client_encoding TO 'utf8';
ALTER ROLE n8nuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE n8nuser SET default_transaction_deferrable TO 'on';
ALTER ROLE n8nuser SET timezone TO 'UTC';

GRANT ALL PRIVILEGES ON DATABASE n8n TO n8nuser;

-- =====================================================
-- Initialize for Metabase Database
-- =====================================================

CREATE DATABASE metabase;
CREATE USER metabaseuser WITH PASSWORD 'METABASE_DB_PASSWORD_PLACEHOLDER';

ALTER ROLE metabaseuser SET client_encoding TO 'utf8';
ALTER ROLE metabaseuser SET default_transaction_isolation TO 'read committed';
ALTER ROLE metabaseuser SET default_transaction_deferrable TO 'on';
ALTER ROLE metabaseuser SET timezone TO 'UTC';

GRANT ALL PRIVILEGES ON DATABASE metabase TO metabaseuser;

-- =====================================================
-- Initialize for WAHA Database
-- =====================================================

CREATE DATABASE waha;
CREATE USER wahauser WITH PASSWORD 'WAHA_DB_PASSWORD_PLACEHOLDER';

ALTER ROLE wahauser SET client_encoding TO 'utf8';
ALTER ROLE wahauser SET default_transaction_isolation TO 'read committed';
ALTER ROLE wahauser SET default_transaction_deferrable TO 'on';
ALTER ROLE wahauser SET timezone TO 'UTC';

GRANT ALL PRIVILEGES ON DATABASE waha TO wahauser;

-- =====================================================
-- Grant permissions on public schema
-- =====================================================

GRANT ALL ON SCHEMA public TO mauticuser;
GRANT ALL ON SCHEMA public TO n8nuser;
GRANT ALL ON SCHEMA public TO metabaseuser;
GRANT ALL ON SCHEMA public TO wahauser;

-- =====================================================
-- Insert Default Client (Demo)
-- =====================================================

INSERT INTO public.clients (client_name, status)
VALUES ('Demo Client', 'active')
ON CONFLICT (client_name) DO NOTHING;

-- Create schema for demo client (client_1)
SELECT create_client_schema(1, 'Demo Client');

-- =====================================================
-- Create Views for Reporting
-- =====================================================

CREATE OR REPLACE VIEW public.lead_status_summary AS
SELECT 
    c.client_id,
    c.client_name,
    COUNT(rl.lead_id) as total_leads,
    COUNT(CASE WHEN rl.verification_status = 'verified' THEN 1 END) as verified_leads,
    COUNT(CASE WHEN rl.verification_status = 'risky' THEN 1 END) as risky_leads,
    COUNT(CASE WHEN rl.verification_status = 'invalid' THEN 1 END) as invalid_leads,
    ROUND(COUNT(CASE WHEN rl.verification_status = 'verified' THEN 1 END)::numeric / COUNT(rl.lead_id) * 100, 2) as verification_rate_pct,
    ROUND(AVG(rl.quality_score), 1) as avg_quality_score,
    COUNT(CASE WHEN rl.quality_score >= 70 THEN 1 END) as high_quality_leads,
    COUNT(CASE WHEN lm.conversion_status = 'paid' THEN 1 END) as paid_conversions
FROM public.clients c
LEFT JOIN public.raw_leads rl ON c.client_id = rl.client_id
LEFT JOIN public.lead_mappings lm ON rl.lead_id = lm.internal_lead_id
GROUP BY c.client_id, c.client_name;

CREATE OR REPLACE VIEW public.sync_performance AS
SELECT 
    DATE(lm.created_at) as sync_date,
    COUNT(*) as total_attempted_syncs,
    COUNT(CASE WHEN lm.sync_status = 'synced' THEN 1 END) as successful_syncs,
    COUNT(CASE WHEN lm.sync_status = 'failed' THEN 1 END) as failed_syncs,
    ROUND(COUNT(CASE WHEN lm.sync_status = 'synced' THEN 1 END)::numeric / COUNT(*) * 100, 2) as sync_success_rate_pct,
    COUNT(CASE WHEN lm.sync_status = 'failed' AND lm.retry_count < 3 THEN 1 END) as pending_retries
FROM public.lead_mappings lm
GROUP BY DATE(lm.created_at)
ORDER BY sync_date DESC;

-- =====================================================
-- Sample Queries for Monitoring
-- =====================================================

-- Get all leads for a client
-- SELECT * FROM client_1.leads WHERE client_id = 1 ORDER BY created_at DESC LIMIT 10;

-- Get conversion metrics
-- SELECT COUNT(*) as total, 
--        COUNT(CASE WHEN conversion_status = 'paid' THEN 1 END) as paid,
--        ROUND(COUNT(CASE WHEN conversion_status = 'paid' THEN 1 END)::numeric / COUNT(*) * 100, 2) as conversion_rate
-- FROM public.lead_mappings WHERE created_at >= NOW() - INTERVAL '30 days';

-- Check sync errors
-- SELECT * FROM public.sync_errors WHERE resolution_status = 'open' ORDER BY created_at DESC;

-- Daily ingestion summary
-- SELECT DATE(ingestion_timestamp) as date, source, COUNT(*) as leads, ROUND(AVG(quality_score), 1) as avg_quality
-- FROM public.raw_leads GROUP BY DATE(ingestion_timestamp), source ORDER BY date DESC;

print('PostgreSQL initialization complete!');
