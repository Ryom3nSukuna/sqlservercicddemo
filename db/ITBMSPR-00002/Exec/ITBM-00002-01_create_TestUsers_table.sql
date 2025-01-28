-- ITBM-00002-01: Create TestUsers Table
CREATE TABLE TestUsers (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    UserName NVARCHAR(100) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE()
);
