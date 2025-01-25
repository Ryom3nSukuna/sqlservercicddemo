-- ITBM-00001-04: Update User Email Domain
UPDATE Users
SET Email = REPLACE(Email, '@newmail.com', '@oldmail.com')
WHERE Email LIKE '%@newmail.com';