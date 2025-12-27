/*
================================================================================
Section: DDL – Schema & Table Creation
Objective: Create required schema and tables for Amazon Brazil sales analysis
================================================================================
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
================================================================================
Section: Analysis I – Payments & Pricing Insights
Objective: Analyze payment behavior and pricing characteristics
================================================================================
*/

-- Objective: Calculate average payment value by payment type

SELECT 
	payment_type,
	ROUND(AVG(payment_value),0) AS rounded_avg_payment
FROM amazon_brazil.payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;

--================================================================================

-- Objective: Compute percentage distribution of orders by payment type

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

--================================================================================

-- Objective: Identify mid-priced products containing 'Smart' keyword

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

--================================================================================

-- Objective: Identify top 3 months by total sales value

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

--================================================================================

-- Objective: Find product categories with high price dispersion

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

--================================================================================

-- Objective: Measure payment type consistency using transaction variance

SELECT 
	payment_type,
	ROUND(STDDEV(payment_value),2) AS std_deviation
FROM amazon_brazil.payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY std_deviation ASC;

--================================================================================

-- Objective: Detect products with missing or incomplete category names

SELECT 
	product_id, 
	product_category_name
FROM amazon_brazil.products
WHERE product_category_name IS NULL
OR LENGTH(TRIM(product_category_name)) = 1
ORDER BY product_category_name;

/*
================================================================================
Section: Analysis II – Customer & Category Behavior
Objective: Analyze customer purchasing patterns and category performance
================================================================================
*/

-- Objective: Analyze payment preference across order value segments
	   
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

--================================================================================

-- Objective: Analyze price distribution and average pricing by category
	   
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

--================================================================================

-- Objective: Identify repeat customers based on order frequency
	   
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

--================================================================================

-- Objective: Classify customers into New, Returning, and Loyal segments
	   
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

--================================================================================

-- Objective: Identify top revenue-generating product categories
	   
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
================================================================================
Section: Analysis III – Time Series, Growth & Advanced Analysis
Objective: Analyze seasonal trends, growth patterns, and customer value
================================================================================
*/

-- Objective: Compare total sales across seasonal periods

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

--================================================================================

-- Objective: Identify products with above-average sales volume

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
WHERE total_quantity_sold > 
(
	SELECT 
		AVG(total_quantity_sold) AS avg_total_quantity_sold
	FROM quantity_sold
)
ORDER BY total_quantity_sold DESC;

--================================================================================

-- Objective: Analyze monthly revenue trends for year 2018

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

--================================================================================

-- Objective: Segment customers based on purchase frequency
		
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

--================================================================================

-- Objective: Rank customers by average order value to identify high-value users

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

--================================================================================

-- Objective: Compute cumulative monthly sales per product over its lifecycle
		
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

--================================================================================

-- Objective: Calculate month-over-month sales growth by payment method
	
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

--================================================================================