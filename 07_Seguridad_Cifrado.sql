/* =========================================================================================
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

   Descripción:
   Implementacion de los requisitos de seguridad:
   1) Creación de roles y asignación de permisos según área.
   2) Cifrado de datos personales y sensibles.
   3) Definición y programación de políticas de respaldo (backup).
========================================================================================= */


/* =========================================================================================
   1️ CREACIÓN DE ROLES Y ASIGNACIÓN DE PERMISOS
========================================================================================= */


USE [master]
GO

------------------ CREACIÓN DE LOGIN ------------------


IF SUSER_ID('administrativoGeneral') IS NULL
BEGIN
    CREATE LOGIN administrativoGeneral
		WITH PASSWORD = 'admin#123',
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
		WITH PASSWORD = 'oper#4321',
		CHECK_POLICY = ON,
		DEFAULT_DATABASE = [Com5600G11];
END
GO

IF SUSER_ID('sistemas') IS NULL
BEGIN
    CREATE LOGIN sistemas
		WITH PASSWORD = 'sistemas#4321',
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

IF DATABASE_PRINCIPAL_ID('sistemas') IS NULL
	CREATE USER sistemas FOR LOGIN sistemas WITH DEFAULT_SCHEMA = [Persona];
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
GRANT EXECUTE ON SCHEMA::Reporte TO sistemas;
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


USE [Com5600G11]
GO

-------------------------------------------------------
-------------------- ENCRIPTACION ---------------------
-------------------------------------------------------

-------------------------------Creacion del certificado y contrasena-----------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys where name = 'DatosPersonas')
	BEGIN
		CREATE MASTER KEY ENCRYPTION BY PASSWORD ='Contrasenia135';
	END
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE NAME = 'CertifacadoEncriptacion')
	BEGIN
		CREATE CERTIFICATE CertifacadoEncriptacion
		WITH SUBJECT ='Certificado de datos sensibles'
	END
GO
IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys where name = 'DatosPersonas')
	BEGIN
		CREATE SYMMETRIC KEY DatosPersonas
		WITH ALGORITHM = AES_256
		ENCRYPTION BY CERTIFICATE CertifacadoEncriptacion
	END
GO

-----------------------------Borrado de keys e indices---------------------------------------------------

IF OBJECT_ID('Consorcio.PK__CuentaBa__B9B1535ACA1DD052','F') IS NOT NULL
BEGIN
	ALTER TABLE Consorcio.CuentaBancaria 
	DROP CONSTRAINT PK__CuentaBa__B9B1535ACA1DD052
END
GO

IF OBJECT_ID('Consorcio.FK_CVU_CBU','F') IS NOT NULL
BEGIN
	ALTER TABLE Consorcio.Consorcio
	DROP CONSTRAINT FK_CVU_CBU
END
GO
IF OBJECT_ID('Consorcio.FK_UF_CuentaPersona','F') IS NOT NULL
BEGIN
	ALTER TABLE Consorcio.UnidadFuncional
	DROP CONSTRAINT FK_UF_CuentaPersona
END
GO


IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional') AND name = 'IX_UF_CVUCBU')
BEGIN
	DROP INDEX IX_UF_CVUCBU ON Consorcio.UnidadFuncional
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Consorcio.Persona') 
			AND name = 'IX_Persona_CBU')
BEGIN
	DROP INDEX IX_Persona_CBU ON Consorcio.Persona
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Consorcio.Persona') 
			AND name = 'IX_Persona_CVU')
BEGIN
	DROP INDEX IX_Persona_CVU ON Consorcio.Persona
END
GO


IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Negocio.Expensa') 
			AND name = 'IX_Expensa_ConsorcioPeriodo')
BEGIN
	DROP INDEX IX_Expensa_ConsorcioPeriodo ON Negocio.Expensa
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Negocio.DetalleExpensa') 
			AND name = 'IX_DetalleExpensa_Fechas_UF_Exp')
