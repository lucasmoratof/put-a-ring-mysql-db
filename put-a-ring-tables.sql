# Creating the database for the project:
CREATE DATABASE CA_2; 

# Making sure the right database will be used:
USE CA_2;

DROP TABLE IF EXISTS customers;
CREATE TABLE IF NOT EXISTS `CA_2`.`customers_seq` (ct_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY); # This table will be used with the trigger to auto populate the primary key for customers
CREATE TABLE `CA_2`.`customers` (
    `ct_id` VARCHAR(15) NOT NULL PRIMARY KEY DEFAULT '0',
    `fname` VARCHAR(15) NOT NULL,
    `lname` VARCHAR(25),
    `st_add` VARCHAR(35) NOT NULL,
    `city` VARCHAR(20),
    `country` VARCHAR(20) NOT NULL
);

USE CA_2;
INSERT INTO `customers` (fname,lname,st_add,city,country) VALUES 
		('Lucas','Morato','74 BM Penha','Botucatu','Brazil'),
        ('Andrea','Morato','74 BM Penha','Bauru','Brazil'),
        ('Isadora','Frederico','71 Cohab Cinco','Rio','Brazil'),
        ('Bono','Vox','1 Dalkey Dr','Dalkey','Ireland'),
        ('Michael','Jordan','25 Illinois Av','Chicago','USA'),
        ('Edith','Piaff','89 Champs Elysees','Paris','France'),
        ('Diego','Morato','12 Taquelim Sq','Lagos','Portugal'),
        ('Patrick','Houle','1220 Pelican St','Sydney','Australia'),
        ('Ar-Jay','Delossantos','120 Victoria St','Sydney','Australia'),
        ('Eloa','Dos Reis','50 Sukhonvit Soi','Bangkok','Thailand')
;        

USE CA_2; 
DROP TABLE IF EXISTS products;
CREATE TABLE IF NOT EXISTS `CA_2`.`products_seq` (pt_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY);
CREATE TABLE `CA_2`.`products` (
    `pt_id` VARCHAR(15) NOT NULL PRIMARY KEY DEFAULT '0',
    `name` VARCHAR(35) NOT NULL,
    `description` VARCHAR(50),
    `supplier` VARCHAR(25) NOT NULL,
    `cost_price` DECIMAL(10 , 2 ) NOT NULL,
    `retail_price` DECIMAL(10 , 2 ) NOT NULL
); 

USE CA_2; 
INSERT INTO `products` (`name`, `description`, `supplier`, `cost_price`, `retail_price`,`in_stock`) VALUES
		('9k YG W band','9k Yellow Gold Wedding Band','Fields','50.00','100.00'),
        ('Pld W band','Palladium Wedding Band','Fields','300.00','650.00'),
        ('18k WG E 1k DIA ring','18k white gold 1k diamond Ring','N Star','700.00','1350.00'),
        ('9k YG E ring Cz','9k yellow gold ring with cubic zirconias','Fields','220.00','550.50'),
        ('18k YG 20in nkl','18k yellow gold chain 20 inches long','B Jews','460.00','1000.00'),
        ('18k WG nkl .75k EM 18in','18k white gold necklace with 0.75k Emerald','B Jews','350.00','850.00'),
        ('9k YG Cr','9k chain with plain cross','B Jews','45.00','150.00'),
        ('18k H ER .6k DIA','9k Hoops earings with 0.6k diamonds','N Star','350.00','550.00'),
        ('SS ER CZ','Sterling Silver earings with cubic zirconias','Fields','20.00','80.00'),
        ('SS p ring','Sterling Silver plain ring','Fields','80.00','80.00'),
        ('9k YG SS ring','9k yellow gold with sterling silver ring','B Jews','100.00','190.00'),
        ('CL G S clean','Cloth to clean gold and sterling silver','','5.00','15.00')
        ;

DROP TABLE IF EXISTS sales;
CREATE TABLE IF NOT EXISTS `CA_2`.`sales_seq` (sl_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY);
CREATE TABLE `CA_2`.`sales` (
    sl_id VARCHAR(6) NOT NULL PRIMARY KEY DEFAULT '0',
    ct_id VARCHAR(15) NOT NULL ,
    order_date DATE NOT NULL,
    FOREIGN KEY (ct_id)
        REFERENCES customers (ct_id)
);

INSERT INTO `sales` (ct_id, order_date) VALUES
		('ct-001','2018-01-15'), ('ct-001','2019-01-01'),
        ('ct-002','2018-02-10'), ('ct-002','2018-02-15'),
	    ('ct-003','2018-03-03'), ('ct-003','2018-03-10'), ('ct-003','2019-02-20'),
        ('ct-004','2018-04-26'), ('ct-004','2018-08-06'), ('ct-004','2018-05-17'),
        ('ct-005','2018-05-22'), ('ct-005','2019-02-01'), ('ct-005','2018-09-22'),
        ('ct-006','2018-06-12'), ('ct-006','2018-06-22'), ('ct-006','2018-12-20'),
        ('ct-007','2018-07-10'), ('ct-007','2018-09-10'), ('ct-007','2018-12-15'),
        ('ct-008','2018-08-30'), ('ct-008','2018-02-10'), ('ct-008','2018-12-14'),
        ('ct-009','2018-09-22'), ('ct-009','2019-01-13'), ('ct-009','2019-02-22'),
        ('ct-010','2018-10-22'), ('ct-010','2018-11-06'), ('ct-010','2018-12-05'), ('ct-010','2018-01-12')
        ; 

DROP TABLE IF EXISTS order_items;
CREATE TABLE `CA_1`.`order_items` (
    oi_id VARCHAR(15) NOT NULL,
    order_id VARCHAR(15) NOT NULL,
    product_id VARCHAR(15) NOT NULL,
    quantity INTEGER(10) NOT NULL,
    PRIMARY KEY (oi_id), 
    FOREIGN KEY (product_id)
        REFERENCES products (product_id),
    FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
);        

USE CA_1;
INSERT INTO `order_items` VALUES
		('oi-0001','or-0001','pt-0001','9'),
        ('oi-0002','or-0001','pt-0008','3'),
        ('oi-0003','or-0003','pt-0007','23'),
        ('oi-0004','or-0004','pt-0002','5'),
        ('oi-0005','or-0005','pt-0012','7'),
		('oi-0006','or-0001','pt-0004','9'),
        ('oi-0007','or-0001','pt-0009','1'),
        ('oi-0008','or-0003','pt-0003','23'),
        ('oi-0009','or-0004','pt-0005','5'),
        ('oi-0010','or-0010','pt-0012','7')
        ; 
        
# THIS IS JUST AN EXAMPLE TO BE USED IN CASE A TABLE IS ALREADY CREATED AND WE WANT TO ADD A NEW COLUMN OR VALUES WITHOUT DROPPING THE WHOLE SCHEMA:
# WHEN A TABLE HAS PK OR FK THE DROP COMMAND DOESN'T WORK, SO THE APPROACH NEED TO BE DIFFERENT, EXAMPLE:
## ALTER TABLE orders
## ADD COLUMN order_date DATE AFTER customer_id;
## UPDATE orders SET order_date = '2019-02-25' WHERE order_id = 'or-0001';
 

  