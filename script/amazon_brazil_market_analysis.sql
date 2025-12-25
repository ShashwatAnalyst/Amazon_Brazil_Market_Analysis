/*
DDL Script: Create Tables

Script Purpose:
============================================================================
	1. Creates 'amazon_brazil' schema if it does not exist.
    2. Creates tables in 'amazon_brazil' schema if not already exists.
============================================================================
*/

CREATE SCHEMA IF NOT EXISTS amazon_brazil;

CREATE TABLE IF NOT EXISTS amazon_brazil.customers (
    customer_id                   VARCHAR(100) PRIMARY KEY,
    customer_unique_id            VARCHAR(100),
    customer_zip_code_prefix      INT
);

CREATE TABLE IF NOT EXISTS amazon_brazil.orders (
    order_id      			 		VARCHAR(100) PRIMARY KEY,
    customer_id       				VARCHAR(100),
    order_status     				VARCHAR(50),
    order_purchase_timestamp 		TIMESTAMP,
    order_approved_at   			TIMESTAMP,
	order_delivered_carrier_date 	TIMESTAMP,
	order_delivered_customer_date 	TIMESTAMP,
	order_estimated_delivery_date 	TIMESTAMP
);

CREATE TABLE IF NOT EXISTS amazon_brazil.payments (
    order_id  				VARCHAR(100),
    payment_sequential 		INT,
    payment_type  			VARCHAR(50),
    payment_installments 	INT,
    payment_value  			NUMERIC
);

CREATE TABLE IF NOT EXISTS amazon_brazil.sellers (
    seller_id   			VARCHAR(100) PRIMARY KEY,
    seller_zip_code_prefix 	INT
);

CREATE TABLE IF NOT EXISTS amazon_brazil.order_items (
    order_id   			VARCHAR(100),
    order_item_id 		INT,
	product_id 			VARCHAR(100),
	seller_id  			VARCHAR(100),
	shipping_limit_date TIMESTAMP,
	price 				NUMERIC,
	freight_value 		NUMERIC
);

CREATE TABLE IF NOT EXISTS amazon_brazil.products (
    product_id           		VARCHAR(100) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_lenght       	INT,
    product_description_lenght  INT,
	product_photos_qty 			INT,
	product_weight_g 			INT,
	product_length_cm		 	INT,
	product_height_cm 			INT,
	product_width_cm 			INT
);

CREATE TABLE IF NOT EXISTS amazon_brazil.sellers (
    seller_id   			VARCHAR(100) PRIMARY KEY,
    seller_zip_code_prefix 	INT
);

CREATE TABLE IF NOT EXISTS amazon_brazil.order_items (
    order_id   			VARCHAR(100),
    order_item_id 		INT,
	product_id 			VARCHAR(100),
	seller_id  			VARCHAR(100),
	shipping_limit_date TIMESTAMP,
	price 				NUMERIC,
	freight_value 		NUMERIC
);

CREATE TABLE IF NOT EXISTS amazon_brazil.products (
    product_id           		VARCHAR(100) PRIMARY KEY,
    product_category_name       VARCHAR(100),
    product_name_lenght       	INT,
    product_description_lenght  INT,
	product_photos_qty 			INT,
	product_weight_g 			INT,
	product_length_cm		 	INT,
	product_height_cm 			INT,
	product_width_cm 			INT
);
/*
========================================================================================
DQL Script: Analysis - I

Script Purpose:
========================================================================================

	1. To simplify its financial reports, Amazon India needs to standardize 
	   payment values. Display the average payment values for each payment_type.
	   Round the average payment values to integer (no decimal) and display the 
	   results sorted in ascending order. 
*/

SELECT 
	payment_type,
	ROUND(AVG(payment_value),0) AS rounded_avg_payment
FROM amazon_brazil.payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;
/*
========================================================================================

	2. To refine its payment strategy, Amazon India wants to know the 
	   distribution of orders by payment type. Calculate the percentage 
	   of total orders for each payment type, rounded to one decimal place, 
	   and display them in descending order
*/

SELECT payment_type,
       ROUND(COUNT(DISTINCT o.order_id)*100.0/
       (SELECT COUNT(DISTINCT o.order_id)
        FROM amazon_brazil.payments p 
		JOIN amazon_brazil.orders o 
			ON p.order_id = o.order_id
        WHERE p.payment_type <> 'not_defined'),1) AS percentage_orders
