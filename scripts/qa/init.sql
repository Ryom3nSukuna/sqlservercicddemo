-- Create the database
IF DB_ID('QaDB') IS NULL
BEGIN
    CREATE DATABASE [QaDB];
END;
GO

-- Create admin login only if it doesn't already exist
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'QaAdminUser')
BEGIN
    CREATE LOGIN QaAdminUser WITH PASSWORD = 'QaAdmin@Secure123', CHECK_POLICY = ON;
    ALTER SERVER ROLE sysadmin ADD MEMBER QaAdminUser;
END;
GO

-- Use the QA database
USE [QaDB];
GO

-- Create the database user only if it doesn't already exist
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'QaAdminUser')
BEGIN
    CREATE USER QaAdminUser FOR LOGIN QaAdminUser;
    EXEC sp_addrolemember 'db_owner', 'QaAdminUser';
END;
GO

-- Create the ExecutedScripts table only if it doesn't already exist
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_NAME = 'ExecutedScripts' AND TABLE_SCHEMA = 'dbo')
BEGIN
    CREATE TABLE ExecutedScripts (
        ScrID INT IDENTITY(1,1) PRIMARY KEY,
        ScriptName NVARCHAR(255) NOT NULL UNIQUE,
        Status NVARCHAR(50),
        ExecutionTime DATETIME,
        RollbackTime DATETIME,
        ErrorDetails NVARCHAR(MAX)
    );
END;
GO
