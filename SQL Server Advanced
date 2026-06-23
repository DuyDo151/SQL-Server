# SQL Server Advanced — Sales & Employee Analysis

## Project Overview
An advanced SQL Server project analyzing sales, employee performance, and customer profitability across multiple dimensions. This project focuses on complex SQL techniques including CTEs, window functions, scalar UDFs, stored procedures, and dynamic PIVOT — going beyond basic querying to demonstrate production-level SQL skills.

**Tools:** SQL Server, SSMS  
**Dataset:** Superstore Sales (normalized into 4 tables)  
**Records:** 9,994 orders · 793 customers · 9 employees · 1,862 products

---

## Database Schema

```
CUSTOMER (793 rows)          EMPLOYEES (9 rows)
    ID (PK)                      ID_EMPLOYEE (PK)
    NAME                         NAME
    SEGMENT                      CITY
    COUNTRY                      REGION
    CITY
    STATE                    PRODUCT (1,862 rows)
    POSTAL_CODE                  ID (PK)
    REGION                       NAME
         \                       CATEGORY
          \                      SUBCATEGORY
           \                          \
            ORDERS (9,994 rows) ───────┘
                ROW_ID (PK)
                ORDER_ID
                ORDER_DATE
                SHIP_DATE
                SHIP_MODE
                CUSTOMER_ID (FK)
                PRODUCT_ID (FK)
                ID_EMPLOYEE (FK)
                SALES
                QUANTITY
                DISCOUNT
                PROFIT
```

---

## Questions & Techniques

### Question 1 — Quarterly Sales by Product Line
**Technique:** CONCAT, DATEPART, GROUP BY, ORDER BY  
Calculate total sales for the Furniture product line grouped by quarter and year, formatted as `Q{quarter}-{year}`.

### Question 2 — Discount Tier Classification
**Technique:** CASE WHEN, GROUP BY, aggregate functions  
Classify orders into 4 discount tiers (No Discount / Low / Medium / High) and calculate order count and profit per category-tier combination.

| Tier | Discount Range |
|---|---|
| No Discount | 0% |
| Low | 0% < discount ≤ 20% |
| Medium | 20% < discount ≤ 50% |
| High | > 50% |

### Question 3 — Top Categories by Customer Segment
**Technique:** CTE, DENSE_RANK(), PARTITION BY, window functions  
Rank product categories by profit within each customer segment and return only the top 2 per segment.

### Question 4 — Employee Profit Contribution
**Technique:** Multiple CTEs, percentage calculation, ORDER BY  
For each employee, calculate each product category's profit contribution (%) relative to their total profit across all categories.

### Question 5 — Scalar UDF + Profitability Report
**Technique:** CREATE FUNCTION, scalar UDF, NULLIF, function call in SELECT  
Build a reusable scalar function `GetProfitabilityRatio(EmployeeID, Category)` returning Total Profit / Total Sales, then use it in a full report query.

### Question 6 — Stored Procedure with Date Parameters
**Technique:** CREATE PROCEDURE, parameters, BETWEEN, SET NOCOUNT ON  
Create a stored procedure that accepts EmployeeID, StartDate, and EndDate and returns sales/profit summary for that employee within the date range.

```sql
EXEC GetEmployeeSalesProfit @EmployeeID = 3, 
                            @StartDate = '2016-12-01', 
                            @EndDate = '2016-12-31';
```

### Question 7 — Dynamic PIVOT by Quarter
**Technique:** Dynamic SQL, temp tables, QUOTENAME, sp_executesql, PIVOT  
Build a stored procedure that automatically detects the 6 most recent quarters and pivots total profit by state — self-updating when new data is added.

---

## SQL Techniques Used

| Technique | Questions |
|---|---|
| CASE WHEN | Q2, Q7 |
| CTE (Common Table Expressions) | Q3, Q4 |
| Multiple CTEs chained | Q4 |
| Window Functions (DENSE_RANK, PARTITION BY) | Q3 |
| Scalar UDF (CREATE FUNCTION) | Q5 |
| Stored Procedure (CREATE PROCEDURE) | Q6, Q7 |
| Dynamic SQL + sp_executesql | Q7 |
| PIVOT | Q7 |
| Temp Tables (#table) | Q7 |
| QUOTENAME | Q7 |
| NULLIF | Q5 |
| DATEPART, CONCAT | Q1, Q7 |

---

## Sample Query — Dynamic PIVOT (Question 7)

```sql
CREATE PROCEDURE dbo.PivotStateProfitByQuarter
AS
BEGIN
    SET NOCOUNT ON;

    -- Step 1: Store the 6 most recent quarters in a temp table
    SELECT TOP 6
        'Q' + CAST(DATEPART(QUARTER, ORDER_DATE) AS VARCHAR) 
            + '-' + CAST(YEAR(ORDER_DATE) AS VARCHAR) AS QuarterLabel,
        YEAR(ORDER_DATE) AS yr,
        DATEPART(QUARTER, ORDER_DATE) AS qtr
    INTO #Last6Quarters
    FROM ORDERS
    GROUP BY YEAR(ORDER_DATE), DATEPART(QUARTER, ORDER_DATE)
    ORDER BY YEAR(ORDER_DATE) DESC, DATEPART(QUARTER, ORDER_DATE) DESC;

    -- Step 2: Build dynamic column list
    DECLARE @QuarterList   NVARCHAR(MAX) = '';
    DECLARE @SelectColumns NVARCHAR(MAX) = '';

    SELECT
        @QuarterList   = @QuarterList
                        + CASE WHEN @QuarterList   = '' THEN '' ELSE ',' END
                        + QUOTENAME(QuarterLabel),
        @SelectColumns = @SelectColumns
                        + CASE WHEN @SelectColumns = '' THEN '' ELSE ',' END
                        + 'ROUND(' + QUOTENAME(QuarterLabel) + ', 2) AS '
                        + QUOTENAME(QuarterLabel)
    FROM #Last6Quarters
    ORDER BY yr DESC, qtr DESC;

    -- Step 3: Execute dynamic SQL
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
    SELECT STATE, ' + @SelectColumns + '
    FROM (
        SELECT c.STATE,
            ''Q'' + CAST(DATEPART(QUARTER, o.ORDER_DATE) AS VARCHAR)
                 + ''-'' + CAST(YEAR(o.ORDER_DATE) AS VARCHAR) AS QuarterLabel,
            o.PROFIT
        FROM ORDERS o
        JOIN CUSTOMER c ON o.CUSTOMER_ID = c.ID
    ) AS SourceData
    PIVOT (SUM(PROFIT) FOR QuarterLabel IN (' + @QuarterList + ')) AS PivotTable
    ORDER BY STATE;
    ';

    EXEC sp_executesql @SQL;
    DROP TABLE #Last6Quarters;
END;
```

---

## Repository Structure
```
sql-advanced/
├── README.md
└── QUESTION.sql        -- All 7 questions in a single file
```

---

## How to Run
1. Create a database in SSMS
2. Import the 4 CSV files via **Tasks → Import Flat File:**
   - `ORDERS.csv` → table `ORDERS`
   - `CUSTOMER.csv` → table `CUSTOMER`
   - `EMPLOYEES.csv` → table `EMPLOYEES`
   - `PRODUCT.csv` → table `PRODUCT`
3. Run `QUESTION.sql` — questions can be run independently or sequentially