FROM amazon_brazil.payments p 
JOIN amazon_brazil.orders o 
	ON p.order_id = o.order_id
WHERE p.payment_type <> 'not_defined'
GROUP BY p.payment_type
ORDER BY percentage_orders DESC;
/*
========================================================================================

	3. Amazon India seeks to create targeted promotions for products within
	   specific price ranges. Identify all products priced between 100 and 
	   500 BRL that contain the word 'Smart' in their name. 
	   Display these products, sorted by price in descending order.
*/

SELECT 
	oi.product_id,
	MAX(oi.price) AS price
FROM amazon_brazil.order_items oi 
JOIN amazon_brazil.products p 
	ON oi.product_id = p.product_id
WHERE p.product_category_name ILIKE '%Smart%'
	AND oi.price BETWEEN 100 AND 500
GROUP BY oi.product_id
ORDER BY price DESC;
/*

========================================================================================
	4. To identify seasonal sales patterns, Amazon India needs to focus on
	   the most successful months. Determine the top 3 months with the 
	   highest total sales value, rounded to the nearest integer.
*/

SELECT 
	TO_CHAR(order_purchase_timestamp,'Month') AS month,
	ROUND(SUM(oi.price + oi.freight_value),0) AS total_sales
FROM amazon_brazil.orders o 
JOIN amazon_brazil.order_items oi
	ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY month
ORDER BY total_sales DESC
LIMIT 3;

/*
========================================================================================

	5. Amazon India is interested in product categories with significant 
	   price variations. Find categories where the difference between 
	   the maximum and minimum product prices is greater than 500 BRL.	   
*/

SELECT 
	p.product_category_name,
	MAX(oi.price)-MIN(oi.price) AS price_difference
FROM amazon_brazil.order_items oi 
JOIN amazon_brazil.products p 
	ON oi.product_id = p.product_id
WHERE p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
HAVING MAX(oi.price) - MIN(oi.price) > 500
ORDER BY price_difference DESC;
/*
========================================================================================

	6. To enhance the customer experience, Amazon India wants to find which
	   payment types have the most consistent transaction amounts. Identify 
	   the payment types with the least variance in transaction amounts, 
	   sorting by the smallest standard deviation first.   
*/

SELECT 
	payment_type,
	ROUND(STDDEV(payment_value),2) AS std_deviation
FROM amazon_brazil.payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY std_deviation ASC;
/*
========================================================================================

	7. Amazon India wants to identify products that may have incomplete 
	   name in order to fix it from their end. Retrieve the list of products 
	   where the product category name is missing or contains only a single
	   character.  
*/

SELECT 
	product_id, 
	product_category_name
FROM amazon_brazil.products
WHERE product_category_name IS NULL
OR LENGTH(TRIM(product_category_name)) = 1
ORDER BY product_category_name;
/*
========================================================================================
DQL Script: Analysis - II

Script Purpose:
========================================================================================

	1. Amazon India wants to understand which payment types are most popular across 
	   different order value segments (e.g., low, medium, high). Segment order values 
	   into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, and 
	   over 1000 BRL. Calculate the count of each payment type within these ranges 
	   and display the results in descending order of count.*/
	   
WITH order_value_table AS (
SELECT order_id ,SUM(price + freight_value) AS order_value
FROM amazon_brazil.order_items
GROUP BY order_id
)

SELECT 	
	CASE WHEN ov.order_value < 200 THEN 'low'
		 WHEN ov.order_value BETWEEN 200 AND 1000 THEN 'medium'
		 ELSE 'high'
		 END AS order_value_segment,
	p.payment_type,
	COUNT(DISTINCT ov.order_id) AS count
FROM order_value_table ov
JOIN amazon_brazil.payments p 
	ON ov.order_id = p.order_id
WHERE p.payment_type <> 'not_defined'
GROUP BY order_value_segment,p.payment_type
ORDER BY count DESC;
/*
========================================================================================

	2. Amazon India wants to analyse the price range and average price for 
	   each product category. Calculate the minimum, maximum, and average 
	   price for each category, and list them in descending order by the 
	   average price.*/
	   
