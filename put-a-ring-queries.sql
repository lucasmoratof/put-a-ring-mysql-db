######## NATIONAL COLLEGE OF IRELAND ########
# Introduction to Data Analytics - CA 2
# Student number: 18184481
# -------------------------------------------
############## PLEASE READ!
# This document cannot be read at once, it won't work.
# Each query need to be run individually.
# Query number 2 was already done on the tables script, please refer to table 'stock audit' for results. The full code can be find here.
# All queries were extensively tested to perform satisfactory. If it didn't, have a break, drinks a coffee, stretch your legs and
# try again!
# ----------------------------------------
## 1. Select all the transactions for any given week 
# Date: 10 to 17/02/2018
# I decided to group by sale, that means that the same customer can appears multiple times depending if he/she made differents sales
# during that week.
# THE QUESTION MENTIONED TRANSACTIONS, SO I'VE INCLUDED SALES AND RETURNS, USING UNION ALL TO AGGREGATE INFORMATION
USE CA_2;
CREATE OR REPLACE VIEW transactions_week AS 
	SELECT 
	s.sale_id `Transaction`,
    CONCAT(c.fname, ' ', c.lname) `Customer Name`,
    SUM(p.retail_price * si.quantity) `Transaction Amount`,
    pmt.pmt_description `Payment Method`    
FROM customers c
INNER JOIN sales s ON c.customer_id = s.customer_id
INNER JOIN payments pmt ON s.payment_id = pmt.payment_id
INNER JOIN sales_items si ON s.sale_id = si.sale_id
INNER JOIN products p ON si.product_id = p.product_id    
WHERE sale_date BETWEEN CAST('2018-02-10' AS DATE) AND CAST('2018-02-17' AS DATE)
GROUP BY 1
UNION ALL
	SELECT 
	r.return_id,
    CONCAT(c.fname, ' ', c.lname),
    SUM(p.retail_price * si.quantity),
    pmt.pmt_description    
FROM customers c
INNER JOIN sales s ON c.customer_id = s.customer_id
INNER JOIN returns r ON s.sale_id = r.sale_id
INNER JOIN payments pmt ON s.payment_id = pmt.payment_id
INNER JOIN sales_items si ON s.sale_id = si.sale_id
INNER JOIN products p ON si.product_id = p.product_id    
WHERE return_date BETWEEN CAST('2018-02-10' AS DATE) AND CAST('2018-02-17' AS DATE)
GROUP BY 1; 
SELECT * FROM transactions_week;
###############################################
## 2. CREATE A TRIGGER TO UPDATE STOCK LEVELS ONCE A SALES TAKE PLACE
# Even if the question was just about the trigger, I've decided to create an audit table where the changes are stored, for analysis
# purposes. The table and trigger were also inserted in the tables script, between products and sales.
USE CA_2; 
CREATE TABLE IF NOT EXISTS stock_audit (
	id int(11) NOT NULL AUTO_INCREMENT,
    product_id varchar(4) NOT NULL,
    old_value integer(6) NOT NULL,
    new_value integer(6)NOT NULL,
    changedon datetime DEFAULT NULL,
    action varchar(50) DEFAULT NULL,
    PRIMARY KEY (id)); 

DELIMITER $$
CREATE TRIGGER before_stock_update BEFORE UPDATE ON products
    FOR EACH ROW BEGIN
    INSERT INTO stock_audit
    SET action = 'update',
		product_id = OLD.product_id,
        old_value = OLD.in_stock,
        new_value = NEW.in_stock,
        changedon = NOW();
END$$
DELIMITER ;
  
USE CA_2;
DELIMITER $$
CREATE TRIGGER stock_update 
    AFTER INSERT ON sales_items	
    FOR EACH ROW    
    BEGIN 
		UPDATE PRODUCTS
        SET in_stock = in_stock - NEW.quantity
        WHERE product_id = NEW.product_id;
