-- Create the database
IF DB_ID('QaDB') IS NULL
BEGIN
    CREATE DATABASE [QaDB];
END;
GO

-- Create admin user
CREATE LOGIN QaAdminUser WITH PASSWORD = 'QaAdmin@Secure123', CHECK_POLICY = ON;
ALTER SERVER ROLE sysadmin ADD MEMBER QaAdminUser;
GO

USE [QaDB];
GO

-- Map the login to a database user in [QaDB]
CREATE USER QaAdminUser FOR LOGIN QaAdminUser;
GO

-- Grant the user db_owner permissions in [QaDB]
EXEC sp_addrolemember 'db_owner', 'QaAdminUser';
GO