BEGIN
	DROP INDEX IX_DetalleExpensa_Fechas_UF_Exp ON Negocio.DetalleExpensa
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Negocio.GastoExtraordinario') 
			AND name = 'IX_GastoExt_Expensa_Cuota')
BEGIN
	DROP INDEX IX_GastoExt_Expensa_Cuota ON Negocio.GastoExtraordinario
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Pago.Pago') 
			AND name = 'IX_Pago_Fecha')
BEGIN
	DROP INDEX IX_Pago_Fecha ON Pago.Pago
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Pago.Pago') 
			AND name = 'IX_Pago_CBU')
BEGIN
	DROP INDEX IX_Pago_CBU ON Pago.Pago
END
GO
-------------------------------------------Persona-------------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Persona') AND name= 'DNI_encriptado')
BEGIN
	ALTER TABLE Consorcio.Persona
	ADD DNI_encriptado VARBINARY(MAX),
		DNI_hash VARBINARY(32),
		EmailPersona_encriptado VARBINARY(MAX),
		EmailPersona_hash VARBINARY(32),
		CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_hash VARBINARY(32),
		telefono_encriptado VARBINARY(MAX),
		telefono_hash VARBINARY(32),
		nombre_encriptado VARBINARY(MAX),
		nombre_hash VARBINARY(32),
		apellido_encriptado VARBINARY(MAX),
		apellido_hash VARBINARY(32)
END
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Persona') AND name= 'dni' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion


	UPDATE Consorcio.Persona
	SET DNI_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), dni),
		DNI_hash = HASHBYTES('SHA2_512',dni),
		EmailPersona_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), email),
		EmailPersona_hash = HASHBYTES('SHA2_512',email),
		CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CVU_CBU),
		CVU_CBU_hash = HASHBYTES('SHA2_512',CVU_CBU),
		telefono_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'),telefono),
		telefono_hash = HASHBYTES('SHA2_512',telefono),
		nombre_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'),nombre),
		nombre_hash = HASHBYTES('SHA2_512',nombre),
		apellido_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), apellido),
		apellido_hash = HASHBYTES('SHA2_512',apellido)

	ALTER TABLE Consorcio.Persona
	DROP COLUMN  dni, 
				email,
				CVU_CBU,
				telefono,
				apellido,
				nombre

	EXEC sp_rename 'Consorcio.Persona.DNI_encriptado','dni','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.EmailPersona_encriptado','email','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.CVU_CBU_encriptado','CVU_CBU','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.telefono_encriptado','telefono','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.nombre_encriptado','nombre','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.apellido_encriptado','apellido','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
GO
----------------------------------------CuentaBancaria----------------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.CuentaBancaria') AND name= 'CVU_CBU_encriptado')
BEGIN

	ALTER TABLE Consorcio.CuentaBancaria
	ADD CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_Hash VARBINARY(32),
		nombreTitular_encriptado VARBINARY(MAX),
		saldo_encriptado VARBINARY(MAX)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.CuentaBancaria') AND name= 'CVU_CBU' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

	UPDATE Consorcio.CuentaBancaria
	SET CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'),CVU_CBU),
		CVU_CBU_Hash = HASHBYTES('SHA2_512',CVU_CBU),
		nombreTitular_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), nombreTitular),
		saldo_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,saldo))


	ALTER TABLE Consorcio.CuentaBancaria
	DROP COLUMN nombreTitular,
				saldo,
				CVU_CBU


	EXEC sp_rename 'Consorcio.CuentaBancaria.CVU_CBU_encriptado','CVU_CBU','COLUMN'
	EXEC sp_rename 'Consorcio.CuentaBancaria.nombreTitular_encriptado','nombreTitular','COLUMN'
	EXEC sp_rename 'Consorcio.CuentaBancaria.saldo_encriptado','saldo','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
