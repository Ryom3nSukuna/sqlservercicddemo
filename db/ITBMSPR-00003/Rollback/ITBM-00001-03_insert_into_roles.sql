-- ITBM-00001-03: Rollback INSERT INTO Users Table
DELETE FROM Roles WHERE UserID in (1,2)