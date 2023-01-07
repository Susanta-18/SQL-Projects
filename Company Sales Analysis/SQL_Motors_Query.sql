USE lco_motors;

-- Q1) How would you fetch details of the customers  who cancelled orders?

SELECT
*
FROM 
customers
INNER JOIN orders ON customers.customer_id = orders.customer_id
WHERE orders.`status` = 'cancelled';

-- Q2) Fetch the details of customers who have done payments between the amount 5,000 and 35,000?

SELECT
*
FROM 
customers
INNER JOIN payments ON payments.customer_id = customers.customer_id
WHERE amount BETWEEN 5000 AND 35000
ORDER BY payments.amount;

/* Q3) Add new employee/salesman with following details:-
EMP ID - 15657
First Name : Lakshmi
Last Name: Roy
Extension : x4065
Email: lakshmiroy1@lcomotors.com
Office Code: 4
Reports To: 1088
Job Title: Sales Rep */

INSERT INTO employees
(employee_id,last_name,first_name,extension,email,office_code,reports_to,job_title)
VALUES
(15657,'Roy','Lakshmi','x4065','lakshmiroy1@lcomotors.com','4',1088,'Sales Rep');

-- Q4) Assign the new employee to the customer whose phone is 2125557413 .
SET SQL_SAFE_UPDATES = 0;
UPDATE customers SET sales_employee_id = 15657
WHERE customers.phone = '2125557413';

-- Q5) Write a SQL query to fetch shipped motorcycles.

SELECT
*
FROM 
products
LEFT JOIN orderdetails ON orderdetails.product_code = products.product_code
LEFT JOIN orders ON orders.order_id = orderdetails.order_id
WHERE orders.`status` = 'shipped';

-- Q6) Write a SQL query to get details of all employees/salesmen in the office located in Sydney.
SELECT
*
FROM 
employees
INNER JOIN offices ON offices.office_code = employees.office_code
WHERE offices.city = 'Sydney';

-- Q7) How would you fetch the details of customers whose orders are in process?

SELECT
*
FROM 
customers
INNER JOIN orders ON orders.customer_id = customers.customer_id
WHERE orders.`status` = 'In process';

-- Q8) How would you fetch the details of products with less than 30 orders?

SELECT
*
FROM 
products
INNER JOIN orderdetails ON orderdetails.product_code = products.product_code
WHERE orderdetails.quantity_ordered < 30;

-- Q9) It is noted that the payment (check number OM314933) was actually 2575. Update the record.

UPDATE payments SET amount = 2575
WHERE payments.check_number = 'OM314933';

-- Q10) Fetch the details of salesmen/employees dealing with customers whose orders are resolved.

SELECT DISTINCT
employees.employee_id,
employees.last_name,
employees.first_name,
employees.extension,
employees.email
FROM 
employees
LEFT JOIN customers ON customers.sales_employee_id = employees.employee_id
LEFT JOIN orders ON orders.customer_id = customers.customer_id
WHERE orders.`status` = 'Resolved';


-- Q11) Get the details of the customer who made the maximum payment.

SELECT 
*,MAX(payments.amount) AS Payment_Amount
FROM 
customers
INNER JOIN payments ON customers.customer_id = payments.customer_id;

-- Q12) Fetch list of orders shipped to France.

SELECT 
order_id,order_date,required_date,shipped_date,status,comments,orders.customer_id
FROM 
orders
LEFT JOIN customers ON orders.customer_id = customers.customer_id
WHERE customers.country = 'France' AND orders.status = 'Shipped' ;

-- Q13) How many customers are from Finland who placed orders.

SELECT 
COUNT(orders.customer_id)
FROM 
orders
INNER JOIN customers ON orders.customer_id = customers.customer_id
WHERE customers.country = 'Finland' ;

-- Q14) Get the details of the customer and payments they made between May 2019 and June 2019.

SELECT 
customers.customer_id,customers.customer_name,customers.last_name,
customers.first_name,customers.phone,customers.address_line1,customers.city,
customers.country,customers.sales_employee_id,customers.credit_limit,
payments.check_number,payments.payment_date,payments.amount
FROM 
customers
LEFT JOIN payments ON payments.customer_id = customers.customer_id
WHERE payments.payment_date BETWEEN '2019-05-01' AND '2019-06-30';