GO
----------------------------------------------------Pago--------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.Pago') AND name= 'cbuCuentaOrigen_encriptado')
BEGIN
	ALTER TABLE Pago.Pago
	ADD cbuCuentaOrigen_encriptado VARBINARY(MAX),
		cbuCuentaOrigen_hash VARBINARY(32),
		fecha_encriptada VARBINARY(MAX),
		fecha_hash VARBINARY(32),
		importe_encriptado VARBINARY(MAX)

END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.Pago') AND name= 'cbuCuentaOrigen' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

	UPDATE Pago.Pago
	SET cbuCuentaOrigen_encriptado ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,cbuCuentaOrigen)),
		cbuCuentaOrigen_hash = HASHBYTES('SHA2_512',cbuCuentaOrigen),
		fecha_encriptada ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,	fecha)),
		fecha_hash = HASHBYTES('SHA2_512',fecha),
		importe_encriptado ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,importe))
	

	ALTER TABLE Pago.Pago
	DROP COLUMN cbuCuentaOrigen,
				fecha,
				importe

	EXEC sp_rename 'Pago.Pago.cbuCuentaOrigen_encriptado','cbuCuentaOrigen','COLUMN'
	EXEC sp_rename 'Pago.Pago.fecha_encriptada','fecha','COLUMN'
	EXEC sp_rename 'Pago.Pago.importe_encriptado','importe','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
GO
---------------------------------------------Consorcio---------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Consorcio') 
				AND name= 'CVU_CBU_encriptado')
BEGIN
	ALTER TABLE Consorcio.Consorcio
	ADD CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_Hash VARBINARY(32),
		direccion_encriptado VARBINARY(MAX)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Consorcio') AND name= 'CVU_CBU' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

	UPDATE Consorcio.Consorcio
	SET CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'),CVU_CBU),
		CVU_CBU_Hash = HASHBYTES('SHA2_512',CVU_CBU),
		direccion_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'),direccion)

	ALTER TABLE Consorcio.Consorcio
	DROP COLUMN CVU_CBU

	EXEC sp_rename 'Consorcio.Consorcio.CVU_CBU_encriptado','CVU_CBU','COLUMN'
	EXEC sp_rename 'Consorcio.Consorcio.direccion_encriptado','direccion','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
GO
---------------------------------------------UnidadFuncional---------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional') 
				AND name= 'CVU_CBU_encriptado')
BEGIN
	ALTER TABLE Consorcio.UnidadFuncional
	ADD CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_Hash VARBINARY(32)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional') AND name= 'CVU_CBU' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

	UPDATE Consorcio.UnidadFuncional
	SET CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'),CVU_CBU),
		CVU_CBU_Hash = HASHBYTES('SHA2_512',CVU_CBU)


	ALTER TABLE Consorcio.UnidadFuncional
	DROP CONSTRAINT FK_UF_CuentaPersona


	ALTER TABLE Consorcio.UnidadFuncional
	DROP CVU_CBU

	EXEC sp_rename 'Consorcio.UnidadFuncional.CVU_CBU_encriptado','CVU_CBU','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
--------------------------------------------DetalleExpensa-------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.DetalleExpensa') 
				AND name= 'prorrateoOrdinario_encriptado')
