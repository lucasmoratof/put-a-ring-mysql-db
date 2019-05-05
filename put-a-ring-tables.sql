# LUCAS MORATO
# PUT A RING ON IT PROJECT
# This document was created to be used with another script called put-a-ring-queries. You can find that file
# on the same repository. You can find all files on https://github.com/lucasmoratof/put-a-ring-mysql-db

# I've some of this script in a blog post that you can access here: 
# https://lucasmorato.home.blog/2019/05/05/put-a-ring-on-it-creating-and-querying-a-mysql-database/

# CREATING AND POPULATING A DATABASE 

# THIS POJECT IS FREE TO USE, A COLLABORATIVE WAY TO MAKE PEOPLE SHARE INFORMATION 

# Creating the database for the project:
CREATE DATABASE PutARingOnIt; 

# Making sure the right database will be used:
USE PutARingOnIt;

DROP TABLE IF EXISTS customers;
CREATE TABLE IF NOT EXISTS `PutARingOnIt`.`customers_seq` (
    customer_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);CREATE TABLE `PutARingOnIt`.`customers` (
    `customer_id` VARCHAR(15) NOT NULL PRIMARY KEY DEFAULT '0',
    `fname` VARCHAR(15) NOT NULL,
    `lname` VARCHAR(25),
    `st_add` VARCHAR(35) NOT NULL,
    `city` VARCHAR(20),
    `country` VARCHAR(20) NOT NULL
);

DELIMITER $$
CREATE TRIGGER tg_customers_insert BEFORE INSERT ON customers FOR EACH ROW BEGIN INSERT INTO customers_seq VALUES(NULL); SET NEW.customer_id = CONCAT('ct-', LPAD(LAST_INSERT_ID(), 3, '0'));
END$$
DELIMITER ;

USE PutARingOnIt;
INSERT INTO `customers` (fname,lname,st_add,city,country) VALUES 
		('Beyonce','Knowles-Carter','Queen St','Hoston','USA'),
        ('Mariah','Carey','Left Side Face Blv','Los Angeles','USA'),
        ('Joelma','Calipso','Rua da Mangeuira','Belem','Brazil'),
        ('Bono','Vox','1 Dalkey Dr','Dalkey','Ireland'),
        ('Michael','Jordan','25 Illinois Av','Chicago','USA'),
        ('Edith','Piaff','89 Champs Elysees','Paris','France'),
        ('Katia','Cega','Rua Ta Dificil','Sao Paulo','Brazil'),
        ('Cher','The One','Old Star Road','San Francisco','USA'),
        ('Tina','Turner','Eldelweiss Strasse','Zurich','Switzerland'),
        ('Sandy','E Junior','Rua do Pe de Jamelao','Campinas','Brazil')
;        

USE PutARingOnIt; 
DROP TABLE IF EXISTS products;
CREATE TABLE IF NOT EXISTS `PutARingOnIt`.`products_seq` (
    product_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);
CREATE TABLE `PutARingOnIt`.`products` (
    `product_id` VARCHAR(15) NOT NULL PRIMARY KEY DEFAULT '0',
    `name` VARCHAR(35) NOT NULL,
    `description` VARCHAR(50),
    `supplier` VARCHAR(25) NOT NULL,
    `cost_price` DECIMAL(10 , 2 ) NOT NULL,
    `retail_price` DECIMAL(10 , 2 ) NOT NULL,
    `in_stock` INTEGER(6)
); 

DELIMITER $$ 
CREATE TRIGGER tg_products_insert BEFORE INSERT ON products FOR EACH ROW BEGIN INSERT INTO products_seq VALUES(NULL); SET NEW.product_id = CONCAT('pt-', LPAD(LAST_INSERT_ID(), 3, '0')); 
END$$ DELIMITER ;

USE PutARingOnIt;
CREATE TABLE IF NOT EXISTS stock_audit (
    id INT(11) NOT NULL AUTO_INCREMENT,
    product VARCHAR(4) NOT NULL,
    old_value INTEGER(6) NOT NULL,
    new_value INTEGER(6) NOT NULL,
    changedon DATETIME DEFAULT NULL,
    action VARCHAR(50) DEFAULT NULL,
    PRIMARY KEY (id)
); 

#DELIMITER $$
#CREATE TRIGGER before_stock_update BEFORE UPDATE ON products
#    FOR EACH ROW BEGIN
#    INSERT INTO stock_audit
#    SET action = 'update',
#		product = OLD.product_id,
#        old_value = OLD.in_stock,
#        new_value = NEW.in_stock,
#        changedon = NOW();
#END$$
#DELIMITER ;