SELECT 
	p.product_category_name,
	MIN(oi.price) AS min_price,
	MAX(oi.price) AS max_price,
	ROUND(AVG(oi.price),2) AS avg_price
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.products p 
	ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY avg_price DESC;
/*
========================================================================================

	3. Amazon India wants to identify the customers who have placed multiple 
	   orders over time. Find all customers with more than one order, and 
	   display their customer unique IDs along with the total number of 
	   orders they have placed.*/
	   
WITH customer_orders AS (
SELECT 
	customer_id,
	COUNT(order_id) AS total_orders
FROM amazon_brazil.orders o
GROUP BY customer_id
HAVING COUNT(order_id) > 1
)
SELECT 
	c.customer_unique_id,
	co.total_orders
FROM amazon_brazil.customers c 
JOIN customer_orders co 
	ON c.customer_id = co.customer_id
ORDER BY co.total_orders DESC;
/*
========================================================================================

	4. Amazon India wants to categorize customers into different types 
	   ('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) 
	   based on their purchase history. Use a temporary table to define these categories and 
	   join it with the customers table to update and display the customer types.*/
	   
CREATE TEMP TABLE customer_type_temp AS
SELECT 
	customer_id,
	CASE WHEN COUNT(order_id) = 1 THEN 'New'
		 WHEN COUNT(order_id) BETWEEN 2 AND 4 THEN 'Returning'
		 ELSE 'Loyal'
	END AS customer_type
FROM amazon_brazil.orders
GROUP BY customer_id;

SELECT 
    c.customer_unique_id,
    ctt.customer_type
FROM amazon_brazil.customers c
JOIN customer_type_temp ctt
    ON c.customer_id = ctt.customer_id;
/*
========================================================================================

	5. Amazon India wants to know which product categories generate the most revenue.
	   Use joins between the tables to calculate the total revenue for each product 
	   category. Display the top 5 categories.
*/
	   
SELECT 
	p.product_category_name,
	ROUND(SUM(oi.price + oi.freight_value),0) AS total_revenue
FROM amazon_brazil.orders o 
JOIN amazon_brazil.order_items oi
	ON o.order_id = oi.order_id
JOIN amazon_brazil.products p
	ON oi.product_id = p.product_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;
/*
========================================================================================
DQL Script: Analysis - III

Script Purpose:
========================================================================================

	1. The marketing team wants to compare the total sales between different seasons. 
	   Use a subquery to calculate total sales for each season 
	   (Spring, Summer, Autumn, Winter) based on order purchase dates, 
	   and display the results. Spring is in the months of March, April and May. 
	   Summer is from June to August and Autumn is between September and November and 
	   rest months are Winter.*/
SELECT 
	CASE WHEN DATE_PART('month',order_purchase_timestamp) IN (3,4,5) THEN 'Spring'
		 WHEN DATE_PART('month',order_purchase_timestamp) IN (6,7,8) THEN 'Summer'
		 WHEN DATE_PART('month',order_purchase_timestamp) IN (9,10,11) THEN 'Autumn'
		 ELSE 'Winter'
		 END AS season,
	ROUND(SUM(oi.price + oi.freight_value),0) AS total_sales
FROM amazon_brazil.orders o 
JOIN amazon_brazil.order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY season
ORDER BY total_sales DESC
/*

========================================================================================

	2 . The inventory team is interested in identifying products that have sales 
	    volumes above the overall average. Write a query that uses a subquery to 
		filter products with a total quantity sold above the average quantity.*/


WITH quantity_sold AS (
SELECT 
	oi.product_id,
	COUNT(*) AS total_quantity_sold
FROM amazon_brazil.orders o 
JOIN amazon_brazil.order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY oi.product_id
)
SELECT 
	product_id,
	total_quantity_sold
FROM quantity_sold
WHERE total_quantity_sold > (
SELECT 
	AVG(total_quantity_sold) AS avg_total_quantity_sold
FROM quantity_sold
)
/*
========================================================================================

	3 . To understand seasonal sales patterns, the finance team is analysing 
		the monthly revenue trends over the past year (year 2018). Run a query to
		calculate total revenue generated each month and identify periods of peak 
		and low sales. Export the data to Excel and create a graph to visually 
		represent revenue changes across the months. 
*/

