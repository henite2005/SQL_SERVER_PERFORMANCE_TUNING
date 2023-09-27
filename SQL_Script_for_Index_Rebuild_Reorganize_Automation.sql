---SQL Script for Index Rebuild/Reorganize Automation---

create procedure usp_Index_Reorg_Automation 
as 
begin 


DECLARE @sql VARCHAR(8000)
DECLARE @Index_Name VARCHAR(500)
DECLARE @Table_View VARCHAR(8000)
declare @table_schema varchar(100)


DECLARE Index_Cursor CURSOR FOR

--Collects all Indexes with Fragmentation >25%

SELECT 
I.name as 'Index',
S.name as 'Schema',
T.name as 'Table'
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
INNER JOIN sys.schemas S on T.schema_id = S.schema_id
INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
AND DDIPS.index_id = I.index_id
WHERE DDIPS.database_id = DB_ID()
and I.name is not null
AND DDIPS.avg_fragmentation_in_percent between 5 AND 25
ORDER BY DDIPS.avg_fragmentation_in_percent desc, page_count desc


OPEN Index_Cursor

FETCH NEXT FROM Index_Cursor INTO @Index_Name, @table_schema, @Table_View

WHILE @@FETCH_STATUS = 0

BEGIN

SET @sql = '


ALTER INDEX '+ @index_name +' on  '+ @table_schema +'.'+ @table_view +' REORGANIZE 

'


--PRINT(@sql)
EXEC(@sql)

FETCH NEXT FROM Index_Cursor INTO @Index_Name, @table_schema, @Table_View

END

CLOSE Index_Cursor
DEALLOCATE Index_Cursor

END

