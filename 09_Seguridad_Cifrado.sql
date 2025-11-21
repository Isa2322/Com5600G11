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

USE [Com5600G11]
GO
-------------------------------------------------------------------------------------------------------------
------------------ Esta hoja esta pensada para que se ejecute el script completo una unica vez---------------
-------------------------------------------------------------------------------------------------------------

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Persona') AND name= 'DNI_hash') 
BEGIN
	RAISERROR('Los datos ya estan encriptados',16,1)
END

-------------------------------------------------------
-------------------- ENCRIPTACION ---------------------
-------------------------------------------------------


-------------------------------Creacion del certificado y contrasena-----------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys where name = 'DatosPersonas')
	BEGIN
		CREATE MASTER KEY ENCRYPTION BY PASSWORD ='Contrasenia135';
	END
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE NAME = 'CertificadoEncriptacion')
	BEGIN
		CREATE CERTIFICATE CertificadoEncriptacion
		WITH SUBJECT ='Certificado de datos sensibles'
	END
GO
IF NOT EXISTS(SELECT 1 FROM sys.symmetric_keys where name = 'DatosPersonas')
	BEGIN
		CREATE SYMMETRIC KEY DatosPersonas
		WITH ALGORITHM = AES_256
		ENCRYPTION BY CERTIFICATE CertificadoEncriptacion
	END
GO

-----------------------------Borrado de constaints e indices con conflicto-----------------------------------
IF OBJECT_ID('Consorcio.UnidadFuncional','F') IS NOT NULL
BEGIN
	ALTER TABLE Consorcio.UnidadFuncional
	DROP CONSTRAINT FK_UF_CuentaPersona
END
GO

IF OBJECT_ID('Consorcio.FK_CVU_CBU','F') IS NOT NULL
BEGIN
	ALTER TABLE Consorcio.Consorcio
	DROP CONSTRAINT FK_CVU_CBU
END
GO

IF OBJECT_ID('Consorcio.PK_CVU_CBU','PK') IS NOT NULL
BEGIN
	ALTER TABLE Consorcio.CuentaBancaria 
	DROP CONSTRAINT PK_CVU_CBU
END
GO

IF OBJECT_ID('Consorcio.FK_UF_CuentaPersona','F') IS NOT NULL
BEGIN
	ALTER TABLE Consorcio.UnidadFuncional
	DROP CONSTRAINT FK_UF_CuentaPersona
END
GO


IF EXISTS (SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID('Consorcio.Persona')
      AND type = 'UQ'
      AND name = 'UQ_Persona_CVUCBU'
)
BEGIN
	ALTER TABLE Consorcio.Persona
	DROP CONSTRAINT UQ_Persona_CVUCBU
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

IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Pago.Pago') 
			AND name = 'IX_Pago_CBU')
BEGIN
	DROP INDEX IX_Pago_CBU ON Pago.Pago
END
GO


IF EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_UF_Consorcio'
                 AND object_id = OBJECT_ID('Consorcio.UnidadFuncional'))
BEGIN
	DROP INDEX IX_UF_Consorcio ON Consorcio.UnidadFuncional
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_Pago_Fecha'
                 AND object_id = OBJECT_ID('Pago.Pago'))
BEGIN
	DROP INDEX IX_Pago_Fecha ON Pago.Pago
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_DetalleExpensa_Fechas_UF_Exp'
                 AND object_id = OBJECT_ID('Negocio.DetalleExpensa'))
BEGIN
	DROP INDEX IX_DetalleExpensa_Fechas_UF_Exp ON Negocio.DetalleExpensa
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_Expensa_ConsorcioPeriodo'
                 AND object_id = OBJECT_ID('Negocio.Expensa'))
BEGIN
	DROP INDEX IX_Expensa_ConsorcioPeriodo ON Negocio.Expensa
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes 
                   WHERE name = 'IX_GastoOrd_Expensa_Tipo'
                     AND object_id = OBJECT_ID('Negocio.GastoOrdinario'))
BEGIN
	DROP INDEX IX_GastoOrd_Expensa_Tipo ON Negocio.GastoOrdinario
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_PagoAplicado_Detalle'
                 AND object_id = OBJECT_ID('Pago.PagoAplicado'))
BEGIN
	DROP INDEX IX_PagoAplicado_Detalle ON Pago.PagoAplicado
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_PagoAplicado_Pago'
                 AND object_id = OBJECT_ID('Pago.PagoAplicado'))
BEGIN
	DROP INDEX IX_PagoAplicado_Pago ON Pago.PagoAplicado
END
GO

IF EXISTS (SELECT 1 FROM sys.indexes 
                   WHERE name = 'IX_GastoExt_Expensa_Cuota'
                     AND object_id = OBJECT_ID('Negocio.GastoExtraordinario'))
    BEGIN
		DROP INDEX IX_GastoExt_Expensa_Cuota ON Negocio.GastoExtraordinario
    END
GO

--------------------------------------------------------------------------------------------------------
--------------------------Modificacion de cada tabla asociada a datos sencibles-------------------------
--------------------------------------------------------------------------------------------------------


-------------------------------------------Persona------------------------------------------------------

--Se crean nuevas columnas para no pisar los datos en caso de fallo
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Persona') AND name= 'DNI_encriptado')
BEGIN
	ALTER TABLE Consorcio.Persona
	ADD DNI_encriptado VARBINARY(MAX),
		DNI_hash VARBINARY(64),
		EmailPersona_encriptado VARBINARY(MAX),
		EmailPersona_hash VARBINARY(64),
		CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_hash VARBINARY(64),
		telefono_encriptado VARBINARY(MAX),
		telefono_hash VARBINARY(64),
		nombre_encriptado VARBINARY(MAX),
		nombre_hash VARBINARY(64),
		apellido_encriptado VARBINARY(MAX),
		apellido_hash VARBINARY(64)
END
GO

BEGIN TRY
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Persona') AND name= 'dni' AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Consorcio.Persona...'
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	--Se guardan los datos encrip´tados en las columnas nuevas
	UPDATE Consorcio.Persona
	SET DNI_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), dni),
		DNI_hash = HASHBYTES('SHA2_512',dni),
		EmailPersona_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), email),
		EmailPersona_hash = HASHBYTES('SHA2_512',email),
		CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CVU_CBU),
		CVU_CBU_hash = HASHBYTES('SHA2_512',CVU_CBU),
		telefono_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'),telefono),
		telefono_hash = HASHBYTES('SHA2_512',telefono),
		nombre_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'),nombre),
		nombre_hash = HASHBYTES('SHA2_512',nombre),
		apellido_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), apellido),
		apellido_hash = HASHBYTES('SHA2_512',apellido)

	--Se dropean las columnas no cifradas
	ALTER TABLE Consorcio.Persona
	DROP COLUMN  dni, 
				email,
				CVU_CBU,
				telefono,
				apellido,
				nombre	
			
	--Se renombran las columnas cifradas para no perder consistencia 
	EXEC sp_rename 'Consorcio.Persona.DNI_encriptado','dni','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.EmailPersona_encriptado','email','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.CVU_CBU_encriptado','CVU_CBU','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.telefono_encriptado','telefono','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.nombre_encriptado','nombre','COLUMN'
	EXEC sp_rename 'Consorcio.Persona.apellido_encriptado','apellido','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Consorcio.Persona cifrado correctamente'