BEGIN
	ALTER TABLE Negocio.DetalleExpensa
	ADD prorrateoOrdinario_encriptado VARBINARY(MAX),
		prorrateoExtaordinario_encriptado VARBINARY(MAX),
		interesMora_encriptado VARBINARY(MAX),
		totalaPagar_encriptado VARBINARY(MAX),
		saldoAnteriorAbonado_encriptado VARBINARY(MAX),
		pagosRecibidos_encriptado VARBINARY(MAX),
		primerVencimiento_encriptado VARBINARY(MAX),
		primerVencimiento_hash VARBINARY(32),
		segundoVencimiento_encriptado VARBINARY(MAX)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.DetalleExpensa') AND name= 'prorrateoOrdinario' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

	Update Negocio.DetalleExpensa
	SET prorrateoOrdinario_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,prorrateoOrdinario)),
		prorrateoExtaordinario_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,prorrateoExtraordinario)),
		interesMora_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,interesMora)),
		totalaPagar_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,totalaPagar)),
		saldoAnteriorAbonado_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,saldoAnteriorAbonado)),
		pagosRecibidos_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,pagosRecibidos)),
		primerVencimiento_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,primerVencimiento)),
		primerVencimiento_hash = HASHBYTES('SHA2_512',primerVencimiento),
		segundoVencimiento_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,segundoVencimiento))


	ALTER TABLE Negocio.DetalleExpensa
	DROP COLUMN prorrateoOrdinario,
				prorrateoExtraordinario,
				ineteresMora,
				totalaPagar,
				saldoAnteriorAbonado,
				pagosRecibidos,
				primerVencimiento,
				segundoVencimiento


	EXEC sp_rename 'Negocio.DetalleExpensa.prorrateoOrdinario_encriptado','prorrateoOrdinario','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.prorrateoExtaordinario_encriptado','prorrateoExtraordinario','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.interesMora_encriptado','interesMora','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.totalaPagar_encriptado','totalaPagar','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.saldoAnteriorAbonado_encriptado','saldoAnteriorAbonado','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.pagosRecibidos_encriptado','segundoVencimiento','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.primerVencimiento_encriptado','primerVencimiento','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.segundoVencimiento_encriptado','pagosRecibidos','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
--------------------------------------------------Expensa-----------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.Expensa') 
				AND name= 'saldoAnterior_encriptado')
BEGIN
	ALTER TABLE Negocio.Expensa
	ADD saldoAnterior_encriptado VARBINARY(MAX),
		ingresosEnTermino_encriptado VARBINARY(MAX),
		ingresosAdeudados_encriptado VARBINARY(MAX),
		ingresosAdelantados_encriptado VARBINARY(MAX),
		egresos_encriptado VARBINARY(MAX),
		saldoCierre_encriptado VARBINARY(MAX),
		fechaPeriodoAnio_encriptado VARBINARY(MAX),
		fechaPeriodoAnio_hash VARBINARY(MAX),
		fechaPeriodoMes_encriptado VARBINARY(MAX),
		fechaPeriodoMes_hash VARBINARY(MAX)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.Expensa') AND name= 'saldoAnterior' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

UPDATE Negocio.Expensa
SET saldoAnterior_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,saldoAnterior)),
	ingresosEnTermino_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,ingresosEnTermino)),
	ingresosAdeudados_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,ingresosAdeudados)),
	ingresosAdelantados_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,ingresosAdelantados)),
	egresos_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,egresos)),
	saldoCierre_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,saldoCierre)),
	fechaPeriodoAnio_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,fechaPeriodoAnio)),
	fechaPeriodoAnio_hash = HASHBYTES('SHA2_512',fechaPeriodoAnio),
	fechaPeriodoMes_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,fechaPeriodoMes)),
	fechaPeriodoMes_hash = HASHBYTES('SHA2_512',fechaPeriodoMes)

ALTER TABLE Negocio.Expensa
DROP COLUMN saldoAnterior,
			ingresosEnTermino,
			ingresosAdeudados,
			ingresosAdelantados,
			egresos,
			saldoCierre,
			fechaPeriodoAnio,
			fechaPeriodoMes

EXEC sp_rename 'Negocio.Expensa.saldoAnterior_encriptado','saldoAnterior','COLUMN'
EXEC sp_rename 'Negocio.Expensa.ingresosEnTermino_encriptado','ingresosEnTermino','COLUMN'
EXEC sp_rename 'Negocio.Expensa.ingresosAdeudados_encriptado','ingresosAdeudados','COLUMN'
EXEC sp_rename 'Negocio.Expensa.ingresosAdelantados_encriptado','ingresosAdelantados','COLUMN'
EXEC sp_rename 'Negocio.Expensa.egresos_encriptado','egresos','COLUMN'
EXEC sp_rename 'Negocio.Expensa.saldoCierre_encriptado','saldoCierre','COLUMN'
EXEC sp_rename 'Negocio.Expensa.fechaPeriodoAnio_encriptado','fechaPeriodoAnio','COLUMN'
EXEC sp_rename 'Negocio.Expensa.fechaPeriodoMes_encriptado','fechaPeriodoMes','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
----------------------------------------GastoOrdinario----------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.GastoOrdinario')
				AND name= 'nroFactura_encriptado')