END$$
DELIMITER ;
###############################################
## 3. Create a View of all stock (grouped by the supplier) 
# The company I've designed use one supplier for each product, but as the ERD was made with suppliers seppareted from products, it would
# be easy to create different suppliers for the same product, as happens in real businness.
CREATE OR REPLACE VIEW stock_by_supplier AS 
	SELECT 
    su.sup_name supplier,
    product_id,
    p.name product_name,
    p.in_stock qtt_in_stock
FROM
    products p
INNER JOIN suppliers su ON p.supplier_id = su.supplier_id
ORDER BY 1;
SELECT * FROM stock_by_supplier;
###############################################
## 4. (Stored Procedure) - Detail and total all sales for the year, group these by each month. (A Group By with RollUp)
# The trick here was to create an appropriate query to retrieve the sales, making the appropriate joins. After that, a simple
# group by month makes the hard work and returns the totals requested, with the rollup given a grand total at the end.
# I've choosen the argument year for my procedure, so it shows the months for the year indicated.
DROP PROCEDURE IF EXISTS sales_per_month;
DELIMITER //
CREATE PROCEDURE sales_per_month (IN MYYEAR integer(4))
 BEGIN
SELECT 
    MONTH(sale_date) month,
    SUM(p.retail_price * si.quantity) total_sales
FROM
    sales s
        INNER JOIN
    sales_items si ON s.sale_id = si.sale_id
        INNER JOIN
    products p ON si.product_id = p.product_id
WHERE
    YEAR(sale_date) = MYYEAR
GROUP BY MONTH(sale_date) WITH ROLLUP;
 END //
DELIMITER ;
CALL sales_per_month(2018);
###############################################
## 5. (View) - Display the growth in sales (as a percentage) for your business, from the 1st month of opening until 
# the end of the year.
#---------- COMMENTS:
## To answer this query I've opted for the steps below: 
## 1- Create a temporary table to hold information about sales grouped per mont;
## 2- Use the LAG() function, that according to mysql documentation is "Value of argument from row lagging current row within partition"
## 3- As LAG() is a WINDOW function, I've finished the query using the WINDOW, which perform an aggregate-like operation on a set of query
# rows. Differently from other aggregate functions, which normally group all the rows into one result, an WINDOW produces a result for
# each row of the query.
## More details can be found at: https://dev.mysql.com/doc/refman/8.0/en/window-functions-usage.html 
DROP TABLE IF EXISTS sales_per_month;
CREATE TABLE `sales_per_month` AS
SELECT 
	month(s.sale_date) `month`,
	SUM(p.retail_price * si.quantity) sales_amount
FROM sales s
INNER JOIN sales_items si ON s.sale_id = si.sale_id
INNER JOIN products p ON si.product_id = p.product_id
WHERE year(s.sale_date) = '2018'
GROUP BY month;
CREATE OR REPLACE VIEW `transaction_growth_2018` AS
SELECT month,
       sales_amount,
       sales_amount - lag(sales_amount, 1) OVER w as revenue_difference,
	   ROUND(((sales_amount - lag(sales_amount, 1) over w) / lag(sales_amount, 1) over w)*100) growth_percent
FROM sales_per_month	   
WINDOW w as (order by month)
ORDER BY month ASC;
SELECT * FROM `transaction_growth_2018`;
###############################################
## 6. (Stored Procedure) - Create a stored procedure that will display all orders by customer and their county.
#---------- COMMENTS:
## This procedure is very straightforward, I've just use CONCAT to return the full name of customer in one field, then use INNER JOINS
# to connect the tables involved in the operation: Customers, Sales, Sales_items and Products. 
# The argument used is customer_id.
DROP PROCEDURE IF EXISTS sales_per_customer;
DELIMITER //
CREATE PROCEDURE sales_per_customer (IN CUSTID varchar(12))
 BEGIN