END

	COMMIT TRAN;
END TRY

BEGIN CATCH ---En caso de fallo hago rollback y dropeo las columnas de datos cifrados y hash , si se crearon
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Consorcio.Persona'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.Persona')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Consorcio.Persona
			DROP COLUMN DNI_encriptado,
						EmailPersona_encriptado,
						CVU_CBU_encriptado,
						telefono_encriptado,
						nombre_encriptado,
						apellido_encriptado;
		END

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.Persona')
			AND name LIKE '%hash'
		)
		BEGIN
			ALTER TABLE Consorcio.Persona
			DROP COLUMN DNI_hash,
						EmailPersona_hash,
						CVU_CBU_hash,
						telefono_hash,
						nombre_hash,
						apellido_hash;
		END
	END CATCH;
	GO
----------------------------------------CuentaBancaria----------------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.CuentaBancaria') AND name= 'CVU_CBU_encriptado')
BEGIN

	ALTER TABLE Consorcio.CuentaBancaria
	ADD CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_Hash VARBINARY(64),
		nombreTitular_encriptado VARBINARY(MAX),
		saldo_encriptado VARBINARY(MAX)
END
GO

BEGIN TRY
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.CuentaBancaria') AND name= 'CVU_CBU' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Consorcio.CuentaBancaria...'
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	UPDATE Consorcio.CuentaBancaria
	SET CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'),CVU_CBU),
		CVU_CBU_Hash = HASHBYTES('SHA2_512',CVU_CBU),
		nombreTitular_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), nombreTitular),
		saldo_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,saldo))


	ALTER TABLE Consorcio.CuentaBancaria
	DROP COLUMN nombreTitular,
				saldo,
				CVU_CBU


	EXEC sp_rename 'Consorcio.CuentaBancaria.CVU_CBU_encriptado','CVU_CBU','COLUMN'
	EXEC sp_rename 'Consorcio.CuentaBancaria.nombreTitular_encriptado','nombreTitular','COLUMN'
	EXEC sp_rename 'Consorcio.CuentaBancaria.saldo_encriptado','saldo','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;

	--Modificacion para usar a CVU_CBU_Hash como PK
	ALTER TABLE Consorcio.CuentaBancaria
	ALTER COLUMN CVU_CBU_Hash VARBINARY(64)NOT NULL

	PRINT 'Consorcio.CuentaBancaria Cifrado correctamente'
END

	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Consorcio.CuentaBancaria'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.CuentaBancaria')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Consorcio.CuentaBancaria
			DROP COLUMN	CVU_CBU_encriptado,
						nombreTitular_encriptado,
						saldo_encriptado
		END
		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.CuentaBancaria')
			AND name LIKE '%hash'
		)
		BEGIN
			ALTER TABLE Consorcio.CuentaBancaria
			DROP COLUMN CVU_CBU_hash
		END
	END CATCH;
	GO
----------------------------------------------------Pago--------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.Pago') AND name= 'cbuCuentaOrigen_encriptado')
BEGIN
	ALTER TABLE Pago.Pago
	ADD cbuCuentaOrigen_encriptado VARBINARY(MAX),
		cbuCuentaOrigen_hash VARBINARY(64),
		importe_encriptado VARBINARY(MAX)

END
GO

BEGIN TRY
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.Pago') AND name= 'cbuCuentaOrigen' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Pago.Pago...'
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	UPDATE Pago.Pago
	SET cbuCuentaOrigen_encriptado= ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,cbuCuentaOrigen)),
		cbuCuentaOrigen_hash = HASHBYTES('SHA2_512',cbuCuentaOrigen),
		importe_encriptado= ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,importe))
	

	ALTER TABLE Pago.Pago
	DROP COLUMN cbuCuentaOrigen,
				importe

	EXEC sp_rename 'Pago.Pago.cbuCuentaOrigen_encriptado','cbuCuentaOrigen','COLUMN'
	EXEC sp_rename 'Pago.Pago.importe_encriptado','importe','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Pago.Pago Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Pago.Pago'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Pago.Pago')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Pago.Pago
			DROP COLUMN	cbuCuentaOrigen_encriptado,
						importe_encriptado
		END

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Pago.Pago')
			AND name LIKE '%hash'
		)
		BEGIN
			ALTER TABLE Pago.Pago
			DROP COLUMN cbuCuentaOrigen_hash
		END
	END CATCH;
	GO
---------------------------------------------Consorcio---------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Consorcio') 
				AND name= 'CVU_CBU_encriptado')
BEGIN
	ALTER TABLE Consorcio.Consorcio
	ADD CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_Hash VARBINARY(64),
		direccion_encriptado VARBINARY(MAX)
END
GO

BEGIN TRY
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.Consorcio') AND name= 'CVU_CBU' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Consorcio.Consorcio'
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	UPDATE Consorcio.Consorcio
	SET CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'),CVU_CBU),
		CVU_CBU_Hash = HASHBYTES('SHA2_512',CVU_CBU),
		direccion_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'),direccion)

	ALTER TABLE Consorcio.Consorcio
	DROP COLUMN CVU_CBU,
				direccion

	EXEC sp_rename 'Consorcio.Consorcio.CVU_CBU_encriptado','CVU_CBU','COLUMN'
	EXEC sp_rename 'Consorcio.Consorcio.direccion_encriptado','direccion','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Consorcio.Consorcio Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Consorcio.Consorcio'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.Consorcio')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Consorcio.Consorcio
			DROP COLUMN	CVU_CBU_encriptado,
						direccion_encriptado
		END

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.Consorcio')
			AND name LIKE '%hash'
		)
		BEGIN
			ALTER TABLE Consorcio.Consorcio
			DROP COLUMN CVU_CBU_Hash
		END
	END CATCH;
	GO
---------------------------------------------UnidadFuncional---------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional') 
				AND name= 'CVU_CBU_encriptado')
BEGIN
	ALTER TABLE Consorcio.UnidadFuncional
	ADD CVU_CBU_encriptado VARBINARY(MAX),
		CVU_CBU_Hash VARBINARY(64)