BEGIN
	ALTER TABLE Negocio.GastoOrdinario
	ADD nombreEmpresaoPersona_encriptado VARBINARY(MAX),
		nroFactura_encriptado VARBINARY(MAX),
		fechaEmision_encriptado VARBINARY(MAX),
		importeTotal_encriptado VARBINARY(MAX),
		detalle_encriptado VARBINARY(MAX),
		tipoServicio_encriptado VARBINARY(MAX)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.GastoOrdinario') AND name= 'nombreEmpresaoPersona' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

	UPDATE Negocio.GastoOrdinario
	SET nombreEmpresaoPersona_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), nombreEmpresaoPersona),
		nroFactura_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,nroFactura)),
		fechaEmision_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,fechaEmision)),
		importeTotal_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,importeTotal)),
		detalle_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), detalle),
		tipoServicio_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), tipoServicio)

	ALTER TABLE Negocio.GastoOrdinario
	DROP COLUMN nombreEmpresaoPersona,
				nroFactura,
				fechaEmision,
				importeTotal,
				detalle,
				tipoServicio

	EXEC sp_rename 'Negocio.GastoOrdinario.nombreEmpresaoPersona_encriptado','nombreEmpresaoPersona','COLUMN'
	EXEC sp_rename 'Negocio.GastoOrdinario.nroFactura_encriptado','nroFactura','COLUMN'
	EXEC sp_rename 'Negocio.GastoOrdinario.fechaEmision_encriptado','fechaEmision','COLUMN'
	EXEC sp_rename 'Negocio.GastoOrdinario.importeTotal_encriptado','importeTotal','COLUMN'
	EXEC sp_rename 'Negocio.GastoOrdinario.detalle_encriptado','detalle','COLUMN'
	EXEC sp_rename 'Negocio.GastoOrdinario.tipoServicio_encriptado','tipoServicio','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END

---------------------------------------------GastoExtaordinario------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.GastoExtraordinario') 
			AND name= 'nroFactura_encriptado')
BEGIN

ALTER TABLE Negocio.GastoExtraordinario
ADD nombreEmpresaoPersona_encriptado VARBINARY(MAX),
	nroFactura_encriptado VARBINARY(MAX),
	fechaEmision_encriptado VARBINARY(MAX),
	importeTotal_encriptado VARBINARY(MAX),
	detalle_encriptado VARBINARY(MAX),
	esPagoTotal_encriptado VARBINARY(MAX),
	nroCuota_encriptado VARBINARY(MAX),
	nroCuota_hash VARBINARY(32),
	totalCuota_encriptado VARBINARY(MAX)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('GastoExtraordinario') AND name= 'nombreEmpresaoPersona' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

UPDATE Negocio.GastoExtraordinario
SET nombreEmpresaoPersona_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), nombreEmpresaoPersona),
	nroFactura_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,nroFactura)),
	fechaEmision_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,fechaEmision)),
	importeTotal_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,importeTotal)),
	detalle_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), detalle),
	esPagoTotal_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,esPagoTotal)),
	nroCuota_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,nroCuota)),
	nroCuota_hash = HASHBYTES('SHA2_512',nroCuota),
	totalCuota_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,totalCuota))

ALTER TABLE Negocio.GastoExtraordinario
DROP COLUMN nombreEmpresaoPersona,
			nroFactura,
			fechaEmision,
			importeTotal,
			detalle,
			esPagoTotal,
			nroCuota,
			totalCuota

