/*
===========================================================================

Archivo 1 – item 1 a 6 

===========================================================================
*/


IF OBJECT_ID('Reporte.sp_ExportarDocumentoExpensas_Secciones1a6', 'P') IS NOT NULL
    DROP PROCEDURE Reporte.sp_ExportarDocumentoExpensas_Secciones1a6;
GO

CREATE OR ALTER PROCEDURE Reporte.sp_ExportarDocumentoExpensas_Secciones1a6
(
    @idConsorcio INT = NULL,
    @anio        INT = NULL,
    @mes         INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY DatosPersonas
        DECRYPTION BY CERTIFICATE CertificadoEncriptacion;

    ;WITH ExpensasFiltradas AS
    (
        SELECT
            e.id                        AS idExpensa,
            e.consorcioId,
            e.fechaPeriodoAnio,
            e.fechaPeriodoMes,

            -- Campos de estado financiero desencriptados
            CONVERT(DECIMAL(18,2),
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(e.saldoAnterior)))       AS saldoAnterior,
            CONVERT(DECIMAL(18,2),
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(e.ingresosEnTermino)))   AS ingresosEnTermino,
            CONVERT(DECIMAL(18,2),
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(e.ingresosAdeudados)))   AS ingresosAdeudados,
            CONVERT(DECIMAL(18,2),
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(e.ingresosAdelantados))) AS ingresosAdelantados,
            CONVERT(DECIMAL(18,2),
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(e.egresos)))             AS egresos,
            CONVERT(DECIMAL(18,2),
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(e.saldoCierre)))         AS saldoCierre,

            c.nombre                    AS NombreConsorcio,
            -- Dirección y CVU del consorcio desencriptados
            CONVERT(VARCHAR(200), DECRYPTBYKEY(c.direccion)) AS direccion,
            CONVERT(VARCHAR(50),  DECRYPTBYKEY(c.CVU_CBU))   AS CVU_CBU,
            c.metrosCuadradosTotal
        FROM Negocio.Expensa e
        INNER JOIN Consorcio.Consorcio c
            ON c.id = e.consorcioId
        WHERE
            (@idConsorcio IS NULL OR e.consorcioId = @idConsorcio)
            AND (@anio IS NULL OR e.fechaPeriodoAnio = @anio)
            AND (@mes  IS NULL OR e.fechaPeriodoMes  = @mes)
    )

    -- 1) Encabezado
    SELECT
        '1-Encabezado'          AS Seccion,
        ef.consorcioId          AS IdConsorcio,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio     AS Anio,
        ef.fechaPeriodoMes      AS Mes,
        ef.direccion            AS Campo1,  -- Dirección
        ef.CVU_CBU              AS Campo2,  -- CVU/CBU
        CAST(ef.metrosCuadradosTotal AS VARCHAR(50)) AS Campo3, -- m2 totales
        NULL                    AS Campo4,
        NULL                    AS Monto
    FROM ExpensasFiltradas ef

    UNION ALL

    -- 2) Forma de pago y vencimiento
    SELECT
        '2-FormaPago'           AS Seccion,
        ef.consorcioId          AS IdConsorcio,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio     AS Anio,
        ef.fechaPeriodoMes      AS Mes,
        'Transferencia bancaria a la cuenta del consorcio' AS Campo1,
        -- Primer vencimiento mínimo
        CONVERT(VARCHAR(10),
            MIN(
                CAST(
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento)) AS DATE
                )
            ), 23) AS Campo2,
        -- Segundo vencimiento máximo
        CONVERT(VARCHAR(10),
            MAX(
                CAST(
                    CONVERT(VARCHAR(50), DECRYPTBYKEY(de.segundoVencimiento)) AS DATE
                )
            ), 23) AS Campo3,
        NULL                    AS Campo4,
        NULL                    AS Monto
    FROM ExpensasFiltradas ef
    LEFT JOIN Negocio.DetalleExpensa de
        ON de.expensaId = ef.idExpensa
    GROUP BY
        ef.consorcioId,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio,
        ef.fechaPeriodoMes

    UNION ALL

    -- 3) Propietarios con saldo deudor
    SELECT
        '3-Deudores'            AS Seccion,
        ef.consorcioId          AS IdConsorcio,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio     AS Anio,
        ef.fechaPeriodoMes      AS Mes,

        -- Nombre y apellido desencriptados
        CONVERT(VARCHAR(100), DECRYPTBYKEY(p.nombre)) + ' ' +
        CONVERT(VARCHAR(100), DECRYPTBYKEY(p.apellido)) AS Campo1, -- Propietario

        CONCAT(uf.piso, '-', uf.departamento)           AS Campo2, -- Piso-Depto
        CAST(uf.numero AS VARCHAR(10))                  AS Campo3, -- Nº UF
        NULL                                            AS Campo4,

        -- totalaPagar desencriptado
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.totalaPagar))) AS Monto
    FROM ExpensasFiltradas ef
    INNER JOIN Negocio.DetalleExpensa de
        ON de.expensaId = ef.idExpensa
    INNER JOIN Consorcio.UnidadFuncional uf
        ON uf.id = de.idUnidadFuncional
    INNER JOIN Consorcio.Persona p
        ON p.CVU_CBU_hash = uf.CVU_CBU_hash
    WHERE
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.totalaPagar))) > 0

    UNION ALL

    -- 4) Gastos ordinarios
    SELECT
        '4-GastosOrdinarios'    AS Seccion,
        ef.consorcioId          AS IdConsorcio,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio     AS Anio,
        ef.fechaPeriodoMes      AS Mes,
        go.tipoServicio         AS Campo1,

        CONVERT(VARCHAR(200), DECRYPTBYKEY(go.nombreEmpresaoPersona)) AS Campo2,
        go.nroFactura           AS Campo3,
        CONVERT(VARCHAR(500), DECRYPTBYKEY(go.detalle))               AS Campo4,

        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(go.importeTotal)))   AS Monto
    FROM ExpensasFiltradas ef
    INNER JOIN Negocio.GastoOrdinario go
        ON go.idExpensa = ef.idExpensa

    UNION ALL

    -- 5) Gastos extraordinarios
    SELECT
        '5-GastosExtraordinarios' AS Seccion,
        ef.consorcioId          AS IdConsorcio,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio     AS Anio,
        ef.fechaPeriodoMes      AS Mes,

        CONVERT(VARCHAR(500), DECRYPTBYKEY(ge.detalle))               AS Campo1,
        CONVERT(VARCHAR(200), DECRYPTBYKEY(ge.nombreEmpresaoPersona)) AS Campo2,
        ge.nroFactura           AS Campo3,
        CASE 
            WHEN ge.nroCuota IS NOT NULL 
                THEN 'Cuota ' + CAST(ge.nroCuota AS VARCHAR(10))
            ELSE NULL
        END                     AS Campo4,

        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(ge.importeTotal)))   AS Monto
    FROM ExpensasFiltradas ef
    INNER JOIN Negocio.GastoExtraordinario ge
        ON ge.idExpensa = ef.idExpensa

    UNION ALL

    -- 6) Estado financiero
    SELECT
        '6-EstadoFinanciero'    AS Seccion,
        ef.consorcioId          AS IdConsorcio,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio     AS Anio,
        ef.fechaPeriodoMes      AS Mes,
        v.Concepto              AS Campo1,
        NULL                    AS Campo2,
        NULL                    AS Campo3,
        NULL                    AS Campo4,
        v.Importe               AS Monto
    FROM ExpensasFiltradas ef
    CROSS APPLY
    (
        VALUES
            ('SaldoAnterior',       ef.saldoAnterior),
            ('IngresosEnTermino',   ef.ingresosEnTermino),
            ('IngresosAdeudados',   ef.ingresosAdeudados),
            ('IngresosAdelantados', ef.ingresosAdelantados),
            ('Egresos',             ef.egresos),
            ('SaldoCierre',         ef.saldoCierre)
    ) AS v(Concepto, Importe);

    CLOSE SYMMETRIC KEY DatosPersonas;
