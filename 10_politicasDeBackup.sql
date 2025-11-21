

/* =========================================================================================
   3-POLITICAS DE RESPALDO (BACKUP)
========================================================================================= 

-- Propuesta
--   • Backup FULL semanal (lunes a las 00:00)
--   • Backup diferencial diario(todos los dias laborales a las 06:00 previo al horario de jornada)
--   • Backup del log cada 1 hora
--   • Retención: 
		FULL semanal: 14 dias,
		FULL mensual: 1 año,
		FULL anual:	5 años
		diferenciales: 7 dias
--   • RPO: 1 hora

/*
-------------------------------Politicas generales de respaldo----------------------------
Proponemos un sistema de respaldo utilizando Backup FULL, es decir, un backup completo de la base
de datos al momento de la realizacion del mismo junto con el log de transaciones. Este se 
realizaria de manera semanal fuera del horario laboral durante la noche al final de la semana.	
Cada dia, durante las mañanas previas al horario laboral se realizaria un Backup diferencial, una
copia de los objetos de la base en su estado actual y para complementarlo y reducir la perdida de 
informacion, cada hora se generara una copia del log de transaciones mientras esta en uso, reduciendo
asi la perdida de datos(RPO) solo una hora previa al ultimo backup realizado en el dia.

Se recomienda guardar los Backup FULL realizados en la semana en distintos dispositivos, incluyendo 
la nube y algun dispositivo de almacenamiento externo al hardware en funcionamiento, tal cual recomienda la estrategia 3-2-1
de respaldo.

-----------------------------Respaldo de reportes generados-------------------------------
Los reportes generados se respaldaran junto con los backups FULL mensuales de la base. La retencion de los backup de 
estos reportes seran de 1 año, con el fin de tener un historial completo de los mismos a lo largo del año.

*/