EXEC sp_rename 'Negocio.GastoExtraordinario.nombreEmpresaoPersona_encriptado','nombreEmpresaoPersona','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.nroFactura_encriptado','nroFactura','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.fechaEmision_encriptado','fechaEmision','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.importeTotal_encriptado','importeTotal','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.detalle_encriptado','detalle','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.esPagoTotal_encriptado','esPagoTotal','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.nroCuota_encriptado','nroCuota','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.totalCuota_encriptado','totalCuota','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
---------------------------------------PagoAplicado-----------------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.PagoAplicado') 
			AND name= 'importeAplicado_encriptado')
BEGIN

	ALTER TABLE Pago.PagoAplicado
	ADD importeAplicado_encriptado VARBINARY(MAX)
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.PagoAplicado') AND name= 'importeAplicado' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertifacadoEncriptacion

	UPDATE Pago.PagoAplicado
	SET importeAplicado_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CONVERT (VARCHAR,importeAplicado))


	ALTER TABLE Pago.PagoAplicado
	DROP COLUMN importeAplicado


	EXEC sp_rename 'Pago.PagoAplicado.importeAplicado_encriptado','importeAplicado','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
END
GO


------------------------Modificacion de indices----------------------------------------

IF OBJECT_ID('Consorcio.PK__CuentaBa__B9B1535ACA1DD052','F') IS NULL
BEGIN
	ALTER TABLE Consorcio.CuentaBancaria 
	ADD CONSTRAINT PK__CuentaBa__B9B1535ACA1DD052 PRIMARY KEY CLUSTERED(CVU_CBU_hash)
END
GO

IF OBJECT_ID('Consorcio.FK_CVU_CBU','F') IS NULL
BEGIN
	ALTER TABLE Consorcio.Consorcio
	ADD CONSTRAINT FK_CVU_CBU FOREIGN KEY (CVU_CBU_hash) REFERENCES Consorcio.CuentaBancaria(CVU_CBU_hash)
END
GO

IF OBJECT_ID('Consorcio.FK_UF_CuentaPersona','F') IS NULL
BEGIN
	ALTER TABLE Consorcio.UnidadFuncional
	ADD CONSTRAINT FK_UF_CuentaPersona FOREIGN KEY (CVU_CBU_hash) REFERENCES Consorcio.Persona (CVU_CBU_hash)
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional') 
				AND name = 'IX_UF_CVUCBU')
BEGIN
	    CREATE NONCLUSTERED INDEX IX_UF_CVUCBU
        ON Consorcio.UnidadFuncional (CVU_CBU_hash)
        INCLUDE (id, consorcioId);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Consorcio.Persona') 
				AND name = 'IX_Persona_CBU')
BEGIN
			CREATE NONCLUSTERED INDEX IX_Persona_CBU
            ON Consorcio.Persona (CVU_CBU_hash)
            INCLUDE (dni, nombre, apellido, email, telefono);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Consorcio.Persona') 
				AND name = 'IX_Persona_CVU')
BEGIN
			CREATE NONCLUSTERED INDEX IX_Persona_CVU
            ON Consorcio.Persona (CVU_CBU_hash)
            INCLUDE (dni, nombre, apellido, email, telefono);
END
GO


IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Negocio.Expensa') 
				AND name = 'IX_Expensa_ConsorcioPeriodo')
BEGIN
		CREATE NONCLUSTERED INDEX IX_Expensa_ConsorcioPeriodo
        ON Negocio.Expensa (consorcioId, fechaPeriodoAnio_hash, fechaPeriodoMes_hash)
        INCLUDE (id, saldoAnterior, ingresosEnTermino, ingresosAdeudados, 
		ingresosAdelantados, egresos, saldoCierre);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Negocio.DetalleExpensa') 
				AND name = 'IX_DetalleExpensa_Fechas_UF_Exp')