USE PutARingOnIt; 
INSERT INTO `products` (`name`, `description`, `supplier`, `cost_price`, `retail_price`,`in_stock` ) VALUES
	('9k YG W band','9k Yellow Gold Wedding Band','Fields','50.00','100.00','100'),
	('Pld W band','Palladium Wedding Band','Fields','300.00','650.00','90'),
	('18k WG E 1k DIA ring','18k white gold 1k diamond Ring','N Star','700.00','1350.00','80'),
	('9k YG E ring Cz','9k yellow gold ring with cubic zirconias','Fields','220.00','550.50','50'),
	('18k YG 20in nkl','18k yellow gold chain 20 inches long','B Jews','460.00','1000.00','100'),
	('18k WG nkl .75k EM 18in','18k white gold necklace with 0.75k Emerald','B Jews','350.00','850.00','85'),
	('9k YG Cr','9k chain with plain cross','B Jews','45.00','150.00','78'),
	('18k H ER .6k DIA','9k Hoops earings with 0.6k diamonds','N Star','350.00','550.00','65'),
	('SS ER CZ','Sterling Silver earings with cubic zirconias','Fields','20.00','80.00','80'),
	('SS p ring','Sterling Silver plain ring','Fields','80.00','80.00','100'),
	('9k YG SS ring','9k yellow gold with sterling silver ring','B Jews','100.00','190.00','75'),
	('CL G S clean','Cloth to clean gold and sterling silver','','5.00','15.00','90')
;

DROP TABLE IF EXISTS sales;
CREATE TABLE IF NOT EXISTS `PutARingOnIt`.`sales_seq` (
    sale_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);
CREATE TABLE `PutARingOnIt`.`sales` (
    sale_id VARCHAR(6) NOT NULL PRIMARY KEY DEFAULT '0',
    customer_id VARCHAR(15) NOT NULL,
    sale_date DATE NOT NULL,
    FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
);

DELIMITER $$ 
CREATE TRIGGER sales_insert BEFORE INSERT ON sales FOR EACH ROW BEGIN INSERT INTO sales_seq VALUES(NULL); SET NEW.sale_id = CONCAT('sl-', LPAD(LAST_INSERT_ID(), 3, '0')); 
END$$ DELIMITER ;

INSERT INTO `sales` (customer_id, sale_date) VALUES
		('ct-001','2018-01-15'), ('ct-001','2019-01-01'),
        ('ct-002','2018-02-10'), ('ct-002','2018-02-15'), ('ct-010','2018-01-12'),
	    ('ct-003','2018-03-03'), ('ct-003','2018-03-10'), ('ct-003','2019-02-20'),
        ('ct-004','2018-04-26'), ('ct-004','2018-08-06'), ('ct-004','2018-05-17'),
        ('ct-005','2018-05-22'), ('ct-005','2019-02-01'), ('ct-005','2018-09-22'),
        ('ct-006','2018-06-12'), ('ct-006','2018-06-22'), ('ct-006','2018-12-20'),
        ('ct-007','2018-07-10'), ('ct-007','2018-09-10'), ('ct-007','2018-12-15'),
        ('ct-008','2018-08-30'), ('ct-008','2018-02-10'), ('ct-008','2018-12-14'),
        ('ct-009','2018-09-22'), ('ct-009','2019-01-13'), ('ct-009','2019-02-22'),
        ('ct-010','2018-10-22'), ('ct-010','2018-11-06'), ('ct-010','2018-12-05'),         
        ('ct-004','2018-01-26'), ('ct-004','2018-06-06'), ('ct-004','2018-11-17'),
        ('ct-005','2018-02-22'), ('ct-005','2018-07-01'), ('ct-005','2019-02-22'),
        ('ct-006','2018-03-12'), ('ct-006','2018-08-22'), ('ct-006','2019-01-20'),
        ('ct-007','2018-04-10'), ('ct-007','2018-09-10'), ('ct-007','2019-01-15'),
        ('ct-008','2018-05-30'), ('ct-008','2018-10-10'), ('ct-008','2019-02-14')
        ; 

DROP TABLE IF EXISTS sales_items;
CREATE TABLE IF NOT EXISTS `PutARingOnIt`.`sales_items_seq` (
    sale_item_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);
