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
DQL Script: Analysis - I

Script Purpose:
========================================================================================
	1. To simplify its financial reports, Amazon India needs to standardize payment values.
	   Display the average payment values for each payment_type.
  	   Round the average payment values to integer (no decimal)
       and display the results sorted in ascending order. 
*/

SELECT payment_type,ROUND(AVG(payment_value),0) AS rounded_avg_payment
FROM amazon_brazil.payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;
/*
========================================================================================
	2. To refine its payment strategy, 
	   Amazon India wants to know the distribution of orders by payment type. 
	   Calculate the percentage of total orders for each payment type, 
	   rounded to one decimal place, and display them in descending order
*/

SELECT payment_type,
       ROUND(COUNT(DISTINCT order_id)*100.0/
       (SELECT COUNT(DISTINCT order_id)
        FROM amazon_brazil.payments
        WHERE payment_type <> 'not_defined'),1) AS percentage_orders
FROM amazon_brazil.payments
WHERE payment_type <> 'not_defined'
GROUP BY payment_type
ORDER BY percentage_orders DESC;
/*
========================================================================================
	3. Amazon India seeks to create targeted promotions for products within specific price ranges. 
   	   Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name. 
	   Display these products, sorted by price in descending order.
*/

SELECT 
	oi.product_id,
	MAX(oi.price) AS price
FROM amazon_brazil.order_items oi 
JOIN amazon_brazil.products p 
	ON oi.product_id = p.product_id
WHERE p.product_category_name ILIKE '%smart%'
	AND oi.price BETWEEN 100 AND 500
GROUP BY oi.product_id
ORDER BY price DESC;

/*
========================================================================================
	4.

