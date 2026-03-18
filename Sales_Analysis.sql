--- 1.CREATING TABLE

CREATE TABLE sales_store (
transaction_id VARCHAR(15),
customer_id VARCHAR(15),
customer_name VARCHAR(30),
customer_age INT,
gender VARCHAR(15),
product_id VARCHAR(15),
product_name VARCHAR(15),
product_category VARCHAR(15),
quantiy INT,
prce FLOAT,
payment_mode VARCHAR(15),
purchase_date DATE,
time_of_purchase TIME,
status VARCHAR(15)
);

SELECT * FROM sales_store

---- 2. Using BULK INSERT to load data to table SALES_STORE by setting date formate to YYYY-MM-DD 


SET DATEFORMAT dmy
BULK INSERT sales_store
FROM'C:\Users\DELL\Downloads\sales_store.csv'
   WITH (
        FIRSTROW=2,
        FIELDTERMINATOR=',',
        ROWTERMINATOR='\n'
   );


--- 3. Coping same table to make changes 

SELECT * INTO sales FROM sales_store
SELECT * FROM sales

--- 4.Data Cleaning

--Step 1: Check for duplicate

SELECT transaction_id,COUNT(*)
FROM sales
GROUP BY transaction_id
HAVING COUNT (transaction_id) >1

TXN240646
TXN342128
TXN855235
TXN981773 -- Four duplicate transaction_id

-- Another method using Windows function with CTE

WITH CTE AS (
SELECT *,
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_id) AS Row_Num
FROM sales
)
--DELETE FROM CTE
--WHERE Row_Num=2
SELECT * FROM CTE
WHERE transaction_id IN ('TXN240646','TXN342128','TXN855235','TXN981773')

--- Duplicate transcation_id with Complete details are deleted

--- Step 2: Correction of Headers (quantiy and prce)
SELECT * FROM sales

EXEC sp_rename 'sales.quantiy','quantity','COLUMN'
EXEC sp_rename 'sales.prce','price','COLUMN'

--- Step 3: Check Datatype

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='sales'

--- Step 4: To checck null values
-- to check null count

DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = STRING_AGG(
     'SELECT ''' + COLUMN_NAME + ''' AS ColumnName,
     COUNT(*) AS NullCount
     FROM ' + QUOTENAME(TABLE_SCHEMA) + '.sales
     WHERE ' + QUOTENAME(COLUMN_NAME) + ' IS NULL',
     ' UNION ALL '

)
WITHIN GROUP (ORDER BY COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sales';

--- Execute the dynamic SQL
EXEC sp_executesql @SQL;

-- Treating null values

SELECT *
FROM sales
WHERE transaction_id IS NULL
OR
customer_id IS NULL
OR
customer_name IS NULL
OR
customer_age IS NULL
OR
gender IS NULL
OR 
payment_mode IS NULL
OR
price is null
OR
product_category is null
OR
product_id is null
OR
product_name is null
OR
purchase_date is null
OR
quantity is null
OR
status is null
OR
time_of_purchase is null
OR
transaction_id is null

---First record seems completely outlier it as no records to better to drop

DELETE FROM sales
WHERE transaction_id IS NULL

--- Filling null values

SELECT * FROM sales
WHERE customer_name='Ehsaan Ram'

UPDATE sales
SET customer_id='CUST9494'
WHERE transaction_id='TXN977900'


SELECT * FROM sales
WHERE customer_name='Damini Raju'

UPDATE sales
SET customer_id='CUST1401'
WHERE transaction_id='TXN985663'

SELECT * FROM sales
WHERE customer_id='CUST1003'

UPDATE sales
SET customer_name='Mahika Saini',customer_age='35',gender='Male'
WHERE transaction_id='TXN432798'


SELECT * FROM sales

--- Step 5: Cleaning Columns which are inconsistence (gender, payment_mode)
---gender
SELECT DISTINCT gender
FROM sales

UPDATE sales
SET gender='M'
WHERE gender='Male'


UPDATE sales
SET gender='F'
WHERE gender='Female'

---payment_mode
SELECT DISTINCT payment_mode
FROM sales

UPDATE sales
SET payment_mode='Credit Card'
WHERE payment_mode='CC'


---Step 6:Data Analysis

--- A) What are the top 5 Most selling products by quantity?
SELECT * FROM sales
SELECT DISTINCT status
from sales

SELECT TOP 5 product_name, SUM(quantity) AS total_quantity_sold
FROM sales
WHERE status ='delivered'
GROUP BY product_name
ORDER BY total_quantity_sold DESC

--Business problem: We don't know which products are most in demand

--Business impact: Helps priorities stock and boost through targeted promotions

-----------------------------------------------------------------------------------------------------------------

--- B) Which products are most frequently canceled?

SELECT TOP 5 product_name, COUNT(*) AS total_cancelled
FROM sales
WHERE status='cancelled'
GROUP BY product_name
ORDER BY total_cancelled DESC

-- Business problem: Frequent cancellations affect revenue and customer trust

-- Business impact: Identify poor performing product and improve quality or remove from catalog
---------------------------------------------------------------------------------------------------------------------

--- C) What time of the day has the highest number of purchase?

SELECT * FROM sales

   SELECT
       CASE
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
       END AS time_of_day,
       COUNT(*) AS total_order
   FROM sales
   GROUP BY
       CASE
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
          WHEN DATEPART(HOUR,time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
       END
ORDER BY total_order DESC

-- Business problem solved : Find peak sales time

-- Business Impact: Optimize staffing, promotions and server loads.

-------------------------------------------------------------------------------------------------------------------

-- D) Who are top 5 highest spending customers?

SELECT * FROM sales

SELECT TOP 5 customer_name,
    FORMAT (SUM(price*quantity),'C0','en-IN') AS total_spent
 FROM sales
GROUP BY customer_name
ORDER BY SUM(price*quantity) DESC

-- Business problem solved: Identify VIP customer

-- Business Impact: Personalized offers, loyalty rewards, and offers for retention

---------------------------------------------------------------------------------------------------------------------

--E) Which product categories generate the highest revenue?

SELECT * FROM sales

SELECT 
     product_category,
     FORMAT (SUM(price*quantity),'C0','en-IN') Revenue
FROM sales
GROUP BY product_category
ORDER BY SUM(price*quantity) DESC

-- Business  problem: Identify Top performing product categories

-- Business Impact: Refine product strategy, supply chain, and promotions.
-- allowing the business to invest more in high-margin or high-demand categories

---------------------------------------------------------------------------------------------------------------

-- F) What is the return/cancellation rate per product category?

SELECT * FROM sales
-- cancellation
SELECT product_category,
     FORMAT(COUNT(CASE WHEN status='cancelled' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS cancelled_percent
FROM sales
GROUP BY product_category
ORDER by cancelled_percent DESC

-- Return
SELECT product_category,
     FORMAT(COUNT(CASE WHEN status='returned' THEN 1 END)*100.0/COUNT(*),'N3')+' %' AS returned_percent
FROM sales
GROUP BY product_category
ORDER by returned_percent DESC

-- Business Problem:  Monitor dissatisfaction trends per category.

-- Business Impact:  Reduce returns, improve product descriptions/ expectations.
-- Helps identify and fix product or logistics issues.

------------------------------------------------------------------------------------------------------------------------------

-- G) What is the most preferred payment mode?

SELECT * FROM sales

SELECT payment_mode, COUNT(Payment_mode) AS total_count
FROM sales
GROUP BY payment_mode
ORDER BY total_count DESC

-- Bussiness problem: Know which payment options customers prefer the most.

-- Business Impact: Streamline payment processing, prioritize popular modes.

---------------------------------------------------------------------------------------------------------------------------------

-- H) How does age group affect purchasing behaviour?

SELECT * FROM sales
--SELECT MIN(customer_age),MAX(customer_age)
--FROM sales

SELECT 
    CASE
       WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
       WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
       WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
       ELSE '51+'
    END AS customer_age,
    FORMAT(SUM(price*quantity),'C0','en-IN') AS total_purchase
FROM sales
GROUP BY CASE
       WHEN customer_age BETWEEN 18 AND 25 THEN '18-25'
       WHEN customer_age BETWEEN 26 AND 35 THEN '26-35'
       WHEN customer_age BETWEEN 36 AND 50 THEN '36-50'
       ELSE '51+'
    END
ORDER BY SUM(price*quantity) DESC

-- Business problem solved: Understand customer demographics.

-- Business Impact: Targeted marketing and product recommendations by age group.

------------------------------------------------------------------------------------------------------------------------------------------
-- I) What's the montly sales trend?

SELECT * FROM sales

--Method 1:


SELECT 
     FORMAT(purchase_date,'yyyy-MM') AS Month_Year,
      FORMAT(SUM(price*quantity),'C0','en-IN') AS total_sales,
     SUM(quantity) AS total_quantity
FROM sales
GROUP BY FORMAT(purchase_date,'yyyy-MM')

--Method 2:(Using year and month function to extract from purchase date column)

SELECT * FROM sales

     SELECT 
          YEAR(purchase_date) AS Years,
          MONTH(purchase_date) AS Months,
          FORMAT(SUM(price*quantity),'C0','en-IN') AS total_sales,
          SUM(quantity) AS total_quantity
FROM sales 
GROUP BY YEAR(purchase_date),MONTH(purchase_date)
ORDER BY Months

-- Business problem: Sales fluctuations go unnoticed.

-- Business Impact: Plan inventory and marketing according to seasonal trends.

-----------------------------------------------------------------------------------------------------------------------------

-- J) Are certain genders buying more specific product categories?

SELECT * FROM sales

--Method 1:

SELECT gender,product_category,COUNT(product_category) AS total_purchase
FROM sales
GROUP BY gender,product_category
ORDER BY gender

--Method 2: (For better view use pivoting formate)
SELECT *
FROM (
    SELECT gender, product_category
    FROM sales
    ) AS source_table
PIVOT (
    COUNT(gender)
    FOR gender IN ([M],[F])
    ) AS pivot_table
ORDER BY product_category

-- Business problem solved: Gender-based product preference.

-- Business Impact: Personalized ads, gender-focus campaigns.


 


