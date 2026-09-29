use MyGuitarShop;

DECLARE @totalProducts int
DECLARE @totalSales money
DECLARE @avgSales money

SELECT @totalProducts = SUM(Quantity)
FROM OrderItems

SELECT @totalSales = SUM((ItemPrice - DiscountAmount) * Quantity)
FROM OrderItems

-- calculate average using the two variables above
SET @avgSales = @totalSales / @totalProducts

PRINT 'Average Sales: ' + CAST(@avgSales as varchar)
GO


DECLARE @orderCount int
DECLARE @avgTax money

SELECT @orderCount = COUNT(*)
FROM Orders

SELECT @avgTax = AVG(TaxAmount)
FROM Orders

IF @orderCount >= 10
	PRINT 'Order count: ' + CAST(@orderCount as varchar) + '  Avg Tax Amount: ' + CAST(@avgTax as varchar)
ELSE
	PRINT 'The number of orders is less than 10'
GO


DECLARE @biggestOrder money
DECLARE @firstName varchar(50)
DECLARE @lastName varchar(50)

DECLARE @orderTotals TABLE (
	OrderID int,
	OrderTotal money
)

INSERT INTO @orderTotals
SELECT OrderID, SUM((ItemPrice - DiscountAmount) * Quantity)
FROM OrderItems
GROUP BY OrderID


SELECT TOP 1 @biggestOrder = ot.OrderTotal,
	@firstName = c.FirstName,
	@lastName = c.LastName
FROM @orderTotals ot
	JOIN Orders o ON ot.OrderID = o.OrderID
	JOIN Customers c ON o.CustomerID = c.CustomerID
ORDER BY ot.OrderTotal DESC

PRINT 'The largest order of $' + CAST(@biggestOrder as varchar) + ' was made by ' + @firstName + ' ' + @lastName
GO


BEGIN TRY
	DELETE FROM Categories
	WHERE CategoryName = 'Guitars'

	PRINT 'SUCCESS: Record was deleted.'
END TRY
BEGIN CATCH
	PRINT 'FAILURE: Record was not deleted.'
	PRINT 'Error ' + CAST(ERROR_NUMBER() as varchar) + ': ' + ERROR_MESSAGE()
END CATCH
GO


IF OBJECT_ID('findAverageSales', 'P') IS NOT NULL
	DROP PROCEDURE findAverageSales
GO

CREATE PROCEDURE findAverageSales
	@avgSales money OUTPUT
AS
	DECLARE @totalProducts int
	DECLARE @totalSales money

	SELECT @totalProducts = SUM(Quantity)
	FROM OrderItems

	SELECT @totalSales = SUM((ItemPrice - DiscountAmount) * Quantity)
	FROM OrderItems

	SET @avgSales = @totalSales / @totalProducts
GO


DECLARE @result money
EXEC findAverageSales @avgSales = @result OUTPUT
PRINT 'Average Sales: ' + CAST(@result as varchar)
GO



IF OBJECT_ID('spDeleteCategory', 'P') IS NOT NULL
	DROP PROCEDURE spDeleteCategory
GO

CREATE PROCEDURE spDeleteCategory
	@categoryName varchar(50)
AS
	BEGIN TRY
		DELETE FROM Categories
		WHERE CategoryName = @categoryName

		PRINT 'SUCCESS: ' + @categoryName + ' was deleted.'
	END TRY
	BEGIN CATCH
		PRINT 'FAILURE: Record was not deleted.'
		PRINT 'Error ' + CAST(ERROR_NUMBER() as varchar) + ': ' + ERROR_MESSAGE()
	END CATCH
GO


EXEC spDeleteCategory @categoryName = 'Guitars'
GO


GO