SELECT 
	CONCAT(c.fname, ' ', c.lname) `Customer Name`,
    c.city,
    s.sale_id sale_number,
    s.sale_date date_of_sale,
    sum(p.retail_price * si.quantity) sale_amount
FROM
    customers c
		INNER JOIN
    sales s ON c.customer_id = s.customer_id
        INNER JOIN
    sales_items si ON s.sale_id = si.sale_id
        INNER JOIN
    products p ON si.product_id = p.product_id
WHERE
    c.customer_id = CUSTID
GROUP BY sale_number;
 END //
DELIMITER ;
CALL sales_per_customer('ct-008');
###############################################
## 7. (Stored Procedure) - Create a stored procedure that will display all returns, grouped by month.
#---------- COMMENTS:
## The logic behind the returns are the same as for sales. First, a return will have it's own primary key, but it must have a connection
# with a previous sale which is being returned. So to have a query that give the return amount, it just need to use an INNER JOIN within
# sales, sales_items and products, which will return the amount.
## However, it is important to remember that we cannot use the sales.sale_date here, as the returns have their own dates, the field 
# returns.return_date, so when grouping by month, we need to choose the appropriate data.
## I have decided to create a procedure that give returns by year, passing the MYYEAR argument, and I added also a ROLLUP, because 
# I believe it is an interesting business question to be answered.
DROP PROCEDURE IF EXISTS returns_per_month;
DELIMITER //
CREATE PROCEDURE returns_per_month (IN MYYEAR integer(4))
BEGIN
SELECT 
    MONTH(return_date) month_of_return, 
    SUM(p.retail_price * si.quantity) total_returns
FROM
    `returns` r
		INNER JOIN
    sales s ON r.sale_id = s.sale_id
        INNER JOIN
    sales_items si ON s.sale_id = si.sale_id
        INNER JOIN
    products p ON si.product_id = p.product_id
WHERE
    YEAR(return_date) = MYYEAR
GROUP BY MONTH(return_date) with rollup;
 END //
DELIMITER ;
CALL returns_per_month(2018);
###############################################
## 8. (Stored Procedure) - Display a specific customers details and all of their relevant orders to date by passing a parameter
# (eg: CustomerID).
#---------- COMMENTS:
## In my opinon this query was a good opportunity to think about what a real business would like to know about their customers, maybe to 
# use into a Machine Learning project, or just to allow the Marketing team to develop new strategies for a product. Being able to query 
# any kind of information from a Database would be, in my point of view, one of the most valuables skills a data analyst could have.
## That said, I've put in my query:
	# - Customer full name;
    # - Customer country;
	# - Date of first purchase;
    # - How many orders/sales the customer had with us;
    # - The total amount of money the customer spent in our store
DROP PROCEDURE IF EXISTS customer_detail_and_sales;
DELIMITER //
CREATE PROCEDURE customer_detail_and_sales (IN MYCUSTOMER varchar(8))
 BEGIN
SELECT 
    CONCAT(c.fname, ' ', c.lname) `Customer Name`,
    c.country,
    MIN(s.sale_date) first_purchase,
    COUNT(DISTINCT s.sale_id) count_sales,
    SUM(p.retail_price * si.quantity) total_purchases
FROM
    customers c
        INNER JOIN
    sales s ON c.customer_id = s.customer_id
        INNER JOIN
    sales_items si ON s.sale_id = si.sale_id
        INNER JOIN
    products p ON si.product_id = p.product_id
WHERE
    c.customer_id = MYCUSTOMER;
 END //
DELIMITER ; 
CALL customer_detail_and_sales('ct-010');
###############################################
# 9. (Trigger) - Create a Trigger that will populate a ‘history table’ once a customers contact details have been updated.
#---------- COMMENTS:
## For that query the logic was very similar to the query number 2. We could divide it into two parts:
	# 1 - create the table that will store the information;
    # 2 - create the trigger and reference on it the audit table create, as well as the table that the trigger will be trigged with
    ## the change.
