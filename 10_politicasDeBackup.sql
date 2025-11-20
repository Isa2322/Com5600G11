

/* =========================================================================================
   3-POLITICAS DE RESPALDO (BACKUP)
========================================================================================= 

-- Política general:
--   • Backup FULL diario (00:00)
--   • Backup diferencial cada 6 horas
--   • Backup del log cada 1 hora
--   • Retención: 14 dias
--   • RPO: 1 hora / RTO: 30 min

-- Backup completo diario
BACKUP DATABASE [Com5600G11]
TO DISK = 'C:\Backups\Com5600G11_FULL.bak'
WITH INIT, COMPRESSION, NAME = 'Backup FULL diario - Com5600G11';
GO

-- Backup del log cada hora
BACKUP LOG [Com5600G11]
TO DISK = 'C:\Backups\Com5600G11_LOG.trn'
WITH NOINIT, COMPRESSION, NAME = 'Backup LOG horario - Com5600G11';
GO

-- Registro programado (solo referencia)
-- ---------------------------------------------------------
-- JOB: Backup_Com5600G11_FULL_Diario  → Diario 00:00 hs
-- JOB: Backup_Com5600G11_Diferencial  → Cada 6 hs
-- JOB: Backup_Com5600G11_Log_Horario  → Cada hora
-- RPO: 1 hora / RTO estimado: 30 min
-- ---------------------------------------------------------

PRINT 'Seguridad aplicada: roles creados, datos cifrados y backups configurados.';
GO
*/