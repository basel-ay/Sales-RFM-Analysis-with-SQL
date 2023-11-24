show databases;
use sql_tutorial;

DESCRIBE sales_dataset;

UPDATE sales_dataset
SET ORDERDATE = STR_TO_DATE(ORDERDATE, '%m/%d/%Y %H:%i');

-- Inspecting the dataset
SELECT * FROM sales_dataset;

-- Checking the unique values
SELECT DISTINCT Status FROM sales_dataset;
SELECT DISTINCT Year_ID FROM sales_dataset;
SELECT DISTINCT ProductLine FROM sales_dataset;
SELECT DISTINCT Country FROM sales_dataset;
SELECT DISTINCT DealSize FROM sales_dataset;
SELECT DISTINCT DealSize FROM sales_dataset;
SELECT DISTINCT Territory FROM sales_dataset;

-- Grouping sales by productline, year_id and dealsize

-- by productline
SELECT productline, sum(sales) 
FROM sales_dataset
GROUP BY productline
ORDER BY 2 DESC;

-- by year_id
SELECT year_id, sum(sales) 
FROM sales_dataset
GROUP BY year_id
ORDER BY 2 DESC;

-- by dealsize
SELECT dealsize, sum(sales) 
FROM sales_dataset
GROUP BY dealsize
ORDER BY 2 DESC;

-- What is the best month for sales in a specific year? How much earned that month?

SELECT MONTH_ID, SUM(SALES) AS 'Revenue', COUNT(ORDERNUMBER) AS 'Frequency'
FROM sales_dataset
WHERE YEAR_ID = 2004
GROUP BY 1
ORDER BY 2 DESC;

-- November seems to be the month for both 2003 and 2004, what product do they sell in November, Classic I believe

SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) AS 'Revenue', COUNT(ORDERNUMBER) AS 'Frequency'
FROM sales_dataset
WHERE MONTH_ID = 11 and YEAR_ID = 2003
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

-- Who is our best customer (this could be best answered with RFM analysis)

CREATE VIEW rfm
AS
WITH rfm AS
(
	SELECT 
		CUSTOMERNAME,
        MAX(ORDERDATE) AS "last_order_date" , -- MAX per customer
        (SELECT MAX(ORDERDATE) FROM sales_dataset) AS "max_order_date", -- MAX regarding all customers
        DATEDIFF((SELECT MAX(ORDERDATE) FROM sales_dataset), MAX(ORDERDATE)) AS "Recency",
        COUNT(ORDERNUMBER) AS "Frequency",
        SUM(SALES) AS "MonetaryValue",
        AVG(SALES) AS "AvgMonetaryValue"
	FROM sales_dataset
    GROUP BY CUSTOMERNAME
),

rfm_calc AS 
(
		SELECT *,
			NTILE(4) OVER(ORDER BY Recency DESC) AS "rfm_recency", -- The more recency value the more being not valuable
            NTILE(4) OVER(ORDER BY Frequency) AS "rfm_frequency",
            NTILE(4) OVER(ORDER BY MonetaryValue) AS "rfm_monetary"
		FROM rfm
)

SELECT *, 
	rfm_recency + rfm_frequency + rfm_monetary AS "rfm_cell", -- combine as number
	CONCAT(rfm_recency, rfm_frequency, rfm_monetary) AS "rfm_cell_string" -- combine as string
FROM rfm_calc;

SELECT * FROM rfm;

SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_cell_string IN (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  -- lost customers
		WHEN rfm_cell_string IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_cell_string IN (311, 411, 331) THEN 'new customers'
		WHEN rfm_cell_string IN (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_cell_string IN (323, 333,321, 422, 332, 432) THEN 'active' -- (Customers who buy often & recently, but at low price points)
		WHEN rfm_cell_string IN (433, 434, 443, 444) THEN 'loyal'
	END AS "rfm_segment"
FROM rfm;

-- What products are most often sold together? 

SELECT
    ORDERNUMBER,
    (
        SELECT GROUP_CONCAT(DISTINCT PRODUCTCODE ORDER BY PRODUCTCODE SEPARATOR ', ')
        FROM sales_dataset AS p
        WHERE p.ORDERNUMBER = s.ORDERNUMBER
        AND p.ORDERNUMBER IN (
            SELECT ORDERNUMBER
            FROM (
                SELECT ORDERNUMBER, COUNT(*) AS rn
                FROM sales_dataset
                WHERE STATUS = 'Shipped'
                GROUP BY ORDERNUMBER
            ) m
            WHERE rn = 3
        )
        LIMIT 1 -- ensures that only one row is returned from the subquery per order
    ) AS PRODUCTCODE
FROM sales_dataset AS s;