## As the query didn't specify which contact details where the object of the query, I chose to put the address, but once the trigger is
# done, it easy to add more parameters according with the needs.
DROP TABLE IF EXISTS customers_audit;
CREATE TABLE customers_audit (
    id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    customer_name VARCHAR(50) NOT NULL,
    previous_adress VARCHAR(50) NOT NULL,
    new_address VARCHAR(50) NOT NULL,
    changedon DATETIME DEFAULT NULL,
    action VARCHAR(50) DEFAULT NULL);
    
drop trigger if exists before_ct_add_update; 
DELIMITER $$
CREATE TRIGGER before_ct_add_update 
    BEFORE UPDATE ON customers
    FOR EACH ROW BEGIN
 
    INSERT INTO customers_audit
    SET action = 'update',
     customer_id = OLD.customer_id,
	 customer_name = CONCAT(OLD.fname, ' ', OLD.lname),
     previous_adress = OLD.st_add,
     new_address = NEW.st_add,
	 changedon = NOW(); 
END$$
DELIMITER ;
UPDATE customers 
SET 
    st_add = 'Rua do Feijao, 8'
WHERE
    customer_id = 'ct-007';
###############################################
# 10. (View) - Create a View that will display a breakdown of (a) sales (b) profit and (c) returns for each month of the year.
#---------- COMMENTS:
# I've found an easy, however long, way to answer this query. First I've created 3 temporary tables:
	# 1st - sales amount per month;
    # 2nd - returns amount per month;
    # 3rd - profit amount per month.
# Then I've made a query to retrieve and calculate the information I need;
# After that, as I cannot use temporary tables to create a View, I created first a proper table, in order to be able to create a View
## from that. Probably not the smartest way to do the job, but It did the service!
DROP TEMPORARY TABLE IF EXISTS sales_month;
CREATE TEMPORARY TABLE sales_month
SELECT 
	month(s.sale_date) `month`,
	SUM(p.retail_price * si.quantity) sales_amount
FROM sales s
INNER JOIN sales_items si ON s.sale_id = si.sale_id
INNER JOIN products p ON si.product_id = p.product_id
WHERE year(s.sale_date) = '2018'
GROUP BY month;
#----
DROP TEMPORARY TABLE IF EXISTS returns_month;
CREATE TEMPORARY TABLE returns_month
SELECT 
	month(r.return_date) `month`,
	SUM(p.retail_price * si.quantity) return_amount 
FROM returns r
INNER JOIN sales s ON r.sale_id = s.sale_id
INNER JOIN sales_items si ON s.sale_id = si.sale_id
INNER JOIN products p ON si.product_id = p.product_id
WHERE year(r.return_date) = '2018'
GROUP BY month;
#----
DROP TEMPORARY TABLE IF EXISTS profit_month;
CREATE TEMPORARY TABLE profit_month
SELECT 
	month(s.sale_date) `month`,
	SUM(p.retail_price * si.quantity) - SUM(p.cost_price * si.quantity) profit_amount
FROM sales s
INNER JOIN sales_items si ON s.sale_id = si.sale_id
INNER JOIN products p ON si.product_id = p.product_id
WHERE year(s.sale_date) = '2018'
GROUP BY month;
#---
CREATE TABLE `2018_sales_returns_profit` AS 
SELECT 
    sm.month,
    sm.sales_amount,
    pm.profit_amount gross_profit,
    rm.return_amount,
    pm.profit_amount - rm.return_amount net_profit
FROM
    sales_month sm
        INNER JOIN
    profit_month pm ON sm.month = pm.month
        INNER JOIN
    returns_month rm ON pm.month = rm.month;
CREATE OR REPLACE VIEW transactions_2018 AS
SELECT * FROM `2018_sales_returns_profit`;
SELECT * FROM transactions_2018;
    
    
    
    