-- Q15) How many orders shipped to Belgium in 2018?

SELECT 
COUNT(orders.order_id) AS Total_orders_shipped_to_Belgium_in_2018
FROM 
orders
INNER JOIN customers ON orders.customer_id = customers.customer_id
WHERE customers.country = 'Belgium' 
AND orders.status = 'Shipped' 
AND orders.shipped_date BETWEEN '2018-01-01' AND '2018-12-31';

-- Q16) Get the details of the salesman/employee with offices dealing with customers in Germany.

SELECT 
employees.employee_id, employees.last_name, employees.first_name,
employees.extension, employees.email, employees.office_code, employees.reports_to,
employees.job_title
FROM 
employees
INNER JOIN customers ON customers.sales_employee_id = employees.employee_id
WHERE customers.country = 'Germany'
GROUP BY employees.employee_id ;

/*Q17) The customer (id:496 ) made a new order today and the details are as follows:
Order id : 10426
Product Code: S12_3148
Quantity : 41
Each price : 151
Order line number : 11
Order date : <today’s date>
Required date: <10 days from today>
Status: In Process
 */ 
INSERT INTO orders (order_id,order_date,required_date,status,customer_id)
values 
(10426,(SELECT CURDATE()),
(SELECT DATE_ADD((SELECT CURDATE()), INTERVAL 10 DAY)),
'In Process',496); 

INSERT INTO orderdetails (order_id,product_code,quantity_ordered,each_price,order_line_number)
VALUES (10426,'S12_3148',41,151,11);

-- Q18) Fetch details of employees who were reported for the payments made by the customers between June 2018 and July 2018.

SELECT 
employees.employee_id, employees.last_name, employees.first_name,
employees.extension, employees.email, employees.office_code, employees.reports_to,
employees.job_title
FROM employees
INNER JOIN customers ON customers.sales_employee_id = employees.employee_id
INNER JOIN payments ON customers.customer_id = payments.customer_id
WHERE payments.payment_date BETWEEN '2018-06-01' AND '2018-07-31'
GROUP BY employees.employee_id
ORDER BY payments.payment_date;

/*19) A new payment was done by a customer(id: 119). Insert the below details.
Check Number : OM314944
Payment date : <today’s date>
Amount : 33789.55 */

INSERT INTO payments (customer_id,check_number,payment_date,amount)
VALUES
(119, 'OM314944', (SELECT CURDATE()),33789.55);

-- 20) Get the address of the office of the employees that reports to the employee whose id is 1102.

SELECT employee_id,offices.office_code,city,phone,address_line1,country,postal_code,territory
FROM employees 
INNER JOIN offices ON employees.office_code = offices.office_code
WHERE reports_to = 1102;

-- 21) Get the details of the payments of classic cars.

SELECT 
payments.customer_id, payments.check_number,
payments.payment_date,payments.amount,
products.product_line
FROM
payments
INNER JOIN orders ON orders.customer_id = payments.customer_id
INNER JOIN orderdetails ON orderdetails.order_id = orders.order_id
INNER JOIN products ON products.product_code = orderdetails.product_code
WHERE products.product_line = 'Classic Cars'
ORDER BY payments.payment_date;

-- 22) Fetch total price of each order of motorcycles.

SELECT 
order_id,orderdetails.product_code,quantity_ordered,each_price,
(SELECT quantity_ordered * each_price) as Total_Price,order_line_number
FROM 
orderdetails
INNER JOIN products ON products.product_code = orderdetails.product_code
WHERE products.product_line = 'Motorcycles';

-- 23) Get the total worth of all planes ordered.

SELECT 
SUM((SELECT quantity_ordered * each_price)) as Total_worth
FROM 
orderdetails
INNER JOIN products ON products.product_code = orderdetails.product_code
WHERE products.product_line = 'Planes';

-- 24) Get the payments of customers living in France.

SELECT 
payments.customer_id,
check_number,
payment_date,
amount
FROM
payments
INNER JOIN customers ON customers.customer_id = payments.customer_id
WHERE customers.country = 'France';

