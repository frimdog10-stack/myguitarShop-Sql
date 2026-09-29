/*
  Assignment 3
  File: YourUsername_A3.sql
*/

USE MyGuitarShop;
GO

-- Question 1: Stored Procedure spInsertProduct
IF OBJECT_ID('spInsertProduct') IS NOT NULL
    DROP PROC spInsertProduct;
GO

CREATE PROC spInsertProduct
    @CategoryID       INT,
    @ProductCode      VARCHAR(10),
    @ProductName      VARCHAR(50),
    @ListPrice        SMALLMONEY,
    @DiscountPercent  SMALLMONEY
AS
BEGIN
    IF @ListPrice < 0
        THROW 50001, 'The column for ListPrice doesn’t accept negative numbers.', 1;

    IF @DiscountPercent < 0
        THROW 50002, 'The column for DiscountPercent doesn’t accept negative numbers.', 1;

    INSERT INTO Products (CategoryID, ProductCode, ProductName, Description, ListPrice, DiscountPercent, DateAdded)
    VALUES (@CategoryID, @ProductCode, @ProductName, '', @ListPrice, @DiscountPercent, GETDATE());
END;
GO



DELETE FROM Products WHERE ProductCode = 'STRAT_99';
EXEC spInsertProduct 1, 'STRAT_99', 'Fender Stratocaster', 1200.00, 15.0;
GO

-----------------------------------------------------------------------------------------

-- Question 2: AFTER TRIGGER Products_INSERT
IF OBJECT_ID('Products_INSERT') IS NOT NULL
    DROP TRIGGER Products_INSERT;
GO

CREATE TRIGGER Products_INSERT
ON Products
AFTER INSERT
AS
BEGIN
    UPDATE Products
    SET DateAdded = GETDATE()
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID
    WHERE i.DateAdded IS NULL;
END;
GO


IF EXISTS (SELECT 1 FROM Products WHERE ProductCode = 'G5122')
    DELETE FROM Products WHERE ProductCode = 'G5122';

INSERT INTO Products (CategoryID, ProductCode, ProductName, Description, ListPrice, DiscountPercent) 
VALUES (1, 'G5122', 'Gretsch G5122 Double Cutaway Hollowbody', '', 999.99, 32);

SELECT * FROM Products WHERE ProductCode = 'G5122';
GO

-----------------------------------------------------------------------------------------


IF OBJECT_ID('Products_UPDATE') IS NOT NULL
    DROP TRIGGER Products_UPDATE;
GO

CREATE TRIGGER Products_UPDATE
ON Products
INSTEAD OF UPDATE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE DiscountPercent < 0 OR DiscountPercent > 100)
    BEGIN
        THROW 50003, 'DiscountPercent must be between 0 and 100.', 1;
    END

    UPDATE Products
    SET CategoryID = i.CategoryID,
        ProductCode = i.ProductCode,
        ProductName = i.ProductName,
        Description = i.Description,
        ListPrice = i.ListPrice,
        DiscountPercent = CASE 
                            WHEN i.DiscountPercent >= 0 AND i.DiscountPercent < 1 THEN i.DiscountPercent * 100
                            ELSE i.DiscountPercent
                          END,
        DateAdded = i.DateAdded
    FROM Products p
    JOIN inserted i ON p.ProductID = i.ProductID;
END;
GO

-- Test 3.3 and 3.4
UPDATE Products SET DiscountPercent = .25 WHERE ProductID = 1;
SELECT ProductID, DiscountPercent FROM Products WHERE ProductID = 1;

UPDATE Products SET DiscountPercent = 50 WHERE ProductID = 1;
SELECT ProductID, DiscountPercent FROM Products WHERE ProductID = 1;
GO

-----------------------------------------------------------------------------------------

-- Question 4: Security - Create Role
USE MyGuitarShop;
GO


IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'RobertHalliday')
    DROP USER RobertHalliday;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'OrderEntry' AND type = 'R')
    DROP ROLE OrderEntry;
GO

CREATE ROLE OrderEntry;
GRANT INSERT, UPDATE ON Orders TO OrderEntry;
GRANT INSERT, UPDATE ON OrderItems TO OrderEntry;
GRANT SELECT TO OrderEntry;
GO


USE master;
GO

IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'RobertHalliday')
    DROP LOGIN RobertHalliday;
GO


CREATE LOGIN RobertHalliday WITH PASSWORD = 'H3ll0B0b_Guitar!', DEFAULT_DATABASE = MyGuitarShop;
GO

USE MyGuitarShop;
GO
CREATE USER RobertHalliday FOR LOGIN RobertHalliday;
ALTER ROLE OrderEntry ADD MEMBER RobertHalliday;
GO


USE MyGuitarShop;
GO

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'RobertHalliday')
    ALTER ROLE OrderEntry DROP MEMBER RobertHalliday;

IF EXISTS (SELECT * FROM sys.database_principals WHERE name = 'OrderEntry' AND type = 'R')
    DROP ROLE OrderEntry;
GO


-- Question 7: Explanation
/*
    A. Server Role: These are security groups at the server instance level. They grant 
       broad powers like managing logins or creating databases across the entire server.
       Example: 'sysadmin' (full access) or 'securityadmin' (manages logins).

    B. Database Role: These are security groups within a specific database. They manage 
       access to specific tables, views, or procedures inside that database only.
       Example: 'db_owner' (full control of one DB) or 'db_datareader' (can read all tables).
*/