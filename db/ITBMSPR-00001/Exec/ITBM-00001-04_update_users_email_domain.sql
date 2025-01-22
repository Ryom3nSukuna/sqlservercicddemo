-- ITBM-00001-04: Update User Email Domain
UPDATE Users
SET Email = REPLACE(Email, '@oldmail.com', '@newmail.com')
WHERE Email LIKE '%@oldmail.com';