END
GO

BEGIN TRY
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional') AND name= 'CVU_CBU' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Consorcio.UnidadFuncional...'

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	UPDATE Consorcio.UnidadFuncional
	SET CVU_CBU_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'),CVU_CBU),
		CVU_CBU_Hash = HASHBYTES('SHA2_512',CVU_CBU)


	ALTER TABLE Consorcio.UnidadFuncional
	DROP COLUMN CVU_CBU

	EXEC sp_rename 'Consorcio.UnidadFuncional.CVU_CBU_encriptado','CVU_CBU','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Consorcio.UnidadFuncional Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Consorcio.UnidadFuncional'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Consorcio.UnidadFuncional
			DROP COLUMN	CVU_CBU_encriptado
		END

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Consorcio.UnidadFuncional')
			AND name LIKE '%hash'
		)
		BEGIN
			ALTER TABLE Consorcio.UnidadFuncional
			DROP COLUMN CVU_CBU_Hash
		END
	END CATCH;
	GO
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
		primerVencimiento_hash VARBINARY(64),
		segundoVencimiento_encriptado VARBINARY(MAX)
END
GO

BEGIN TRY
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.DetalleExpensa') AND name= 'prorrateoOrdinario' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando Negocio.DetalleExpensa...'

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	Update Negocio.DetalleExpensa
	SET prorrateoOrdinario_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,prorrateoOrdinario)),
		prorrateoExtaordinario_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,prorrateoExtraordinario)),
		interesMora_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,interesMora)),
		totalaPagar_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,totalaPagar)),
		saldoAnteriorAbonado_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,saldoAnteriorAbonado)),
		pagosRecibidos_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,pagosRecibidos)),
		primerVencimiento_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,primerVencimiento)),
		primerVencimiento_hash = HASHBYTES('SHA2_512',CONVERT (VARCHAR,CONVERT (VARCHAR,primerVencimiento))),
		segundoVencimiento_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,segundoVencimiento))


	ALTER TABLE Negocio.DetalleExpensa
	DROP COLUMN prorrateoOrdinario,
				prorrateoExtraordinario,
				interesMora,
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
	EXEC sp_rename 'Negocio.DetalleExpensa.pagosRecibidos_encriptado','pagosRecibidos','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.primerVencimiento_encriptado','primerVencimiento','COLUMN'
	EXEC sp_rename 'Negocio.DetalleExpensa.segundoVencimiento_encriptado','segundoVencimiento','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Negocio.DetalleExpensa Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Negocio.DetalleExpensa'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Negocio.DetalleExpensa')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Negocio.DetalleExpensa
			DROP COLUMN	prorrateoOrdinario_encriptado,
						prorrateoExtaordinario_encriptado,
						interesMora_encriptado,
						totalaPagar_encriptado,
						saldoAnteriorAbonado_encriptado,
						pagosRecibidos_encriptado,
						primerVencimiento_encriptado,
						segundoVencimiento_encriptado
		END

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Negocio.DetalleExpensa')
			AND name LIKE '%hash'
		)
		BEGIN
			ALTER TABLE Negocio.DetalleExpensa
			DROP COLUMN primerVencimiento_hash
		END
	END CATCH;
	GO
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
		saldoCierre_encriptado VARBINARY(MAX)
END
GO

BEGIN TRY 
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.Expensa') AND name= 'saldoAnterior' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Negocio.Expensa...'

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

UPDATE Negocio.Expensa
SET saldoAnterior_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,saldoAnterior)),
	ingresosEnTermino_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,ingresosEnTermino)),
	ingresosAdeudados_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,ingresosAdeudados)),
	ingresosAdelantados_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,ingresosAdelantados)),
	egresos_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,egresos)),
	saldoCierre_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,saldoCierre))


ALTER TABLE Negocio.Expensa
DROP COLUMN saldoAnterior,
			ingresosEnTermino,
			ingresosAdeudados,
			ingresosAdelantados,
			egresos,
			saldoCierre


EXEC sp_rename 'Negocio.Expensa.saldoAnterior_encriptado','saldoAnterior','COLUMN'
EXEC sp_rename 'Negocio.Expensa.ingresosEnTermino_encriptado','ingresosEnTermino','COLUMN'
EXEC sp_rename 'Negocio.Expensa.ingresosAdeudados_encriptado','ingresosAdeudados','COLUMN'
EXEC sp_rename 'Negocio.Expensa.ingresosAdelantados_encriptado','ingresosAdelantados','COLUMN'
EXEC sp_rename 'Negocio.Expensa.egresos_encriptado','egresos','COLUMN'
EXEC sp_rename 'Negocio.Expensa.saldoCierre_encriptado','saldoCierre','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Negocio.Expensa Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Negocio.Expensa'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Negocio.Expensa')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Negocio.Expensa
			DROP COLUMN	saldoAnterior_encriptado,
						ingresosEnTermino_encriptado,
						ingresosAdeudados_encriptado,
						ingresosAdelantados_encriptado,
						egresos_encriptado,
						saldoCierre_encriptado
		END
	END CATCH;
	GO
----------------------------------------GastoOrdinario----------------------------------------------------
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.GastoOrdinario')
				AND name= 'nroFactura_encriptado')
BEGIN
	ALTER TABLE Negocio.GastoOrdinario
	ADD nombreEmpresaoPersona_encriptado VARBINARY(MAX),
		importeTotal_encriptado VARBINARY(MAX),
		detalle_encriptado VARBINARY(MAX)
END
GO

BEGIN TRY
BEGIN TRAN

IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.GastoOrdinario') AND name= 'nombreEmpresaoPersona' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Negocio.GastoOrdinario...'

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	UPDATE Negocio.GastoOrdinario
	SET nombreEmpresaoPersona_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), nombreEmpresaoPersona),
		importeTotal_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,importeTotal)),
		detalle_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), detalle)

	ALTER TABLE Negocio.GastoOrdinario
	DROP COLUMN nombreEmpresaoPersona,
				importeTotal,
				detalle

	EXEC sp_rename 'Negocio.GastoOrdinario.nombreEmpresaoPersona_encriptado','nombreEmpresaoPersona','COLUMN'
	EXEC sp_rename 'Negocio.GastoOrdinario.importeTotal_encriptado','importeTotal','COLUMN'
	EXEC sp_rename 'Negocio.GastoOrdinario.detalle_encriptado','detalle','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Negocio.GastoOrdinario Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Negocio.GastoOrdinario'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Negocio.GastoOrdinario')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Negocio.GastoOrdinario
			DROP COLUMN	nombreEmpresaoPersona_encriptado,
						importeTotal_encriptado,
						detalle_encriptado
		END
	END CATCH;
	GO

