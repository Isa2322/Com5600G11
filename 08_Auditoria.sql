USE [Com5600G11]
GO

-------------------------------------------------------------------------
-- 1. AUDITORÍA DE MIEMBROS (¿Quién pertenece a qué Rol?)
-------------------------------------------------------------------------
PRINT '>>> REPORTE DE MIEMBROS DE ROLES:'

SELECT 
    Rol.name AS [Rol],
    Miembro.name AS [Usuario],
    Miembro.type_desc AS [Tipo de Usuario]
FROM sys.database_role_members AS DRM
INNER JOIN sys.database_principals AS Rol 
    ON DRM.role_principal_id = Rol.principal_id
INNER JOIN sys.database_principals AS Miembro 
    ON DRM.member_principal_id = Miembro.principal_id
WHERE Rol.is_fixed_role = 0 
ORDER BY Rol.name;

PRINT ''
PRINT '-------------------------------------------------------------------------'

-------------------------------------------------------------------------
-- 2. AUDITORÍA DE PERMISOS (¿Qué puede hacer cada Rol?)
-------------------------------------------------------------------------
PRINT '>>> REPORTE DE PERMISOS EFECTIVOS:'

SELECT 
    dp.name AS [Rol / Usuario],
    perms.state_desc AS [Estado],       -- GRANT o DENY
    perms.permission_name AS [Permiso], -- SELECT, UPDATE, EXECUTE...
    perms.class_desc AS [Tipo],         -- SCHEMA, OBJECT, etc.
    
    -- Resuelve el nombre ya sea un Esquema o una Tabla
    CASE 
        WHEN perms.class_desc = 'SCHEMA' THEN s.name
        WHEN perms.class_desc = 'OBJECT_OR_COLUMN' THEN obj.name
        ELSE 'Otro' 
    END AS [Sobre (Objeto/Esquema)]

FROM sys.database_permissions AS perms
INNER JOIN sys.database_principals AS dp 
    ON perms.grantee_principal_id = dp.principal_id
LEFT JOIN sys.objects AS obj 
    ON perms.major_id = obj.object_id AND perms.class_desc = 'OBJECT_OR_COLUMN'
LEFT JOIN sys.schemas AS s 
    ON perms.major_id = s.schema_id AND perms.class_desc = 'SCHEMA'

-- Filtro para ver solo tus roles (ignora dbo, public, sys, etc.)
WHERE dp.is_fixed_role = 0 
  AND dp.name NOT IN ('public', 'dbo', 'guest', 'sys', 'INFORMATION_SCHEMA')

ORDER BY [Rol / Usuario], [Tipo], [Sobre (Objeto/Esquema)];
GO