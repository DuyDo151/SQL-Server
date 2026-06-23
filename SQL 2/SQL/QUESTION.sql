-- QUESTION 1:
/* 
Write an SQL query to calculate the total sales for all products belonging to the 'Furniture' product line, 
grouped by quarter and year. Return two columns: Quarter_Year formatted as Q{quarter}-{year} (e.g. Q1-2014), 
and Total_Sales as the rounded total sales for that quarter. Order the results chronologically from the 
earliest to the most recent quarter.
*/
Select CONCAT('Q', DATEPART(QUARTER, o.ORDER_DATE), '-', YEAR(o.ORDER_DATE)) as Quarter_Year, ROUND(Sum(o.SALES), 2) as Total_Sales
From ORDERS o join PRODUCT p on o.PRODUCT_ID = p.ID 
where p.NAME = 'Furniture'
Group by YEAR(o.ORDER_DATE), DATEPART(QUARTER, o.ORDER_DATE) 
Order by YEAR(o.ORDER_DATE), DATEPART(QUARTER, o.ORDER_DATE);

-- QUESTION 2:
/* 
For each product category, classify orders into four discount tiers: No Discount, Low, Medium, and High. 
For each category/tier combination, calculate the total number of order lines and total profit. 
Order results by category and discount tier.

Discount level tiers:
No Discount = 0%
0% < Low Discount <= 20%
20% < Medium Discount <= 50%
High Discount > 50% 
*/
SELECT p.CATEGORY,
    CASE 
        WHEN o.discount = 0 THEN 'No Discount'
        WHEN o.discount <= 0.2 THEN 'Low Discount'
        WHEN o.discount <= 0.5 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS DISCOUNT_LEVEL,
COUNT(o.row_id) AS NUMBER_OF_ORDERS,
ROUND(SUM(o.profit), 2) AS TOTAL_PROFIT
FROM ORDERS o JOIN PRODUCT p ON o.PRODUCT_ID = p.ID
GROUP BY p.CATEGORY,
    CASE 
        WHEN o.discount = 0 THEN 'No Discount'
        WHEN o.discount <= 0.2 THEN 'Low Discount'
        WHEN o.discount <= 0.5 THEN 'Medium Discount'
        ELSE 'High Discount'
    END
ORDER BY p.CATEGORY, DISCOUNT_LEVEL;
-- QUESTION 3:
/* 
For each customer segment, aggregate total sales and total profit by product category, then rank the categories
within each segment by total profit (highest to lowest). Return only the top 2 ranked categories per segment, 
including their total sales, total profit, and profit rank.
*/
With Category_Stats as(
SELECT c.SEGMENT, p.CATEGORY, ROUND(SUM(o.SALES), 2) as TOTAL_SALES, ROUND(SUM(o.PROFIT), 2) as TOTAL_PROFIT, DENSE_RANK() OVER(PARTITION BY c.SEGMENT ORDER BY SUM(o.PROFIT) DESC) as PROFIT_RANK
From ORDERS o join CUSTOMER c on o.CUSTOMER_ID = c.ID 
join PRODUCT p on o.PRODUCT_ID = p.ID 
GROUP BY c.SEGMENT, p.CATEGORY)
select * from Category_Stats 
where PROFIT_RANK <=2;
-- QUESTION 4
/*
For each employee, calculate the total profit per product category they have sold. Then compute each category's
profit contribution (%) as its share of that employee's overall total profit across all categories. Return the 
employee ID, employee name, category, total profit, and profit contribution percentage. Order the results by 
employee, then by profit contribution percentage from highest to lowest.
*/
With Employee_category_profit as (
select e.ID_EMPLOYEE, e.NAME, p.CATEGORY, SUM(o.PROFIT) as Category_Profit
from EMPLOYEES e join ORDERS o on e.ID_EMPLOYEE = o.ID_EMPLOYEE
join PRODUCT p on o.PRODUCT_ID = p.ID
group by e.ID_EMPLOYEE, e.NAME, p.CATEGORY),
Total_employee_profit as (
select ID_EMPLOYEE, SUM(Category_Profit) as Overall_Profit
from Employee_category_profit 
group by ID_EMPLOYEE) 
select ecp.ID_EMPLOYEE, ecp.NAME, ecp.CATEGORY, ROUND(ecp.Category_Profit, 2) as TOTAL_PROFIT, ROUND((ecp.Category_Profit / tep.Overall_Profit) * 100, 2) as PROFIT_PERCENTAGE 
from Employee_category_profit ecp join Total_employee_profit tep on ecp.ID_EMPLOYEE = tep.ID_EMPLOYEE
order by ecp.ID_EMPLOYEE, PROFIT_PERCENTAGE DESC;
-- QUESTION 5:
/*
Create a scalar user-defined function that takes an employee ID and a product category as inputs and returns 
the profitability ratio, defined as Total Profit / Total Sales for that employee–category combination 
(return NULL if total sales is zero or NULL). Then use this function in a report query that returns 
each employee's ID, name, product category, total sales, total profit, and the computed profitability ratio. 
Order results by employee, then by profitability ratio from highest to lowest.
*/
if OBJECT_ID('dbo.GetProfitabilityRatio', 'FN') is not null 
drop function dbo.GetProfitabilityRatio;
Go
create function dbo.GetProfitabilityRatio (@EmployeeID INT, @Category NVARCHAR(50))
returns float
as
begin
declare @Ratio float; 
select @Ratio = 
       CASE 
            WHEN SUM(o.SALES) = 0 OR SUM(o.SALES) is NULL then NULL 
            ELSE SUM(o.PROFIT) / SUM(o.SALES) 
        END
