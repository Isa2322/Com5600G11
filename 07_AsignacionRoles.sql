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
------------------  BORRAR DE LOGINS --------------
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
------------------ CREACIÓN DE LOGINS --------------
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
--- CAMBIO DE CONTEXTO A LA BASE DE DATOS ----------
-------------------------------------------------------
USE [Com5600G11]
GO

-------------------------------------------------------
----------------- CREACIÓN DE USUARIOS -------------
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
------------------ CREACIÓN DE ROLES ---------------
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
------------ ASIGNACIÓN DE MIEMBROS --------------
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
------------- ASIGNACIÓN DE PERMISOS ---------------
-------------------------------------------------------

PRINT '>>> INICIANDO ASIGNACIÓN CONDICIONAL DE PERMISOS...'


-------------------------------------------------------
------------ Lectura sobre esquemas -------------------
-------------------------------------------------------

-- esquema Consorcio --

--AdminGenerales 
IF NOT EXISTS (
    SELECT 1 FROM sys.database_permissions 
    WHERE major_id = SCHEMA_ID('Consorcio') AND class_desc = 'SCHEMA' 
      AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') 
      AND permission_name = 'SELECT'
)
BEGIN
    GRANT SELECT ON SCHEMA::Consorcio TO AdministrativosGenerales;
END

--AdminOperativos
IF NOT EXISTS (
    SELECT 1 FROM sys.database_permissions 
    WHERE major_id = SCHEMA_ID('Consorcio') AND class_desc = 'SCHEMA' 
      AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') 
      AND permission_name = 'SELECT'
)
BEGIN
    GRANT SELECT ON SCHEMA::Consorcio TO AdministrativosOperativos;
END

-- esquema Negocio --

--AdministrativosGenerales
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Negocio') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'SELECT')
    GRANT SELECT ON SCHEMA::Negocio TO AdministrativosGenerales;

--AdministrativosOperativos
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Negocio') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'SELECT')
    GRANT SELECT ON SCHEMA::Negocio TO AdministrativosOperativos;

--AdministrativosBancarios
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Negocio') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'SELECT')
    GRANT SELECT ON SCHEMA::Negocio TO AdministrativosBancarios;


--esquema Pago --

-- AdministrativosBancarios
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Pago') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'SELECT')
    GRANT SELECT ON SCHEMA::Pago TO AdministrativosBancarios;

-------------------------------------------------------
------------ ejecucion --------------------------------
-------------------------------------------------------

-- AdministrativosGenerales

-- faltantes
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_CargaTiposRol') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_CargaTiposRol TO AdministrativosGenerales;


-- Importación
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarDatosConsorcios') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarDatosConsorcios TO AdministrativosGenerales;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarInquilinosPropietarios') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarInquilinosPropietarios TO AdministrativosGenerales;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarUFInquilinos') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarUFInquilinos TO AdministrativosGenerales;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarUFporConsorcio') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarUFporConsorcio TO AdministrativosGenerales;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_RellenarCocheras') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_RellenarCocheras TO AdministrativosGenerales;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_RellenarBauleras') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_RellenarBauleras TO AdministrativosGenerales;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.SP_generadorCuentaBancaria') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.SP_generadorCuentaBancaria TO AdministrativosGenerales;

-- Reportes
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Reporte') AND class_desc = 'SCHEMA' AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosGenerales') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON SCHEMA::Reporte TO AdministrativosGenerales;


-- AdministrativosOperativos--

-- faltantes
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_CargaTiposRol') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_CargaTiposRol TO AdministrativosOperativos;

-- Importación
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarDatosConsorcios') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarDatosConsorcios TO AdministrativosOperativos;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarInquilinosPropietarios') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarInquilinosPropietarios TO AdministrativosOperativos;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarUFInquilinos') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarUFInquilinos TO AdministrativosOperativos;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarUFporConsorcio') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarUFporConsorcio TO AdministrativosOperativos;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_RellenarCocheras') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_RellenarCocheras TO AdministrativosOperativos;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_RellenarBauleras') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_RellenarBauleras TO AdministrativosOperativos;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.SP_generadorCuentaBancaria') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.SP_generadorCuentaBancaria TO AdministrativosOperativos;

-- Reportes
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Reporte') AND class_desc = 'SCHEMA' AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosOperativos') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON SCHEMA::Reporte TO AdministrativosOperativos;



-- AdministrativosBancarios--

-- Gastos y Expensas
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_CargarGastosExtraordinarios') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_CargarGastosExtraordinarios TO AdministrativosBancarios;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarGastosMensuales') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarGastosMensuales TO AdministrativosBancarios;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarDatosProveedores') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarDatosProveedores TO AdministrativosBancarios;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.CargarGastosGeneralesOrdinarios') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.CargarGastosGeneralesOrdinarios TO AdministrativosBancarios;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Negocio.SP_GenerarLoteDeExpensas') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.SP_GenerarLoteDeExpensas TO AdministrativosBancarios;

-- datos de consorcio necesarios para los gastos
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarDatosConsorcios') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarDatosConsorcios TO AdministrativosBancarios;
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.SP_generadorCuentaBancaria') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.SP_generadorCuentaBancaria TO AdministrativosBancarios;

-- Bancario
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarPago') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_ImportarPago TO AdministrativosBancarios;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarPago') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_CrearYcargar_FormasDePago TO AdministrativosBancarios;

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = OBJECT_ID('Operaciones.sp_ImportarPago') AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON OBJECT::Operaciones.sp_AplicarPagosACuentas TO AdministrativosBancarios;

-- Reportes
IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Reporte') AND class_desc = 'SCHEMA' AND grantee_principal_id = DATABASE_PRINCIPAL_ID('AdministrativosBancarios') AND permission_name = 'EXECUTE')
    GRANT EXECUTE ON SCHEMA::Reporte TO AdministrativosBancarios;



-- Sistemas ---

IF NOT EXISTS (SELECT 1 FROM sys.database_permissions WHERE major_id = SCHEMA_ID('Reporte') AND class_desc = 'SCHEMA' AND grantee_principal_id = DATABASE_PRINCIPAL_ID('Sistemas') AND permission_name = 'EXECUTE')
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