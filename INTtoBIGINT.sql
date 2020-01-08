/*
	Frank Gill
	2020-01-08
	Testing ALTER of column data type from INT to BIGINT
	With and without row compression
*/

/* Create table with clustered index */
DROP TABLE IF EXISTS NoCompression;

CREATE TABLE NoCompression
(RowId INT IDENTITY (1,1)
,TextCol CHAR(50)
,CharCount INT);

CREATE UNIQUE CLUSTERED INDEX IX_TranAnatomy_NoCompression ON NoCompression(RowID);

SET NOCOUNT ON;

/* Insert 1000 rows */
DECLARE @loopcount INT,
@looplimit INT;

SELECT @loopcount = 1, @looplimit = 1000;

WHILE @loopcount <= @looplimit
BEGIN

	INSERT INTO NoCompression
	(TextCol
	,CharCount)
	VALUES
	(N'Test'
	,100);

	SELECT @loopcount += 1;

END

/* ALTER CharCount column to BIGINT */
DECLARE @maxlsn NVARCHAR(46);
SELECT @maxlsn = CONCAT(N'0x',MAX([Current LSN])) FROM fn_dblog(NULL,NULL);

ALTER TABLE NoCompression
ALTER COLUMN CharCount BIGINT;

/* Return log records associated with ALTER and a count of page splits */
SELECT [Current LSN]
,[Transaction ID]
,[Transaction Name]
,Operation
,Context
,[Description]
,[Previous LSN]
,AllocUnitName
,[Page ID]
,[Slot ID]
,[Begin Time]
,[Database Name]
,[Number of Locks]
,[Lock Information]
,[New Split Page]
FROM fn_dblog(@maxlsn,NULL);


SELECT COUNT(*)
FROM fn_dblog(@maxlsn,NULL)
WHERE [New Split Page] IS NOT NULL
GO

/* Create table with index and row compression */
DROP TABLE IF EXISTS Compression;

CREATE TABLE Compression
(RowId INT IDENTITY (1,1)
,TextCol CHAR(50)
,CharCount INT);

CREATE UNIQUE CLUSTERED INDEX IX_TranAnatomy_Compression ON Compression(RowID);

ALTER TABLE [dbo].[Compression] REBUILD PARTITION = ALL
WITH 
(DATA_COMPRESSION = ROW
)

/* Insert 1000 rows */
SET NOCOUNT ON;

DECLARE @loopcount INT,
@looplimit INT;

SELECT @loopcount = 1, @looplimit = 1000;

WHILE @loopcount <= @looplimit
BEGIN

	INSERT INTO Compression
	(TextCol
	,CharCount)
	VALUES
	(N'Test'
	,100);

	SELECT @loopcount += 1;

END

/* ALTER and capture all log records associated with operation */
DECLARE @maxlsn NVARCHAR(46);
SELECT @maxlsn = CONCAT(N'0x',MAX([Current LSN])) FROM fn_dblog(NULL,NULL);

ALTER TABLE Compression
ALTER COLUMN CharCount BIGINT;

SELECT [Current LSN]
,[Transaction ID]
,[Transaction Name]
,Operation
,Context
,[Description]
,[Previous LSN]
,AllocUnitName
,[Page ID]
,[Slot ID]
,[Begin Time]
,[Database Name]
,[Number of Locks]
,[Lock Information]
,[New Split Page]
FROM fn_dblog(@maxlsn,NULL);
GO