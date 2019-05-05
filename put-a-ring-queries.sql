# LUCAS MORATO
# PUT A RING ON IT PROJECT
# This document was created to be used with another script called put-a-ring-tables. You can find that file
# on the same repository. You can find all files on https://github.com/lucasmoratof/put-a-ring-mysql-db

# I've some of the queries in a blog post that you can access here: 
# https://lucasmorato.home.blog/2019/05/05/put-a-ring-on-it-creating-and-querying-a-mysql-database/

# QUERIES
 
############## PLEASE READ!
# This document cannot be read at once, it won't work.
# Each query need to be run individually.
# ----------------------------------------
###############################################
## Stored Procedure - Detail and total all sales for the year, group these by each month, A Group By with RollUp.
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
## View - Display the growth in sales (as a percentage) for your business, from the 1st month of opening until 
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
    
    
    
    