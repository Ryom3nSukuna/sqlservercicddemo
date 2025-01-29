-- Create the databases
IF DB_ID('DevDB') IS NULL
BEGIN
    CREATE DATABASE [DevDB];
END;
GO

-- Create admin login only if it doesn't already exist
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'DevAdminUser')
BEGIN
    CREATE LOGIN DevAdminUser WITH PASSWORD = 'DevAdmin@Secure123', CHECK_POLICY = ON;
    ALTER SERVER ROLE sysadmin ADD MEMBER DevAdminUser;
END;
GO

-- Use the QA database
USE [DevDB];
GO

-- Create the database user only if it doesn't already exist
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'DevAdminUser')
BEGIN
    CREATE USER DevAdminUser FOR LOGIN DevAdminUser;
    EXEC sp_addrolemember 'db_owner', 'DevAdminUser';
END;
GO

-- Create a sequence for ScrID
IF NOT EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'ExecutedScriptsSequence')
BEGIN
	CREATE SEQUENCE dbo.ExecutedScriptsSequence
	AS INT
	START WITH 1
	INCREMENT BY 1
	MINVALUE 1
	NO CYCLE;
END
GO

-- Create the ExecutedScripts table only if it doesn't already exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_NAME = 'ExecutedScripts' AND TABLE_SCHEMA = 'dbo')
BEGIN
    CREATE TABLE ExecutedScripts (
        ScrID INT NOT NULL DEFAULT (NEXT VALUE FOR dbo.ExecutedScriptsSequence) PRIMARY KEY,
        ScriptName NVARCHAR(255) NOT NULL UNIQUE,
        Status NVARCHAR(50),
        ExecutionTime DATETIME,
        RollbackTime DATETIME,
        ErrorDetails NVARCHAR(MAX)
    );
END;
GO
