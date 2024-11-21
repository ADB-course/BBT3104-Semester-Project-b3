CREATE TRIGGER update_stock_quantity
AFTER INSERT ON Distribution
FOR EACH ROW
BEGIN
    UPDATE Product
    SET stockQuantity = stockQuantity - NEW.quantity
    WHERE productId = NEW.productId;
END;


CREATE TRIGGER unique_distributor_name
BEFORE INSERT ON Distribution
FOR EACH ROW
BEGIN
    DECLARE distributorExists INT;
    SELECT COUNT(*) INTO distributorExists
    FROM Distribution
    WHERE distributorName = NEW.distributorName;
    
    IF distributorExists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot input an existing distributor name';
    END IF;
END;



 DELIMITER $$


CREATE PROCEDURE VerifyAndDeliverProduct(IN productId INT, IN deliveryId INT)
BEGIN
    DECLARE stockQuantity INT;
    DECLARE productCheck BOOLEAN;
    
    -- Start Transaction
    START TRANSACTION;


    -- Check if product exists and retrieve stockQuantity and productCheck
    SELECT stock_quantity, product_check 
    INTO stockQuantity, productCheck
    FROM Product
    WHERE productId = productId;


    -- Check if delivery exists
    IF EXISTS (SELECT 1 FROM Delivery WHERE deliveryId = deliveryId) THEN
        IF stockQuantity > 0 AND productCheck = TRUE THEN
            -- Update delivery details
            INSERT INTO Delivery (deliveryId, productName, deliveryDate, deliveryTime, deliveryAddress)
            SELECT deliveryId, productName, NOW(), NOW(), deliveryAddress
            FROM Product
            WHERE productId = productId;


            -- Update product stock
            UPDATE Product
            SET stock_quantity = stock_quantity - 1, product_status = 'Delivered'
            WHERE productId = productId;


        ELSEIF stockQuantity = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Out of Stock';
        ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Failed Quality Check';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Delivery ID Not Found';
    END IF;


    -- Commit Transaction
    COMMIT;
END$$


DELIMITER ;




DELIMITER $$

CREATE FUNCTION FUNC_GET_TOTAL_SALES(productId INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE total_sales DECIMAL(10, 2);
    
    SELECT SUM(s.Quantity_sold * s.unit_price) INTO total_sales
    FROM sale s
    WHERE s.ProductId = productId;
    
    RETURN total_sales;
END$$

DELIMITER ;



10.7 Views
1.)  CREATE VIEW PaymentStatus AS
   SELECT 
       p.payment_id,
       o.order_id,
       p.amount,
       p.status
   FROM 
       payments p
   JOIN 
       orders o ON p.order_id = o.order_id;


2.)
   CREATE VIEW SupplierInfo AS
   SELECT 
       s.supplier_id,
       s.supplier_name,
       s.contact_info,
       p.product_name
   FROM 
       suppliers s
   JOIN 
       products p ON s.supplier_id = p.supplier_id;


3.)CREATE VIEW StaffPerformance AS
   SELECT 
       s.staff_id,
       s.staff_name,
       COUNT(o.order_id) AS total_orders,
       SUM(s.total_sales) AS total_sales
   FROM 
       staff s
   LEFT JOIN 
       sales sa ON s.staff_id = sa.staff_id
   LEFT JOIN 
       orders o ON sa.order_id = o.order_id
   GROUP BY 
       s.staff_id;



DELIMITER $$

CREATE PROCEDURE PROC_SALES_BY_DATE(IN saleDate DATE)
BEGIN
    SELECT s.saleId, s.date, c.customerName, p.productName, s.Quantity_sold, s.unit_price
    FROM sale s
    JOIN product p ON s.ProductId = p.productId
    JOIN customer c ON s.customerName = c.customerName
    WHERE s.date = saleDate;
END$$

DELIMITER ;


CREATE TABLE DairyProducts (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) CHECK (Price > 0),
    QuantityInStock INT CHECK (QuantityInStock >= 0),
    ExpirationDate DATE CHECK (ExpirationDate > CURRENT_DATE),
    FatContent DECIMAL(5, 2) CHECK (FatContent >= 0 AND FatContent <= 100),
    UnitsSold INT CHECK (UnitsSold >= 0),
    DistributionCenter VARCHAR(100) NOT NULL
);


Sale entity (InnoDB, B+Tree)
CHECK (paymentMethod IN (‘Card’, ‘Mobile’, ‘Cash’))
Order entity (InnoDB, B+Tree)
CHECK (quantityOrdered > 0) and CHECK (productPrice >=0)
Payment entity (InnoDB, B+Tree)
CHECK (amountPaid >=0) and CHECK (paymentStatus IN (0, 1)) - 0 for pending and 1 for paid
Supplier entity (InnoDB, B+Tree)
CHECK (supplierType IN (0, 1)) - 0 for manufacturer and 1 for distributor
Product entity (InnoDB, B+Tree)
CHECK (stock_quantity >=0), CHECK (unitPrice > 0) and CHECK (product_check IN (TRUE, FALSE))
Factory entity (InnoDB, B+Tree)
CHECK (unprocessedGoods >= 0) and CHECK (processedGoods >= 0)
Stores entity (MyISAM, B+Tree)
CHECK (salePrice >= 0), CHECK (discountPrice >= 0) and CHECK (stockAmount >= 0)
Customer entity (InnoDB, B+Tree)
CHECK (unitPrice>=0) and  CHECK (paymentMethod IN (‘Card’, ‘Mobile’, ‘Cash’))
