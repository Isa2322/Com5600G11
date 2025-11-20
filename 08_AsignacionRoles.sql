/* =========================================================================================
   1️ CREACIÓN DE ROLES Y ASIGNACIÓN DE PERMISOS
========================================================================================= */

USE [master]
GO

------------------ CREACIÓN DE LOGIN ------------------
IF SUSER_ID('administrativoGeneral') IS NULL
BEGIN
    CREATE LOGIN administrativoGeneral
		WITH PASSWORD = 'admin123',
		CHECK_POLICY = ON,
		DEFAULT_DATABASE = [Com5600G11];
END
GO

IF SUSER_ID('administrativoBancario') IS NULL
BEGIN
    CREATE LOGIN administrativoBancario
		WITH PASSWORD = 'supervisor2024*',
		CHECK_POLICY = ON,
		DEFAULT_DATABASE = [Com5600G11];
END
GO


IF SUSER_ID('administrativoOperativo') IS NULL
BEGIN
    CREATE LOGIN administrativoOperativo
		WITH PASSWORD = 'oper4321',
		CHECK_POLICY = ON,
		DEFAULT_DATABASE = [Com5600G11];
END
GO

IF SUSER_ID('sistema') IS NULL
BEGIN
    CREATE LOGIN sistema
		WITH PASSWORD = 'sistema4321',
		CHECK_POLICY = ON,
		DEFAULT_DATABASE = [Com5600G11];
END
GO


-------------------------------------------------------
----------------- CREACIÓN DE USUARIO -----------------
-------------------------------------------------------

IF DATABASE_PRINCIPAL_ID('administrativoGeneral') IS NULL
	CREATE USER administrativoGeneral FOR LOGIN administrativoGeneral WITH DEFAULT_SCHEMA = [Persona];
GO

IF DATABASE_PRINCIPAL_ID('administrativoBancario') IS NULL
	CREATE USER administrativoBancario FOR LOGIN administrativoBancario WITH DEFAULT_SCHEMA = [Negocio];
GO

IF DATABASE_PRINCIPAL_ID('administrativoOperativo') IS NULL
	CREATE USER administrativoOperativo FOR LOGIN administrativoOperativo WITH DEFAULT_SCHEMA = [Negocio];
GO

IF DATABASE_PRINCIPAL_ID('sistema') IS NULL
	CREATE USER sistema FOR LOGIN sistema WITH DEFAULT_SCHEMA = [Persona];
GO


-------------------------------------------------------
------------------ CREACIÓN DE ROLES ------------------
-------------------------------------------------------

IF DATABASE_PRINCIPAL_ID('AdministrativosGenerales') IS NULL
	CREATE ROLE AdministrativosGenerales AUTHORIZATION dbo;
GO

IF DATABASE_PRINCIPAL_ID('AdministrativosBancarios') IS NULL
	CREATE ROLE AdministrativosBancarios AUTHORIZATION dbo;
GO

IF DATABASE_PRINCIPAL_ID('AdministrativosOperativos') IS NULL
	CREATE ROLE AdministrativosOperativos AUTHORIZATION dbo;
GO

IF DATABASE_PRINCIPAL_ID('Sistemas') IS NULL
	CREATE ROLE Sistemas AUTHORIZATION dbo;
GO



-------------------------------------------------------
------------- ASIGNACIÓN DE PERMISOS ------------------
-------------------------------------------------------


-- Administrativo General: actualizacion de datos UF y generacion de reportes
GRANT SELECT, UPDATE ON SCHEMA::Consorcio TO administrativoGeneral;
GRANT SELECT ON SCHEMA::Negocio TO administrativoGeneral;
GRANT EXECUTE ON SCHEMA::Reporte TO administrativoGeneral;

-- Administrativo Bancario: importacion de informacion bancaria + reportes
GRANT SELECT, INSERT, UPDATE ON SCHEMA::Pago TO administrativoBancario;
GRANT EXECUTE ON SCHEMA::Reporte TO administrativoBancario;
GRANT EXECUTE ON SCHEMA::Operaciones To administrativoBancario;

-- Administrativo Operativo: actualizacion de UF + reportes
GRANT SELECT, UPDATE ON SCHEMA::Consorcio TO administrativoOperativo;
GRANT EXECUTE ON SCHEMA::Reporte TO administrativoOperativo;

-- Sistemas: sólo reportes (lectura y ejecucion)
GRANT EXECUTE ON SCHEMA::Reporte TO sistema;
GO

-------------------------------------------------------
------------------ AÑADIR USUARIOS A ------------------
------------------------ ROLES ------------------------
-------------------------------------------------------



ALTER ROLE AdministrativosGenerales ADD MEMBER administrativoGeneral;
ALTER ROLE AdministrativosBancarios ADD MEMBER administrativoBancario;
ALTER ROLE AdministrativosOperativos ADD MEMBER administrativoOperativo;
ALTER ROLE Sistemas ADD MEMBER sistema;
GO

/*
USE Com5600G11;
GO

EXECUTE AS LOGIN = 'administrativoBancario';
SELECT SUSER_SNAME()   AS LoginActual,
       USER_NAME()      AS UsuarioBD;
-- selects que queramos o imports

REVERT;  -- vuelve a tu usuario
*/