BEGIN
		CREATE NONCLUSTERED INDEX IX_DetalleExpensa_Fechas_UF_Exp
        ON Negocio.DetalleExpensa (primerVencimiento_hash, idUnidadFuncional, expensaId)
        INCLUDE (totalaPagar, pagosRecibidos, prorrateoOrdinario, 
		prorrateoExtraordinario, interesMora, segundoVencimiento);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Negocio.GastoExtraordinario') 
				AND name = 'IX_GastoExt_Expensa_Cuota')
BEGIN
			CREATE NONCLUSTERED INDEX IX_GastoExt_Expensa_Cuota
            ON Negocio.GastoExtraordinario (idExpensa, nroCuota_hash)
            INCLUDE (importeTotal, esPagoTotal, fechaEmision, 
			nombreEmpresaoPersona, detalle, totalCuota);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Pago.Pago') 
				AND name = 'IX_Pago_Fecha')
BEGIN
		CREATE NONCLUSTERED INDEX IX_Pago_Fecha
        ON Pago.Pago (fecha_hash)
        INCLUDE (id, importe, idFormaPago, cbuCuentaOrigen);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Pago.Pago') 
				AND name = 'IX_Pago_CBU')
BEGIN
		CREATE NONCLUSTERED INDEX IX_Pago_CBU
        ON Pago.Pago (cbuCuentaOrigen_hash)
        INCLUDE (id, fecha, importe, idFormaPago);
END
GO

/*
-- Encriptando Persona
ALTER TABLE Consorcio.Persona
ADD DNI_encriptado VARBINARY(256),
	EmailPersona_encriptado VARBINARY(256),
	CVU_CBU_encriptado VARBINARY(256)
GO

DECLARE @Contrasena VARCHAR(16) = 'Contrasenia135';

UPDATE Consorcio.Persona
SET DNI_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CAST(dni AS CHAR(8)), 1, CAST(idPersona AS VARBINARY(255))),
	Email_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), email),
	CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), CVU_CBU),
GO

ALTER TABLE Consorcio.Persona
DROP COLUMN idPersona, dni, email
GO

-- Encriptando CuentaBancaria
ALTER TABLE Consorcio.CuentaBancaria
ADD CVU_CBU_encriptado VARBINARY(256),
	nombreTitular_encriptado VARBINARY(256),
	saldo_encriptado VARBINARY(256)

UPDATE Consorcio.CuentaBancaria
SET CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'),CVU_CBU),
	nombreTitular_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), nombreTitular),
	saldo_encriptado = ENCRYPTBYKEY(Key_GUID('ClaveSimetrica'), saldo),
GO


ALTER TABLE Consorcio.CuentaBancaria
DROP COLUMN nombreTitular,saldo,CVU_CBU
GO


-------------------------------------------------------
----------------- DESENCRIPTACION ---------------------
-------------------------------------------------------


CREATE OR ALTER PROCEDURE Operaciones.CuentasDescifradas @contrasena VARCHAR
AS
SELECT
    nombreTitular,
    saldo,
    CVU_CBU,
    CONVERT(NVARCHAR(50), DECRYPTBYPASSPHRASE(@contrasena, nombreTitular_encriptado)) AS nombreTitular,
    CONVERT(NVARCHAR(100), DECRYPTBYPASSPHRASE(@contrasena, saldo_encriptado)) AS saldo,
    CONVERT(NVARCHAR(50), DECRYPTBYPASSPHRASE(@contrasena, CVU_CBU_encriptado)) AS CVU_CBU
FROM Consorcio.CuentaBancaria;
GO


-- Vista para descifrar (solo lectura para roles autorizados)
CREATE OR ALTER VIEW Operaciones.vwPersonasDescifradas 
AS


SELECT
    idPersona,
    nombre,
    apellido,
    CONVERT(NVARCHAR(50), DECRYPTBYPASSPHRASE('Contrasenia135', DNI_encriptado)) AS DNI,
    CONVERT(NVARCHAR(100), DECRYPTBYPASSPHRASE('Contrasenia135', EmailPersona_encriptado)) AS EmailPersona,
    CONVERT(NVARCHAR(50), DECRYPTBYPASSPHRASE('Contrasenia135', CVU_CBU_encriptado)) AS CVU_CBUPersona
FROM Consorcio.Persona;
GO

-- Solo los roles administrativos y sistemas pueden acceder
DENY SELECT ON Consorcio.Persona TO PUBLIC;
GRANT SELECT ON Consorcio.vwPersonasDescifradas TO AdministrativosGenerales, Sistemas;
GO





/* =========================================================================================
   3-POLITICAS DE RESPALDO (BACKUP)
========================================================================================= */

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