SELECT 
    TO_CHAR(month, 'Mon YYYY') AS month,
    total_revenue
FROM (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        ROUND(SUM(oi.price + oi.freight_value), 0) AS total_revenue
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi
        ON oi.order_id = o.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
      AND DATE_PART('year', o.order_purchase_timestamp) = 2018
    GROUP BY month
	ORDER BY month
) t
/*
========================================================================================

	4 . A loyalty program is being designed  for Amazon India. Create a 
		segmentation based on purchase frequency: ‘Occasional’ for customers
		with 1-2 orders, ‘Regular’ for 3-5 orders, and ‘Loyal’ for more than
		5 orders. Use a CTE to classify customers and their count and generate
		a chart in Excel to show the proportion of each segment.*/
		
WITH CTE AS (
SELECT 
	customer_id,
	CASE WHEN COUNT(order_id) <= 2 THEN 'Occasional'
		 WHEN COUNT(order_id) BETWEEN 3 AND 5 THEN 'Regular'
		 ELSE 'Loyal'
	END AS customer_type
FROM amazon_brazil.orders
GROUP BY customer_id
)
SELECT 
	customer_type,
	COUNT(*) AS count
FROM CTE
GROUP BY customer_type
/*
========================================================================================

	5 . Amazon wants to identify high-value customers to target for 
	an exclusive rewards program. You are required to rank customers 
	based on their average order value (avg_order_value) to find the
	top 20 customers.*/

SELECT 
	o.customer_id ,
	ROUND(AVG(oi.price + oi.freight_value),2) AS avg_order_value,
	RANK()OVER(ORDER BY AVG(oi.price + oi.freight_value) DESC) AS customer_rank
FROM amazon_brazil.order_items oi
JOIN amazon_brazil.orders o 
	ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY o.customer_id
ORDER BY customer_rank
LIMIT 20;
/*
========================================================================================

	6 . Amazon wants to analyze sales growth trends for its key products
		over their lifecycle. Calculate monthly cumulative sales for each 
		product from the date of its first sale. Use a recursive CTE to 
		compute the cumulative sales (total_sales) for each product month 
		by month.*/
		
WITH RECURSIVE monthly_sales AS (
    SELECT 
        oi.product_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,
        SUM(oi.price + oi.freight_value) AS monthly_sales,
        MIN(DATE_TRUNC('month', o.order_purchase_timestamp))
            OVER (PARTITION BY oi.product_id) AS first_sale_month
    FROM amazon_brazil.orders o
    JOIN amazon_brazil.order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY oi.product_id, sale_month
),
rcte AS (
    -- Anchor: first month per product
    SELECT
        product_id,
		sale_month,
		monthly_sales AS total_sales
    FROM monthly_sales
    WHERE sale_month = first_sale_month

    UNION ALL
    -- Recursive step: move forward month by month
    SELECT
        ms.product_id,
		ms.sale_month,
		rc.total_sales + ms.monthly_sales AS total_sales
    FROM rcte rc
    JOIN monthly_sales ms
        ON ms.product_id = rc.product_id
       AND ms.sale_month = rc.sale_month + INTERVAL '1 month'
)
SELECT *
FROM rcte
ORDER BY product_id, sale_month;
/*
========================================================================================

	7 . To understand how different payment methods affect monthly sales growth,
	Amazon wants to compute the total sales for each payment method and calculate
	the month-over-month growth rate for the past year (year 2018). Write query to
	first calculate total monthly sales for each payment method, then compute the
	percentage change from the previous month.*/
	
WITH monthly_sales AS (
SELECT 
	p.payment_type,
	DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,
	SUM(oi.price + oi.freight_value) AS monthly_total
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi
	ON o.order_id = oi.order_id
JOIN amazon_brazil.payments p
	ON p.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
AND DATE_PART('year', o.order_purchase_timestamp) = 2018
GROUP BY p.payment_type, sale_month
ORDER BY p.payment_type, sale_month
)
SELECT payment_type,sale_month,monthly_total,
ROUND((monthly_total - prev_month_total) * 100.0 / prev_month_total,2) AS monthly_change
FROM (
SELECT * ,
LAG(monthly_total)
		OVER(PARTITION BY payment_type) AS prev_month_total
FROM monthly_sales 
)t
/*
========================================================================================
*/