CREATE TABLE `PutARingOnIt`.`sales_items` (
    sale_item_id VARCHAR(10) NOT NULL PRIMARY KEY DEFAULT '0',
    sale_id VARCHAR(15) NOT NULL,
    product_id VARCHAR(15) NOT NULL,
    quantity INTEGER(10) NOT NULL,
    FOREIGN KEY (product_id)
        REFERENCES products (product_id),
    FOREIGN KEY (sale_id)
        REFERENCES sales (sale_id)
);        

DELIMITER $$ 
CREATE TRIGGER sl_items__insert BEFORE INSERT ON sales_items FOR EACH ROW BEGIN INSERT INTO sales_items_seq VALUES(NULL); SET NEW.sale_item_id = CONCAT('si-', LPAD(LAST_INSERT_ID(), 3, '0')); 
END$$ DELIMITER ;

USE PutARingOnIt;
INSERT INTO `sales_items` (sale_id, product_id, quantity) VALUES
	('sl-001','pt-002','2'),('sl-001','pt-004','1'),('sl-001','pt-010','1'),('sl-002','pt-002','1'),('sl-002','pt-008','2'),
	('sl-003','pt-005','1'),('sl-003','pt-007','3'),('sl-004','pt-012','1'),('sl-004','pt-009','2'),('sl-026','pt-003','2'),
	('sl-005','pt-006','1'),('sl-006','pt-007','1'),('sl-007','pt-008','3'),('sl-008','pt-009','1'),('sl-009','pt-010','1'),
	('sl-010','pt-011','1'),('sl-011','pt-012','1'),('sl-012','pt-001','2'),('sl-013','pt-002','1'),('sl-014','pt-003','1'),
    ('sl-015','pt-004','1'),('sl-016','pt-005','1'),('sl-017','pt-006','2'),('sl-018','pt-007','1'),('sl-019','pt-008','1'),
    ('sl-020','pt-009','1'),('sl-021','pt-010','1'),('sl-023','pt-011','3'),('sl-024','pt-012','1'),('sl-025','pt-001','1'),
    ('sl-026','pt-003','2'),('sl-026','pt-002','3'),('sl-027','pt-005','2'),('sl-027','pt-002','3'),('sl-028','pt-005','3'),
    ('sl-028','pt-004','2'),('sl-028','pt-010','1'),('sl-029','pt-010','4'),('sl-034','pt-004','1'),('sl-043','pt-010','1'),
    ('sl-030','pt-002','2'),('sl-035','pt-004','1'),('sl-039','pt-010','1'),('sl-043','pt-002','1'),('sl-044','pt-008','2'),
	('sl-031','pt-005','1'),('sl-036','pt-007','3'),('sl-040','pt-012','1'),('sl-044','pt-009','2'),('sl-042','pt-003','1'),
	('sl-032','pt-006','1'),('sl-037','pt-007','1'),('sl-041','pt-008','3'),('sl-026','pt-009','1'),('sl-034','pt-004','1'),
	('sl-033','pt-011','1'),('sl-038','pt-012','1'),('sl-042','pt-001','2'),('sl-013','pt-002','1'),('sl-034','pt-004','1')
    ;

DROP TABLE IF EXISTS returns;
CREATE TABLE IF NOT EXISTS `PutARingOnIt`.`returns_seq` (
    return_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY
);
CREATE TABLE `PutARingOnIt`.`returns` (
    return_id VARCHAR(10) NOT NULL PRIMARY KEY DEFAULT '0',
    sale_id VARCHAR(15) NOT NULL,
    return_date DATE NOT NULL,
    FOREIGN KEY (sale_id)
        REFERENCES sales (sale_id)
);        

DELIMITER $$ 
CREATE TRIGGER returns_insert BEFORE INSERT ON returns FOR EACH ROW BEGIN INSERT INTO returns_seq VALUES(NULL); SET NEW.return_id = CONCAT('rt-', LPAD(LAST_INSERT_ID(), 3, '0')); 
END$$ DELIMITER ;

USE PutARingOnIt;
insert into returns (sale_id, return_date)
select sale_id, date_add(sale_date, interval 5 day)
from sales
where sale_id = 'sl-001' or sale_id = 'sl-003' or sale_id = 'sl-007' or sale_id = 'sl-039' or sale_id = 'sl-011' or
	  sale_id = 'sl-031' or sale_id = 'sl-018' or sale_id = 'sl-010' or sale_id = 'sl-019' or sale_id = 'sl-043' or
      sale_id = 'sl-028' or sale_id = 'sl-023' or sale_id = 'sl-025' or sale_id = 'sl-026';