/*

/* 
=========================================================================================
   Ajusta el procedimiento Operaciones.sp_Reporte5_MayoresMorosos_XML
   para usar la vista Operaciones.vw_PersonasDescifradas
   despues de aplicar el cifrado.
========================================================================================= */


// PPrueba de modificacion de sp con solo Consorcio.Persona

IF OBJECT_ID('Operaciones.sp_Reporte5_MayoresMorosos_XML', 'P') IS NOT NULL
    DROP PROCEDURE Operaciones.sp_Reporte5_MayoresMorosos_XML
GO

CREATE OR ALTER PROCEDURE Operaciones.sp_Reporte5_MayoresMorosos_XML
    @idConsorcio INT,
    @fechaDesde  DATE,
    @fechaHasta  DATE = NULL
    --solo admito q la fecha limite venga vacia
AS
BEGIN
    SET NOCOUNT ON;
    IF @fechaHasta IS NULL SET @fechaHasta = CAST(GETDATE() AS DATE);

    WITH DeudaPorDetalle AS 
    (
        SELECT 
            de.expensaId,
            de.idUnidadFuncional,
            de.primerVencimiento,
            CASE 
                WHEN de.totalaPagar - ISNULL(de.pagosRecibidos,0) > 0 
                THEN de.totalaPagar - ISNULL(de.pagosRecibidos,0)
                ELSE 0 
            END AS Deuda
        FROM Negocio.DetalleExpensa AS de
        WHERE (@fechaDesde IS NULL OR de.primerVencimiento >= @fechaDesde)
          AND (@fechaHasta IS NULL OR de.primerVencimiento <= @fechaHasta)
    ),
    DeudaPorPersona AS 
    (
        SELECT
            p.dni,
            p.nombre,
            p.apellido,
            p.email,
            p.telefono,
            SUM(d.Deuda) AS MorosidadTotal
        FROM DeudaPorDetalle d
        INNER JOIN Consorcio.UnidadFuncional uf ON uf.id = d.idUnidadFuncional
        INNER JOIN Negocio.Expensa e            ON e.id = d.expensaId
        INNER JOIN Consorcio.Consorcio c        ON c.id = uf.consorcioId
        -- titular por CBU/CVU registrado en la UF
        INNER JOIN Operaciones.vw_PersonasDescifradas p
            ON (p.CVU_CBU = uf.CVU_CBU OR p.CVU_CBU = uf.CVU_CBU)
        WHERE (@idConsorcio IS NULL OR c.id = @idConsorcio)
        GROUP BY p.dni, p.nombre, p.apellido, p.email, p.telefono
        HAVING SUM(d.Deuda) > 0.01
    )
    SELECT
        (
            SELECT TOP (3)
                p.dni              AS [@dni],
                p.nombre           AS [nombre],
                p.apellido         AS [apellido],
                p.email            AS [email],
                p.telefono         AS [telefono],
                p.MorosidadTotal   AS [morosidad]
            FROM DeudaPorPersona p
            ORDER BY p.MorosidadTotal DESC
            FOR XML PATH('propietario'), ROOT('mayoresMorosos'), TYPE
        ) AS XML_Reporte5;
END
GO
*/*/