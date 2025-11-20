

/* =========================================================================================
   3-POLITICAS DE RESPALDO (BACKUP)
========================================================================================= 

-- Propuesta
--   • Backup FULL semanal (lunes a las 00:00)
--   • Backup diferencial diario(todos los dias laborales a las 06:00 previo al horario de jornada)
--   • Backup del log cada 1 hora
--   • Retención: 14 dias
--   • RPO: 1 hora

/*
-------------------------------Politicas generales de respaldo----------------------------
Proponemos un sistema de respaldo utilizando Backup FULL, es decir, un backup completo de la base
de datos al momento de la realizacion del mismo junto con el log de transaciones.Este se 
realizaria de manera semanal fuera del horario laboral durante la noche al final de la semana.	
Cada dia, durante las mañanas previas al horario laboral se realizaria un Backup diferencial, una
copia de los objetos de la base en su estado actual y para complementarlo y reducir la perdida de 
informacion, cada hora se generara una copia del log de transaciones mientras esta en uso, reduciendo
la perdida de datos solo una hora.

Se recomienda tener guardar los Backup FULL realizados en la semana en distintos dispositivos, incluyendo 
la nube y algun dispositivo externo al hardware en funcionamiento, tal cual recomienda la estrategia 3-2-1
de respaldo.
*/