-- ITBM-00001-02: Alter Users Table to Add Email Column
ALTER TABLE Users
ADD Email NVARCHAR(255) NULL;