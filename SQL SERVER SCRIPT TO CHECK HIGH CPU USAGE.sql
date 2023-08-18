---SQL SERVER SCRIPT TO CHECK HIGH CPU USAGE---

USE [msdb]
GO

/****** Object:  Job [Alert_for_high_CPU]    Script Date: 8/11/2023 3:25:22 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 8/11/2023 3:25:22 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Alert_for_high_CPU', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'STANBICTAN\SQLDBSUPPORT', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [step1]    Script Date: 8/11/2023 3:25:22 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'set ansi_warnings on
go
set ansi_padding on
go
set quoted_identifier on
go
declare 
@usage  int,
@sub nvarchar(max),
@bod nvarchar(max)
set @usage =
(        SELECT 100-avg(record.value(''(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]'', ''INT'')) as ''Cpu Usage %''
                    FROM ( 
                        SELECT top 5 CONVERT(xml, record) AS [record],dateadd (ms,timestamp - (select ms_ticks from sys.dm_os_sys_info),getdate()) as ''Time''
                        FROM sys.dm_os_ring_buffers
                        WHERE ring_buffer_type = N''RING_BUFFER_SCHEDULER_MONITOR''
                        AND record LIKE ''%<SystemHealth>%''
                        order by time desc) AS x) ;
set @sub = (select ''SQL Server Alert System: High CPU Usage at '' + @@servername);
set @bod = (select ''DESCRIPTION: At '' + cast(getdate() as nvarchar) +'' on SQL Server '' + @@servername +'', CPU usage was '' +cast(@usage as nvarchar)+ ''%!!!!'');
IF  cast(@usage as int) > 95
begin
    exec msdb.dbo.sp_send_dbmail
    @profile_name = ''My_Profile'',
    @recipients = ''herbert.nicholas@stanbic.co.tz'',
    @subject = @sub,
    @body = @bod;
end;
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20211029, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'df24cb48-55e9-436a-a0de-56d4dd5139a3'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