from ORDERS o join PRODUCT p on o.PRODUCT_ID = p.ID 
where o.ID_EMPLOYEE = @EmployeeID AND p.CATEGORY = @Category;
Return @Ratio;
END;
Go
Select e.ID_EMPLOYEE, e.NAME, p.CATEGORY, ROUND(SUM(o.SALES), 2) as TOTAL_SALES, ROUND(SUM(o.PROFIT), 2) as TOTAL_PROFIT, ROUND(dbo.GetProfitabilityRatio(e.ID_EMPLOYEE, p.CATEGORY), 4) as PROFITABILITY_RATIO
from EMPLOYEES e join ORDERS o on e.ID_EMPLOYEE = o.ID_EMPLOYEE 
join PRODUCT p on o.PRODUCT_ID = p.ID
group by e.ID_EMPLOYEE, e.NAME, p.CATEGORY
Order by e.ID_EMPLOYEE, PROFITABILITY_RATIO DESC;
-- QUESTION 6:
/* 
Create a stored procedure that accepts EMPLOYEE_ID, StartDate, and EndDate as parameters and returns a single 
row containing the employee's ID, name, total sales, and total profit for all orders placed within the given 
date range (inclusive on both ends). If no orders exist for that employee in the specified range, the procedure
should return no rows.
Test with: 
EXEC GetEmployeeSalesProfit @EmployeeID = 3, @StartDate = '2016-12-01', @EndDate = '2016-12-31';
*/
If OBJECT_ID('dbo.GetEmployeeSalesProfit', 'P') IS NOT NULL 
   DROP PROCEDURE dbo.GetEmployeeSalesProfit;
Go
create procedure dbo.GetEmployeeSalesProfit
  @EmployeeID INT, @StartDate DATE, @EndDate DATE 
AS
Begin 
    SET Nocount on;
select e.ID_EMPLOYEE, e.NAME as EMPLOYEE_NAME, ROUND(SUM(o.SALES), 2) as TOTAL_SALES, ROUND(SUM(o.PROFIT), 2) as TOTAL_PROFIT 
from EMPLOYEES e join ORDERS o on e.ID_EMPLOYEE = o.ID_EMPLOYEE
where e.ID_EMPLOYEE = @EmployeeID and o.ORDER_DATE Between @STARTDATE and @ENDDATE 
Group by e.ID_EMPLOYEE, e.NAME;
END;
GO
EXEC dbo.GetEmployeeSalesProfit
@EmployeeID = 3, @StartDate = '2016-12-01', @EndDate = '2016-12-31';
-- QUESTION 7:
/*
Write a stored procedure using dynamic SQL that pivots total profit by the last 6 quarters found in the dataset,
with one row per state. The procedure should:
-	Automatically detect the 6 most recent quarters from the ORDERS table
-	Output one column per quarter, named in the format Q{quarter}-{year} (e.g. Q4-2017), ordered from most 
recent to oldest left to right
-	Output one row per customer STATE, showing the rounded total profit for each quarter (NULL if no orders 
existed for that state in that quarter)
-	Order rows alphabetically by state
The procedure must remain correct if new quarterly data is added in the future.
*/
IF OBJECT_ID('dbo.PivotStateProfitByQuarter', 'P') IS NOT NULL
    DROP PROCEDURE dbo.PivotStateProfitByQuarter;
GO
CREATE PROCEDURE dbo.PivotStateProfitByQuarter
AS
BEGIN
    SET NOCOUNT ON;
Select TOP 6 'Q' + CAST(DATEPART(QUARTER, ORDER_DATE) AS VARCHAR) + '-' + CAST(YEAR(ORDER_DATE) AS VARCHAR) as QuarterLabel, YEAR(ORDER_DATE) as yr, DATEPART(QUARTER, ORDER_DATE) as qtr
INTO #Last6Quarters
from ORDERS
group by YEAR(ORDER_DATE), DATEPART(QUARTER, ORDER_DATE)
order by YEAR(ORDER_DATE) DESC, DATEPART(QUARTER, ORDER_DATE) DESC; 
declare @QuarterList NVARCHAR(MAX) = '';
declare @SelectColumns NVARCHAR(MAX) = ''; 
select 
@QuarterList = @QuarterList 
                + case when @QuarterList = '' then '' else ',' End 
                + QUOTENAME(QuarterLabel), 
@SelectColumns = @SelectColumns 
                  + case when @SelectColumns = '' THEN '' else ',' end
                  + 'ROUND(' + QUOTENAME(QuarterLabel) + ',2) as '
                  + QUOTENAME(QuarterLabel) 
from #Last6Quarters
order by yr DESC, qtr DESC; 
Declare @SQL NVARCHAR(MAX); 
set @SQL = ' Select STATE, ' + @SelectColumns + '
From (
       select c.STATE, ''Q'' + CAST(DATEPART(QUARTER, o.ORDER_DATE) as VARCHAR) + ''-'' + CAST(YEAR(o.ORDER_DATE) as VARCHAR) as QuarterLabel, o.Profit 
       from ORDERS o join CUSTOMER c on o.CUSTOMER_ID = c.ID ) as SourceDATA
PIVOT(SUM(PROFIT) FOR QuarterLabel IN (' + @QuarterList + ')) as PivotTable 
Order by STATE;
'; 
EXEC sp_executesql @SQL; 
DROP TABLE #Last6Quarters
END; 
Go
EXEC dbo.PivotStateProfitByQuarter;
