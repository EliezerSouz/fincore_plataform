-- Migration: Adicionar campos de contexto histórico forense desnormalizados à tabela audit_logs
-- Permite investigação completa sem JOINs e preserva imutabilidade histórica do momento da alteração.

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS user_name TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS user_role TEXT;

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS machine_name TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS host_name TEXT;

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS ip_address TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS mac_address TEXT;

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS platform TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS os_version TEXT;

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS app_version TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS session_id TEXT;

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS browser TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS device_description TEXT;

ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS entity_display_name TEXT;
ALTER TABLE audit_logs ADD COLUMN IF NOT EXISTS entity_module TEXT;

-- Índices otimizados para busca rápida em grandes volumes de auditoria
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_module ON audit_logs ("tenantId", entity_module);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_user ON audit_logs ("tenantId", "userId");
CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs (timestamp DESC);