END
GO

/*
===========================================================================

archivo 2 – item 7 

===========================================================================
*/

IF OBJECT_ID('Reporte.sp_ExportarDocumentoExpensas_Item7', 'P') IS NOT NULL
    DROP PROCEDURE Reporte.sp_ExportarDocumentoExpensas_Item7;
GO

CREATE OR ALTER PROCEDURE Reporte.sp_ExportarDocumentoExpensas_Item7
(
    @idConsorcio INT = NULL,
    @anio        INT = NULL,
    @mes         INT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Abrimos la llave para desencriptar
    OPEN SYMMETRIC KEY DatosPersonas
        DECRYPTION BY CERTIFICATE CertificadoEncriptacion;

    ;WITH ExpensasFiltradas AS
    (
        SELECT
            e.id                    AS idExpensa,
            e.consorcioId,
            e.fechaPeriodoAnio,
            e.fechaPeriodoMes,
            c.nombre                AS NombreConsorcio
        FROM Negocio.Expensa e
        INNER JOIN Consorcio.Consorcio c
            ON c.id = e.consorcioId
        WHERE
            (@idConsorcio IS NULL OR e.consorcioId = @idConsorcio)
            AND (@anio IS NULL OR e.fechaPeriodoAnio = @anio)
            AND (@mes  IS NULL OR e.fechaPeriodoMes  = @mes)
    )
    SELECT
        ef.consorcioId                                AS IdConsorcio,
        ef.NombreConsorcio,
        ef.fechaPeriodoAnio                           AS Anio,
        ef.fechaPeriodoMes                            AS Mes,
        ef.idExpensa                                  AS IdExpensa,
        uf.id                                         AS IdUnidadFuncional,
        uf.departamento,
        uf.piso,
        uf.numero,
        uf.metrosCuadrados,
        uf.porcentajeExpensas,

        -- Propietario (desencriptado)
        CONVERT(VARCHAR(100), DECRYPTBYKEY(p.nombre))   AS NombrePropietario,
        CONVERT(VARCHAR(100), DECRYPTBYKEY(p.apellido)) AS ApellidoPropietario,
        CONVERT(VARCHAR(8),   DECRYPTBYKEY(p.dni))      AS DNI,
        CONVERT(VARCHAR(150), DECRYPTBYKEY(p.email))    AS Email,
        CONVERT(VARCHAR(20),  DECRYPTBYKEY(p.telefono)) AS Telefono,

        -- Montos (desencriptados)
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.saldoAnteriorAbonado))) AS SaldoAnterior,
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.pagosRecibidos)))       AS PagosRecibidos,
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.totalaPagar)))          AS TotalAPagar,

        -- Deuda = SaldoAnterior - PagosRecibidos
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.saldoAnteriorAbonado))) 
        -
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.pagosRecibidos)))       AS Deuda,

        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.prorrateoOrdinario)))   AS ExpensasOrdinarias,
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.prorrateoExtraordinario))) AS ExpensasExtraordinarias,
        CONVERT(DECIMAL(18,2),
                CONVERT(VARCHAR(50), DECRYPTBYKEY(de.interesMora)))          AS InteresMora,

        -- Vencimientos (desencriptados)
        CAST(CONVERT(VARCHAR(50), DECRYPTBYKEY(de.primerVencimiento)) AS DATE)  AS PrimerVencimiento,
        CAST(CONVERT(VARCHAR(50), DECRYPTBYKEY(de.segundoVencimiento)) AS DATE) AS SegundoVencimiento

    FROM ExpensasFiltradas ef
    INNER JOIN Negocio.DetalleExpensa de
        ON de.expensaId = ef.idExpensa
    INNER JOIN Consorcio.UnidadFuncional uf
        ON uf.id = de.idUnidadFuncional
    -- Join por HASH del CVU/CBU (post-cifrado)
    INNER JOIN Consorcio.Persona p
        ON p.CVU_CBU_hash = uf.CVU_CBU_hash
    ORDER BY
        ef.consorcioId,
        ef.fechaPeriodoAnio,
        ef.fechaPeriodoMes,
        uf.id;

    CLOSE SYMMETRIC KEY DatosPersonas;
END
GO


-- EJECUCION CSV 1

EXEC Reporte.sp_ExportarDocumentoExpensas_Secciones1a6
    @idConsorcio = 1,
    @anio        = 2025,
    @mes         = 5;

    
-- EJECUCION CSV 2

EXEC Reporte.sp_ExportarDocumentoExpensas_Item7
    @idConsorcio = 1,
    @anio        = 2025,
    @mes         = 5;