---------------------------------------------GastoExtaordinario------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.GastoExtraordinario') 
			AND name= 'nroFactura_encriptado')
BEGIN

	ALTER TABLE Negocio.GastoExtraordinario
	ADD nombreEmpresaoPersona_encriptado VARBINARY(MAX),
		fechaEmision_encriptado VARBINARY(MAX),
		importeTotal_encriptado VARBINARY(MAX),
		detalle_encriptado VARBINARY(MAX),
		esPagoTotal_encriptado VARBINARY(MAX),
		totalCuota_encriptado VARBINARY(MAX)
END
GO

BEGIN TRY
BEGIN TRAN
IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Negocio.GastoExtraordinario') AND name= 'nombreEmpresaoPersona' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Negocio.GastoExtraordinario...'

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

UPDATE Negocio.GastoExtraordinario
SET nombreEmpresaoPersona_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), nombreEmpresaoPersona),
	fechaEmision_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,fechaEmision)),
	importeTotal_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,importeTotal)),
	detalle_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), detalle),
	esPagoTotal_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,esPagoTotal)),
	totalCuota_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,totalCuota))

ALTER TABLE Negocio.GastoExtraordinario
DROP COLUMN nombreEmpresaoPersona,
			fechaEmision,
			importeTotal,
			detalle,
			esPagoTotal,
			totalCuota;


EXEC sp_rename 'Negocio.GastoExtraordinario.nombreEmpresaoPersona_encriptado','nombreEmpresaoPersona','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.fechaEmision_encriptado','fechaEmision','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.importeTotal_encriptado','importeTotal','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.detalle_encriptado','detalle','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.esPagoTotal_encriptado','esPagoTotal','COLUMN'
EXEC sp_rename 'Negocio.GastoExtraordinario.totalCuota_encriptado','totalCuota','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Negocio.GastoExtraordinario Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Negocio.GastoExtraordinario'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Negocio.GastoExtraordinario')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Negocio.GastoExtraordinario
			DROP COLUMN	nombreEmpresaoPersona_encriptado,
						fechaEmision_encriptado,
						importeTotal_encriptado,
						detalle_encriptado,
						esPagoTotal_encriptado,
						totalCuota_encriptado
		END
	END CATCH;
	GO

---------------------------------------PagoAplicado-----------------------------------------------------------

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.PagoAplicado') 
			AND name= 'importeAplicado_encriptado')
BEGIN

	ALTER TABLE Pago.PagoAplicado
	ADD importeAplicado_encriptado VARBINARY(MAX)
END
GO

BEGIN TRY 
BEGIN TRAN
IF EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Pago.PagoAplicado') AND name= 'importeAplicado' 
				AND system_type_id <>TYPE_ID('VARBINARY')) 
BEGIN
	PRINT 'Cifrando datos de Pago.PagoAplicado...'

	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion

	UPDATE Pago.PagoAplicado
	SET importeAplicado_encriptado = ENCRYPTBYKEY(Key_GUID('DatosPersonas'), CONVERT (VARCHAR,importeAplicado))


	ALTER TABLE Pago.PagoAplicado
	DROP COLUMN importeAplicado

	EXEC sp_rename 'Pago.PagoAplicado.importeAplicado_encriptado','importeAplicado','COLUMN'

	CLOSE SYMMETRIC KEY DatosPersonas;
	PRINT 'Pago.PagoAplicado Cifrado correctamente'
END
	COMMIT TRAN;
END TRY

BEGIN CATCH 
	ROLLBACK TRAN;
		PRINT 'No se pudo cifrar Pago.PagoAplicado'

		IF EXISTS(
			SELECT 1 
			FROM sys.columns 
			WHERE object_id = OBJECT_ID('Pago.PagoAplicado')
			AND name LIKE '%encriptado'
		)
		BEGIN
			ALTER TABLE Pago.PagoAplicado
			DROP COLUMN	importeAplicado_encriptado
		END
	END CATCH;
	GO
------------------------Modificacion de indices y constraints----------------------------------------------

IF NOT EXISTS (SELECT 1 FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID('Consorcio.Persona')
      AND type = 'UQ'
      AND name = 'UQ_Persona_CVUCBU'
)
BEGIN
	ALTER TABLE Consorcio.Persona
	ADD CONSTRAINT UQ_Persona_CVUCBU UNIQUE(CVU_CBU_hash)
END
GO

IF OBJECT_ID('Consorcio.PK_CVU_CBU','PK') IS NULL
BEGIN

	ALTER TABLE Consorcio.CuentaBancaria
	ADD CONSTRAINT PK_CVU_CBU PRIMARY KEY CLUSTERED(CVU_CBU_Hash)
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

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Pago.Pago') 
				AND name = 'IX_Pago_CBU')
