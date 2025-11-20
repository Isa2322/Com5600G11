/*
=========================================================================
ENTREGA 7 - REQUISITOS DE SEGURIDAD
   Materia: 3641 - Bases de Datos Aplicada
   Comisión: 5600
   Grupo: 11
   Fecha: 10/11/2025
   Archivo: 04_RequisitosDeSeguridad.sql

   Integrantes:
   - Hidalgo, Eduardo - 41173099
   - Quispe, Milagros Soledad - 45064110
   - Puma, Florencia - 42945609
   - Fontanet Caniza, Camila - 44892126
   - Altamiranda, Isaias Taiel - 43094671
   - Pastori, Ximena - 42300128
   ---------------------------------------------------------------------
   Incluye: Logins, Usuarios, Roles y Permisos
=========================================================================
*/

USE [master]
GO

-------------------------------------------------------
------------------ 0. BORRAR DE LOGINS --------------
-------------------------------------------------------
/*
-------------------------------------------------------
-- ELIMINAR USUARIOS (Nivel Base de Datos)
-------------------------------------------------------
USE [Com5600G11]
GO

PRINT '>>> ELIMINANDO USUARIOS DE LA BASE DE DATOS...'

IF USER_ID('administrativoGeneral') IS NOT NULL
BEGIN
    DROP USER administrativoGeneral;
    PRINT '   - Usuario administrativoGeneral eliminado.';
END

IF USER_ID('administrativoBancario') IS NOT NULL
BEGIN
    DROP USER administrativoBancario;
    PRINT '   - Usuario administrativoBancario eliminado.';
END

IF USER_ID('administrativoOperativo') IS NOT NULL
BEGIN
    DROP USER administrativoOperativo;
    PRINT '   - Usuario administrativoOperativo eliminado.';
END

IF USER_ID('sistema') IS NOT NULL
BEGIN
    DROP USER sistema;
    PRINT '   - Usuario sistema eliminado.';
END
GO

-------------------------------------------------------
-- ELIMINAR LOGINS (Nivel Servidor)
-------------------------------------------------------
USE [master]
GO

PRINT ''
PRINT '>>> ELIMINANDO LOGINS DEL SERVIDOR...'

IF SUSER_ID('administrativoGeneral') IS NOT NULL
BEGIN
    DROP LOGIN administrativoGeneral;
    PRINT '   - Login administrativoGeneral eliminado.';
END

IF SUSER_ID('administrativoBancario') IS NOT NULL
BEGIN
    DROP LOGIN administrativoBancario;
    PRINT '   - Login administrativoBancario eliminado.';
END

IF SUSER_ID('administrativoOperativo') IS NOT NULL
BEGIN
    DROP LOGIN administrativoOperativo;
    PRINT '   - Login administrativoOperativo eliminado.';
END

IF SUSER_ID('sistema') IS NOT NULL
BEGIN
    DROP LOGIN sistema;
    PRINT '   - Login sistema eliminado.';
END
GO

PRINT ''
PRINT '=== LIMPIEZA COMPLETADA ==='
*/

-------------------------------------------------------
------------------ 1. CREACIÓN DE LOGINS --------------
-------------------------------------------------------

IF SUSER_ID('administrativoGeneral') IS NULL
BEGIN
    CREATE LOGIN administrativoGeneral
        WITH PASSWORD = 'admin123',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = [Com5600G11];
END
GO

IF SUSER_ID('administrativoBancario') IS NULL
BEGIN
    CREATE LOGIN administrativoBancario
        WITH PASSWORD = 'supervisor2024*',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = [Com5600G11];
END
GO

IF SUSER_ID('administrativoOperativo') IS NULL
BEGIN
    CREATE LOGIN administrativoOperativo
        WITH PASSWORD = 'oper4321',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = [Com5600G11];
END
GO

IF SUSER_ID('sistema') IS NULL
BEGIN
    CREATE LOGIN sistema
        WITH PASSWORD = 'sistema4321',
        CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE = [Com5600G11];
END
GO

-------------------------------------------------------
--- 2. CAMBIO DE CONTEXTO A LA BASE DE DATOS ----------
-------------------------------------------------------
USE [Com5600G11]
GO

-------------------------------------------------------
----------------- 3. CREACIÓN DE USUARIOS -------------
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
------------------ 4. CREACIÓN DE ROLES ---------------
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
------------ 5. ASIGNACIÓN DE MIEMBROS --------------
-------------------------------------------------------

IF IS_ROLEMEMBER('AdministrativosGenerales', 'administrativoGeneral') = 0 
BEGIN
    ALTER ROLE AdministrativosGenerales ADD MEMBER administrativoGeneral;
END

IF IS_ROLEMEMBER('AdministrativosBancarios', 'administrativoBancario') = 0
BEGIN
    ALTER ROLE AdministrativosBancarios ADD MEMBER administrativoBancario;
END

IF IS_ROLEMEMBER('AdministrativosOperativos', 'administrativoOperativo') = 0
BEGIN
    ALTER ROLE AdministrativosOperativos ADD MEMBER administrativoOperativo;
END

IF IS_ROLEMEMBER('Sistemas', 'sistema') = 0
BEGIN
    ALTER ROLE Sistemas ADD MEMBER sistema;
END
GO

-------------------------------------------------------
------------- 6. ASIGNACIÓN DE PERMISOS ---------------
-------------------------------------------------------

-- A. Rol: Administrativo General
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Consorcio')
    GRANT SELECT, UPDATE ON SCHEMA::Consorcio TO AdministrativosGenerales;

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Negocio')
    GRANT SELECT ON SCHEMA::Negocio TO AdministrativosGenerales;

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Reporte')
    GRANT EXECUTE ON SCHEMA::Reporte TO AdministrativosGenerales;
GO

-- B. Rol: Administrativo Bancario
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Pago')
    GRANT SELECT, INSERT, UPDATE ON SCHEMA::Pago TO AdministrativosBancarios;

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Reporte')
    GRANT EXECUTE ON SCHEMA::Reporte TO AdministrativosBancarios;

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Operaciones')
    GRANT EXECUTE ON SCHEMA::Operaciones To AdministrativosBancarios;
GO

-- C. Rol: Administrativo Operativo
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Consorcio')
    GRANT SELECT, UPDATE ON SCHEMA::Consorcio TO AdministrativosOperativos;

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Reporte')
    GRANT EXECUTE ON SCHEMA::Reporte TO AdministrativosOperativos;
GO

-- D. Rol: Sistemas
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Reporte')
    GRANT EXECUTE ON SCHEMA::Reporte TO Sistemas;
GO

PRINT 'Script de Seguridad ejecutado correctamente.'



/*
USE Com5600G11;
GO

EXECUTE AS LOGIN = 'administrativoBancario';
SELECT SUSER_SNAME()   AS LoginActual,
       USER_NAME()      AS UsuarioBD;
-- selects que queramos o imports

REVERT;  -- vuelve a tu usuario
*/