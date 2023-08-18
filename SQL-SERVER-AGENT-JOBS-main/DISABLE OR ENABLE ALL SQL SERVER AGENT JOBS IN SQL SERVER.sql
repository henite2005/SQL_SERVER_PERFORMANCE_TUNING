---HOW TO DISABLE OR ENABLE ALL SQL SERVER AGENT JOBS IN SQL SERVER---

STEP-1: Get Information for all SQL Server Agent Jobs 

USE [msdb]
GO 
SELECT * FROM dbo.sysjobs

STEP-2: Disable/Enable Jobs. Generate Scripts for Enable/Disable 

SELECT 'EXEC msdb.dbo.sp_update_job @job_name = ''' + name + N''', @enabled = 1;' 
FROM dbo.sysjobs