BEGIN
		CREATE NONCLUSTERED INDEX IX_Pago_CBU
        ON Pago.Pago (cbuCuentaOrigen_hash)
        INCLUDE (id, fecha, importe, idFormaPago);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_Pago_Fecha'
                 AND object_id = OBJECT_ID('Pago.Pago'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Pago_Fecha
        ON Pago.Pago (fecha)
        INCLUDE (id, importe, idFormaPago, cbuCuentaOrigen);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_UF_Consorcio'
                 AND object_id = OBJECT_ID('Consorcio.UnidadFuncional'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_UF_Consorcio
        ON Consorcio.UnidadFuncional (consorcioId)
        INCLUDE (CVU_CBU, piso, departamento, numero, metrosCuadrados, porcentajeExpensas, tipo);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_Pago_Fecha'
                 AND object_id = OBJECT_ID('Pago.Pago'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Pago_Fecha
        ON Pago.Pago (fecha)
        INCLUDE (id, importe, idFormaPago, cbuCuentaOrigen);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_DetalleExpensa_Fechas_UF_Exp'
                 AND object_id = OBJECT_ID('Negocio.DetalleExpensa'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_DetalleExpensa_Fechas_UF_Exp
        ON Negocio.DetalleExpensa (primerVencimiento_hash, idUnidadFuncional, expensaId)
        INCLUDE (totalaPagar, pagosRecibidos, prorrateoOrdinario, prorrateoExtraordinario, interesMora, segundoVencimiento);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_Expensa_ConsorcioPeriodo'
                 AND object_id = OBJECT_ID('Negocio.Expensa'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Expensa_ConsorcioPeriodo
        ON Negocio.Expensa (consorcioId, fechaPeriodoAnio, fechaPeriodoMes)
        INCLUDE (id, saldoAnterior, ingresosEnTermino, ingresosAdeudados, ingresosAdelantados, egresos, saldoCierre);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
                   WHERE name = 'IX_GastoOrd_Expensa_Tipo'
                     AND object_id = OBJECT_ID('Negocio.GastoOrdinario'))
BEGIN
      CREATE NONCLUSTERED INDEX IX_GastoOrd_Expensa_Tipo
		ON Negocio.GastoOrdinario (idExpensa, tipoServicio)
       INCLUDE (importeTotal, fechaEmision, nombreEmpresaoPersona, detalle);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_PagoAplicado_Detalle'
                 AND object_id = OBJECT_ID('Pago.PagoAplicado'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_PagoAplicado_Detalle
        ON Pago.PagoAplicado (idDetalleExpensa)
        INCLUDE (idPago, importeAplicado);
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes 
               WHERE name = 'IX_PagoAplicado_Pago'
                 AND object_id = OBJECT_ID('Pago.PagoAplicado'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_PagoAplicado_Pago
        ON Pago.PagoAplicado (idPago)
        INCLUDE (idDetalleExpensa, importeAplicado);
END
GO

IF OBJECT_ID('Negocio.GastoExtraordinario','U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes 
                   WHERE name = 'IX_GastoExt_Expensa_Cuota'
                     AND object_id = OBJECT_ID('Negocio.GastoExtraordinario'))
    BEGIN
        CREATE NONCLUSTERED INDEX IX_GastoExt_Expensa_Cuota
            ON Negocio.GastoExtraordinario (idExpensa, nroCuota)
            INCLUDE (importeTotal, esPagoTotal, fechaEmision, nombreEmpresaoPersona, detalle, totalCuota);
    END
END
GO

-------------------------------------------------------------------------------------------------------------
-------------------------------------Modificacion de sp de Reportes------------------------------------------
-------------------------------------------------------------------------------------------------------------
/*
    REPORTE 1:
    Se desea analizar el flujo de caja en forma semanal
*/

IF OBJECT_ID('Reporte.sp_Reporte1_FlujoSemanal', 'P') IS NOT NULL
    DROP PROCEDURE Reporte.sp_Reporte1_FlujoSemanal
GO

CREATE or ALTER PROCEDURE Reporte.sp_Reporte1_FlujoSemanal
(
    @NombreConsorcio VARCHAR(100),
    @PeriodoAnio INT,
    @PeriodoMes INT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IdConsorcio INT;
    DECLARE @IdExpensa INT;

    -- 1. Abrimos la llave simétrica para poder leer los datos
    -- Asegúrate de que el nombre del certificado sea el correcto (con o sin el error de tipeo previo)
    OPEN SYMMETRIC KEY DatosPersonas
    DECRYPTION BY CERTIFICATE CertificadoEncriptacion;

    -- 2. Buscar la Expensa y el ID del Consorcio
    -- (La tabla Consorcio mantiene el nombre en texto plano según tu script, así que esto no cambia)
    SELECT 
        @IdConsorcio = C.id,
        @IdExpensa = E.id
    FROM Consorcio.Consorcio AS C
    INNER JOIN Negocio.Expensa AS E ON E.consorcioId = C.id
    WHERE C.nombre = @NombreConsorcio 
      AND E.fechaPeriodoAnio = @PeriodoAnio 
      AND E.fechaPeriodoMes = @PeriodoMes;

    -- 3. Validar si la Expensa fue encontrada
    IF @IdExpensa IS NULL
    BEGIN
        CLOSE SYMMETRIC KEY DatosPersonas; -- Cerramos llave antes del error
        IF @IdConsorcio IS NULL
        BEGIN
             RAISERROR('El Consorcio con nombre "%s" no fue encontrado.', 16, 1, @NombreConsorcio);
        END
        ELSE
        BEGIN
             RAISERROR('La Expensa para el Consorcio "%s" en el periodo %d/%d no fue encontrada.', 16, 1, @NombreConsorcio, @PeriodoMes, @PeriodoAnio);
        END
        RETURN;
    END;

    -- 4. Inicia la lógica de CTE con Desencriptación
    WITH EgresosCombinados AS ( 
        -- A. Gastos Ordinarios
        -- Nota: En tu script, GastoOrdinario NO encriptó fechaEmision, solo importeTotal.
        SELECT
            fechaEmision, 
            CONVERT(DECIMAL(18,2), CONVERT(VARCHAR, DECRYPTBYKEY(importeTotal))) AS Gasto_Ordinario,
            0.00 AS Gasto_Extraordinario,
            CONVERT(DECIMAL(18,2), CONVERT(VARCHAR, DECRYPTBYKEY(importeTotal))) AS Gasto_Total
        FROM Negocio.GastoOrdinario
        WHERE idExpensa = @IdExpensa 
        
        UNION ALL
        
        -- B. Gastos Extraordinarios
        -- Nota: En tu script, GastoExtraordinario SÍ encriptó fechaEmision e importeTotal.
        SELECT
            CONVERT(DATE, CONVERT(VARCHAR, DECRYPTBYKEY(fechaEmision))) AS fechaEmision, 
            0.00 AS Gasto_Ordinario,
            CONVERT(DECIMAL(18,2), CONVERT(VARCHAR, DECRYPTBYKEY(importeTotal))) AS Gasto_Extraordinario,
            CONVERT(DECIMAL(18,2), CONVERT(VARCHAR, DECRYPTBYKEY(importeTotal))) AS Gasto_Total
        FROM Negocio.GastoExtraordinario
        WHERE idExpensa = @IdExpensa
    ),
    EgresosSemanal AS ( 
        -- Agrupar los egresos por semana (Ya con los datos desencriptados)
        SELECT
            YEAR(fechaEmision) AS Anio,
            MONTH(fechaEmision) AS Mes,
            DATEPART(wk, fechaEmision) AS Semana, 
            SUM(Gasto_Ordinario) AS Gasto_Ordinario_Semanal,
            SUM(Gasto_Extraordinario) AS Gasto_Extraordinario_Semanal,
            SUM(Gasto_Total) AS Gasto_Semanal_Total
        FROM EgresosCombinados
        GROUP BY YEAR(fechaEmision), MONTH(fechaEmision), DATEPART(wk, fechaEmision)
    )
    
    -- 5. SELECT final
    SELECT
        @NombreConsorcio AS Nombre_Consorcio, 
        @IdConsorcio AS ID_Consorcio,
        @IdExpensa AS ID_Expensa,
        FORMAT(CAST(CAST(@PeriodoAnio AS VARCHAR) + '-' + CAST(@PeriodoMes AS VARCHAR) + '-01' AS DATE), 'yyyy-MM') AS Periodo,
        ES.Anio,
        ES.Mes,
        ES.Semana,

        -- Formateo de salida
        FORMAT(ES.Gasto_Ordinario_Semanal, 'N2') AS Egreso_Ordinario,
        FORMAT(ES.Gasto_Extraordinario_Semanal, 'N2') AS Egreso_Extraordinario,
        FORMAT(ES.Gasto_Semanal_Total, 'N2') AS Egreso_Semanal_Total,
        
         -- Acumulado Progresivo
        FORMAT(SUM(ES.Gasto_Semanal_Total) OVER (
            ORDER BY ES.Anio, ES.Semana
            ROWS UNBOUNDED PRECEDING
        ), 'N2') AS Acumulado_Progresivo,
        
        -- Promedio en el Periodo
        FORMAT(AVG(ES.Gasto_Semanal_Total) OVER (), 'N2') AS Promedio_Periodo
        
    FROM EgresosSemanal AS ES
    WHERE @PeriodoAnio = ES.Anio AND @PeriodoMes = ES.Mes
    ORDER BY ES.Anio, ES.Semana;

    -- 6. Cerrar la llave
    CLOSE SYMMETRIC KEY DatosPersonas;
END
GO

IF OBJECT_ID('Reporte.sp_Reporte1_FlujoSemanal', 'P') IS NOT NULL
    PRINT 'SP Para el reporte 1: Reporte.sp_Reporte1_FlujoSemanal creado con exito'
go

/*
    REPORTE 2:
    Presente el total de recaudación por mes y departamento en formato de tabla cruzada.  

*/
IF OBJECT_ID('Reporte.sp_Reporte2_RecaudacionMesDepto', 'P') IS NOT NULL
    DROP PROCEDURE Reporte.sp_Reporte2_RecaudacionMesDepto
GO

CREATE OR ALTER PROCEDURE Reporte.sp_Reporte2_RecaudacionMesDepto
    @idConsorcio INT,   
    @anio INT,    
    @incluirSinPagos BIT = 0 
AS
BEGIN
    SET NOCOUNT ON;
    /* 
       Base: pagos aplicados a detalles de expensa.
       Camino: PagoAplicado -> Pago(fecha) -> DetalleExpensa -> UF(departamento) -> Consorcio.
       Tomamos solo los pagos del año solicitado (@anio).
    */
	--Abro la clave Simetrica
	OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion;

    WITH AplicadoDes AS(
		SELECT idPago,
		idDetalleExpensa,
		--desencripto importeAplicado ya que es el valor que necesito para los calculos
		CONVERT(decimal(18,2),CONVERT(VARCHAR,DECRYPTBYKEY(importeAplicado)))AS importeAplicado
	FROM Pago.PagoAplicado
	),
	PagoDes AS(
	
	SELECT id,
	idFormaPago,
	fecha,
	cbuCuentaOrigen_hash,
	--desencripto importe
	CONVERT(decimal(18,2),CONVERT(VARCHAR,DECRYPTBYKEY(importe)))AS importe
	from Pago.Pago
	),
	Recaudacion AS
    (
        SELECT 
            uf.departamento,
            MONTH(p.fecha) AS mes,
            SUM(pa.importeAplicado) AS importe
        FROM AplicadoDes AS pa
        INNER JOIN PagoDes           AS p  ON p.id = pa.idPago
        INNER JOIN Negocio.DetalleExpensa AS de ON de.id = pa.idDetalleExpensa
        INNER JOIN Consorcio.UnidadFuncional AS uf ON uf.id = de.idUnidadFuncional
        INNER JOIN Consorcio.Consorcio       AS c  ON c.id = uf.consorcioId
        WHERE c.id = @idConsorcio
          AND YEAR(p.fecha) = @anio
        GROUP BY uf.departamento, MONTH(p.fecha)
    ),
    -- Si se pide incluir UFs sin pagos, generamos todas las combinaciones depto x mes con 0
    Base AS
    (
		SELECT 
			uf.departamento,
			r.mes,
			COALESCE(r.importe,0) AS importe
			FROM Consorcio.UnidadFuncional uf
			LEFT JOIN Recaudacion r ON r.departamento =uf.departamento
			WHERE uf.consorcioId=@idConsorcio
			AND(
			@incluirSinPagos=1 OR 
			uf.departamento IN (SELECT DISTINCT departamento FROM Recaudacion )
			)
	)
	SELECT departamento,
		ISNULL([1],0) AS Ene,
		ISNULL([2],0) AS Feb,
		ISNULL([3],0) AS Mar,
		ISNULL([4],0) AS Abr,
		ISNULL([5],0) AS May,
		ISNULL([6],0) AS Jun,
		ISNULL([7],0) AS Jul,
		ISNULL([8],0) AS Ago,
		ISNULL([9],0) AS Sep,
		ISNULL([10],0) AS Oct,
		ISNULL([11],0) AS Nov,
		ISNULL([12],0) AS Dic,
		ISNULL([1],0)+ISNULL([2],0)+ISNULL([3],0)+ISNULL([4],0)+
		ISNULL([5],0)+ISNULL([6],0)+ISNULL([7],0)+ISNULL([8],0)+
		ISNULL([9],0)+ISNULL([10],0)+ISNULL([11],0)+ISNULL([12],0) AS Total
	FROM(
		SELECT departamento,mes,importe
		FROM Base
		)AS a
		PIVOT(sum(importe) FOR mes IN 
		([1],[2],[3],[4],[5],[6],
		[7],[8],[9],[10],[11],[12])
		) AS p
    ORDER BY departamento;

CLOSE SYMMETRIC KEY DatosPersonas
END
GO

IF OBJECT_ID('Reporte.sp_Reporte2_RecaudacionMesDepto', 'P') IS NOT NULL
    PRINT 'SP Para el reporte 2: Reporte.sp_Reporte2_RecaudacionMesDepto creado con exito'
GO


--=========================================================================================================
/*
    REPORTE 3:
    Presente un cuadro cruzado con la recaudación total desagregada según su procedencia (ordinario, extraordinario, etc.) según el periodo.
*/
IF OBJECT_ID('Reporte.sp_Reporte3_RecaudacionPorProcedencia', 'P') IS NOT NULL
    DROP PROCEDURE Reporte.sp_Reporte3_RecaudacionPorProcedencia
GO
CREATE OR ALTER PROCEDURE Reporte.sp_Reporte3_RecaudacionPorProcedencia
    @idConsorcio INT = NULL, 
    @fechaDesde  DATE = NULL, 
    @fechaHasta  DATE = NULL 
AS
BEGIN
    SET NOCOUNT ON;

    IF @fechaHasta IS NULL SET @fechaHasta = CAST(GETDATE() AS DATE);

    OPEN SYMMETRIC KEY DatosPersonas
        DECRYPTION BY CERTIFICATE CertificadoEncriptacion;

    WITH Pagos AS
    (
        SELECT 
            pa.idPago,
            CAST(p.fecha AS DATE) AS fechaPago,
            YEAR(p.fecha) AS anio,
            MONTH(p.fecha) AS mes,

            -- importeAplicado desencriptado
            CONVERT(decimal(18,2), CONVERT(VARCHAR(50), DECRYPTBYKEY(pa.importeAplicado))) AS importeAplicado,

            -- prorrateos desencriptados
            CONVERT(decimal(18,6), CONVERT(VARCHAR(50), DECRYPTBYKEY(de.prorrateoOrdinario))) AS prorrateoOrdinario,
            CONVERT(decimal(18,6), CONVERT(VARCHAR(50), DECRYPTBYKEY(de.prorrateoExtraordinario))) AS prorrateoExtraordinario,
            CONVERT(decimal(18,6), CONVERT(VARCHAR(50), DECRYPTBYKEY(de.interesMora))) AS interesMora,

            uf.consorcioId
        FROM Pago.PagoAplicado pa
        INNER JOIN Pago.Pago p ON p.id = pa.idPago
        INNER JOIN Negocio.DetalleExpensa de ON de.id = pa.idDetalleExpensa
        INNER JOIN Consorcio.UnidadFuncional uf ON uf.id = de.idUnidadFuncional
        WHERE (@idConsorcio IS NULL OR uf.consorcioId = @idConsorcio)
          AND (@fechaDesde IS NULL OR CAST(p.fecha AS DATE) >= @fechaDesde)
          AND (@fechaHasta IS NULL OR CAST(p.fecha AS DATE) <= @fechaHasta)
    ),
    Distribuido AS
    (
        SELECT
            anio, mes,
            ISNULL(prorrateoOrdinario,0) AS wOrd,
            ISNULL(prorrateoExtraordinario,0) AS wExt,
            ISNULL(interesMora,0) AS wMora,
            importeAplicado
        FROM Pagos
    ),
    Partes AS
    (
        SELECT
            anio, mes,
            CASE WHEN (wOrd + wExt + wMora) > 0 
                 THEN importeAplicado * (wOrd / (wOrd + wExt + wMora))
                 ELSE 0 END AS rec_Ordinario,
            CASE WHEN (wOrd + wExt + wMora) > 0 
                 THEN importeAplicado * (wExt / (wOrd + wExt + wMora))
                 ELSE 0 END AS rec_Extraordinario,
            CASE WHEN (wOrd + wExt + wMora) > 0 
                 THEN importeAplicado * (wMora / (wOrd + wExt + wMora))
                 ELSE 0 END AS rec_Mora
        FROM Distribuido
    )

    SELECT 
        CONCAT(anio, '-', RIGHT('00' + CAST(mes AS VARCHAR(2)),2)) AS Periodo,
        SUM(rec_Ordinario) AS Ordinario,
        SUM(rec_Extraordinario) AS Extraordinario,
        SUM(rec_Mora) AS Mora,
        SUM(rec_Ordinario + rec_Extraordinario + rec_Mora) AS Total
    FROM Partes
    GROUP BY anio, mes
    ORDER BY anio, mes;

    CLOSE SYMMETRIC KEY DatosPersonas;
END;
GO
IF OBJECT_ID('Reporte.sp_Reporte3_RecaudacionPorProcedencia', 'P') IS NOT NULL
    PRINT 'SP Para el reporte 3: Reporte.sp_Reporte3_RecaudacionPorProcedencia creado con exito'
GO


--=========================================================================================================
/*
    REPORTE 4:
    Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.  
*/



IF OBJECT_ID('Reporte.sp_Reporte4_ObtenerTopNMesesGastosIngresos', 'P') IS NOT NULL
    DROP PROCEDURE Reporte.sp_Reporte4_ObtenerTopNMesesGastosIngresos
GO

CREATE PROCEDURE Reporte.sp_Reporte4_ObtenerTopNMesesGastosIngresos
    @TopN INT = 5,
    @Anio INT = NULL,
    @ConsorcioID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --Abro la key para poder usarla

    OPEN SYMMETRIC KEY DatosPersonas
	DECRYPTION BY CERTIFICATE CertificadoEncriptacion;

    
    -- Top N meses con mayores gastos
    WITH GastosPorMes AS (
        SELECT 
            YEAR(e.fechaEmision) AS Anio,
            MONTH(e.fechaEmision) AS Mes,
            SUM(e.importeTotal) AS TotalGastos
        FROM (
            -- Junto los gastos ordinarios y extraordinarios, capaz que hay una forma mas prolija
            -- Lo dejo asi por ahora pq anda
            --ORDINARIOS
            SELECT 
                ngo.idExpensa,
                ngo.fechaEmision,
                CAST(
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(ngo.importeTotal))
                    AS DECIMAL(18,2)
                ) AS importeTotal
            FROM Negocio.GastoOrdinario as ngo
            WHERE ngo.fechaEmision IS NOT NULL
            
            UNION ALL
            
            --EXTRAORDINARIOS
            SELECT 
                ge.idExpensa,
                CAST(
                        CONVERT(VARCHAR(50), DECRYPTBYKEY(ge.fechaEmision))
                        AS DATETIME
                    ),
                CAST(
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(ge.importeTotal))
                    AS DECIMAL(18,2)
                ) AS importeTotal
            FROM Negocio.GastoExtraordinario as ge
            WHERE ge.fechaEmision IS NOT NULL
        ) as e

        INNER JOIN Negocio.Expensa AS exp ON e.idExpensa = exp.id
        WHERE 
            e.fechaEmision IS NOT NULL
            -- Filtros agragados
            AND (@Anio IS NULL OR YEAR(e.fechaEmision) = @Anio)
            AND (@ConsorcioID IS NULL OR exp.consorcioId = @ConsorcioID)

        GROUP BY YEAR(e.fechaEmision), MONTH(e.fechaEmision)
    ),
    TopNGastos AS (
        SELECT TOP (@TopN)
            Anio,
            Mes,
            DATENAME(MONTH, DATEFROMPARTS(Anio, Mes, 1)) AS NombreMes,
            TotalGastos,
            'Gasto' AS Tipo
        FROM GastosPorMes
        ORDER BY TotalGastos DESC
    ),
    
    -- Top N meses con mayores ingresos
    -- Tomo los de detalle expensa en vez de los de expensa pq ahi estan los pagos que si se recibieron (creo)
    IngresosPorMes AS (
        SELECT 
            exp.fechaPeriodoAnio AS Anio,
            exp.fechaPeriodoMes AS Mes,
            --desencripto pagosRecibidos
            SUM(
                CAST(
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(de.pagosRecibidos)) --desencripto y dspues casteo
                    AS DECIMAL(18,2)
                )
            ) AS TotalIngresos
        FROM Negocio.DetalleExpensa AS de
        INNER JOIN Negocio.Expensa AS exp ON de.expensaId = exp.id
        WHERE
            de.primerVencimiento IS NOT NULL
             --desencripto pagosRecibidos
            AND CAST(
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(de.pagosRecibidos))
                AS DECIMAL(18,2)
            ) > 0
            --desencripto primerVencimiento
            AND (@Anio IS NULL OR YEAR(
                    CAST(
                        CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento))
                        AS DATETIME
                    )
                ) = @Anio)
            AND (@ConsorcioID IS NULL OR exp.consorcioId = @ConsorcioID)
        GROUP BY exp.fechaPeriodoAnio, exp.fechaPeriodoMes
    ),
    TopNIngresos AS (
        SELECT TOP (@TopN)
            Anio,
            Mes,
            DATENAME(MONTH, DATEFROMPARTS(Anio, Mes, 1)) AS NombreMes,
            TotalIngresos AS Monto,
            'Ingreso' AS Tipo
        FROM IngresosPorMes
        ORDER BY TotalIngresos DESC
    )
    
    -- Resultados combinados
    SELECT 
        Tipo,
        Anio,
        Mes,
        NombreMes,
        TotalGastos AS Monto
    FROM TopNGastos
    
    UNION ALL
    
    SELECT 
        Tipo,
        Anio,
        Mes,
        NombreMes,
        Monto
    FROM TopNIngresos
    
    ORDER BY Tipo DESC, Monto DESC;
    
CLOSE SYMMETRIC KEY DatosPersonas;

END
GO

IF OBJECT_ID('Reporte.sp_Reporte4_ObtenerTopNMesesGastosIngresos', 'P') IS NOT NULL
    PRINT 'SP Para el reporte 4: Reporte.sp_Reporte4_ObtenerTopNMesesGastosIngresos creado con exito'


GO

--=========================================================================================================

/*
    REPORTE 5:
    Obtenga los 3 (tres) propietarios con mayor morosidad. 
    Presente información de contacto y DNI de los propietarios para que la administración los pueda 
    contactar o remitir el trámite al estudio jurídico.
    CON XML
*/
IF OBJECT_ID('Reporte.sp_Reporte5_MayoresMorosos_XML', 'P') IS NOT NULL
    DROP PROCEDURE Reporte.sp_Reporte5_MayoresMorosos_XML;
GO

CREATE OR ALTER PROCEDURE Reporte.sp_Reporte5_MayoresMorosos_XML
    @idConsorcio INT,
    @fechaDesde  DATE,
    @fechaHasta  DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @fechaHasta IS NULL 
        SET @fechaHasta = CAST(GETDATE() AS DATE);

    OPEN SYMMETRIC KEY DatosPersonas
        DECRYPTION BY CERTIFICATE CertificadoEncriptacion;

    WITH DeudaPorDetalle AS 
    (
        SELECT 
            de.expensaId,
            de.idUnidadFuncional,

            -- Desencriptar la fecha
            CASE 
                WHEN ISDATE(CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento))) = 1
                    THEN CONVERT(date, CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento)))
                ELSE NULL
            END AS primerVencimiento,

            -- Desencriptar totalaPagar y pagosRecibidos
            CONVERT(decimal(18,2),
                CASE 
                    WHEN ISNUMERIC(CONVERT(VARCHAR(50), DECRYPTBYKEY(de.totalaPagar))) = 1
                        THEN CONVERT(VARCHAR(50), DECRYPTBYKEY(de.totalaPagar))
                    ELSE '0'
                END
            )
            -
            ISNULL(
                CONVERT(decimal(18,2),
                    CASE 
                        WHEN ISNUMERIC(CONVERT(VARCHAR(50), DECRYPTBYKEY(de.pagosRecibidos))) = 1
                            THEN CONVERT(VARCHAR(50), DECRYPTBYKEY(de.pagosRecibidos))
                        ELSE '0'
                    END
                ), 
            0) AS Deuda

        FROM Negocio.DetalleExpensa AS de
          WHERE 
            (@fechaDesde IS NULL OR 
                CASE 
                    WHEN ISDATE(CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento))) = 1
                        THEN CONVERT(date, CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento)))
                END >= @fechaDesde)

        AND (@fechaHasta IS NULL OR 
                CASE 
                    WHEN ISDATE(CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento))) = 1
                        THEN CONVERT(date, CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento)))
                END <= @fechaHasta)
    ),
    -- CTE: Deuda agrupada por Persona (propietario)
    DeudaPorPersona AS 
    (
        SELECT
            -- Datos personales desencriptados
            CONVERT(VARCHAR(20),  DECRYPTBYKEY(p.dni))       AS dni,
            CONVERT(VARCHAR(50),  DECRYPTBYKEY(p.nombre))    AS nombre,
            CONVERT(VARCHAR(50),  DECRYPTBYKEY(p.apellido))  AS apellido,
            CONVERT(VARCHAR(100), DECRYPTBYKEY(p.email))     AS email,
            CONVERT(VARCHAR(20),  DECRYPTBYKEY(p.telefono))  AS telefono,

            SUM(d.Deuda) AS MorosidadTotal

        FROM DeudaPorDetalle d
        INNER JOIN Consorcio.UnidadFuncional uf ON uf.id = d.idUnidadFuncional
        INNER JOIN Negocio.Expensa e            ON e.id = d.expensaId
        INNER JOIN Consorcio.Consorcio c        ON c.id = uf.consorcioId

        -- Relación por CVU/CBU HASH
        INNER JOIN Consorcio.Persona p
            ON p.CVU_CBU_hash = uf.CVU_CBU_hash

        WHERE (@idConsorcio IS NULL OR c.id = @idConsorcio)

        GROUP BY 
            CONVERT(VARCHAR(20),  DECRYPTBYKEY(p.dni)),
            CONVERT(VARCHAR(50),  DECRYPTBYKEY(p.nombre)),
            CONVERT(VARCHAR(50),  DECRYPTBYKEY(p.apellido)),
            CONVERT(VARCHAR(100), DECRYPTBYKEY(p.email)),
            CONVERT(VARCHAR(20),  DECRYPTBYKEY(p.telefono))

        HAVING SUM(d.Deuda) > 0.01
    )


    -- OUTPUT en XML (TOP 3 mayores morosos)
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

    -- Cerramos la llave simétrica
    CLOSE SYMMETRIC KEY DatosPersonas;

END
GO

IF OBJECT_ID('Reporte.sp_Reporte5_MayoresMorosos_XML', 'P') IS NOT NULL
    PRINT 'SP Para el reporte 5: Reporte.sp_Reporte5_MayoresMorosos_XML creado con exito'
GO
