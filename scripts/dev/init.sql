-- Create the database
IF DB_ID('DevDB') IS NULL
BEGIN
    CREATE DATABASE [DevDB];
END;
GO

-- Create admin user
CREATE LOGIN DevAdminUser WITH PASSWORD = 'DevAdmin@Secure123', CHECK_POLICY = ON;
ALTER SERVER ROLE sysadmin ADD MEMBER DevAdminUser;
GO

-- Use the [DevDB] database
USE [DevDB];
GO

-- Map the login to a database user in [DevDB]
CREATE USER DevAdminUser FOR LOGIN DevAdminUser;
GO

-- Grant the user db_owner permissions in [DevDB]
EXEC sp_addrolemember 'db_owner', 'DevAdminUser';
GO

CREATE TABLE ExecutedScripts (
    ScriptName NVARCHAR(255) PRIMARY KEY,
    ExecutedAt DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(50)
);
GO