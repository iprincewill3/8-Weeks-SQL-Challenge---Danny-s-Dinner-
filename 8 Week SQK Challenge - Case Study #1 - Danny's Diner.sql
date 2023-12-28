8 WEEK SQL CHALLENGE (CASE STUDY #1)

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
 "customer_id" VARCHAR(1),
 "order_date" DATE,
 "product_id" INTEGER
);
 
INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
SELECT * FROM sales;
  
CREATE TABLE menu(
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
 );
 
INSERT INTO menu 
 ("product_id", "product_name", "price")
VALUES
 ('1', 'sushi', '10'),
 ('2', 'curry', '15'),
 ('3', 'ramen', '12');
 
SELECT * FROM menu;

CREATE TABLE members (
 "customer_id" VARCHAR(1),
 "join_date" DATE
);

INSERT INTO members
 ("customer_id", "join_date")
VALUES
 ('A', '2021-01-07'),
 ('B', '2021-01-09');
 
SELECT * FROM members;

SELECT customer_id, SUM(price)
FROM sales
INNER JOIN menu
 ON sales.product_id = menu.product_id
GROUP BY customer_id
 

-- Question 1: What is the total amount each customer spent at the restaurant?

-- Solution to Question 1:

SELECT customer_id, sum(price) AS total_amount
FROM sales as s
 LEFT JOIN menu as m 
  ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;


-- Question 2: How many days has each customer visited the restaurant?

-- Solution to Question 2:

SELECT customer_id, COUNT(order_date) AS days
FROM sales 
GROUP BY 1
ORDER BY 1;


-- Question 3: What was the first item from the menu purchased by each customer?

-- Solution to Question 3:

SELECT customer_id,
	   product_name,
	   order_date
	   FROM
			(SELECT *,
			 DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS dense_rnk
			 FROM menu AS m
			 JOIN sales AS s
			  ON m.product_id = s.product_id) x	
			 WHERE x.dense_rnk = 1;
		  

-- Question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

-- Solution to Question 4:
	 
SELECT DISTINCT product_name, COUNT (product_name) AS total_times_item_was_purchased
FROM sales AS s
 JOIN menu AS m
  ON s.product_id = m.product_id
GROUP BY 1
ORDER BY total_times_item_was_purchased DESC 
LIMIT 1;


-- Question 5: Which item was the most popular for each customer?

-- Solution to Question 5:

WITH CTE_Item AS (SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS product_total_count,
			          RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(m.product_id) DESC) AS rnk_order
			          FROM sales AS s
			           JOIN menu AS m
 			           ON s.product_id = m.product_id
			          GROUP BY customer_id, product_name)
SELECT customer_id, product_name, product_total_count
FROM CTE_Item
WHERE rnk_order = 1;


-- Question 6: Which item was purchased first by the customer after they became a member?

-- Solution to Question 6:

SELECT customer_id, product_name, order_date, item_purchase_order
FROM
(WITH CTE AS (SELECT s.customer_id, m.product_name, s.order_date,
			 RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk_order,
			 CASE 
				WHEN s.customer_id = 'A' AND s.order_date > '2021-01-07' THEN 'yes'
				WHEN s.customer_id = 'B' AND s.order_date > '2021-01-09' THEN 'yes'
			 	ELSE 'n/a'
			 END AS case_text
		     FROM sales AS s
		      JOIN menu AS m
		      ON s.product_id = m.product_id)
SELECT customer_id, product_name, order_date, 
RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS item_purchase_order
FROM CTE
WHERE case_text = 'yes') AS x
WHERE item_purchase_order = 1;


-- Question 7: Which item was purchased just before the customer became a member?

-- Solution to Question 7:

SELECT customer_id, product_name, order_date, item_purchase_order_before_membership 
FROM
(WITH CTE AS (SELECT s.customer_id, m.product_name, s.order_date,
			 RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk_order,
			 CASE 
				WHEN s.customer_id = 'A' AND s.order_date < '2021-01-07' THEN 'yes'
				WHEN s.customer_id = 'B' AND s.order_date < '2021-01-09' THEN 'yes'
			 	ELSE 'n/a'
			 END AS case_text
		     FROM sales AS s
		      JOIN menu AS m
		      ON s.product_id = m.product_id)
SELECT customer_id, product_name, order_date, 
RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS item_purchase_order_before_membership 
FROM CTE
WHERE case_text = 'yes') AS x;


-- Question 8: What is the total items and amount spent for each member before they became a member?

-- Solution to Question 8:

SELECT s.customer_id, COUNT(m.product_id) AS item_total, SUM(m.price) AS amount_spent
FROM 
	menu AS m
  JOIN 
    sales AS s ON m.product_id = s.product_id
  JOIN 
    members AS mr ON s.customer_id = mr.customer_id
WHERE s.order_date < mr.join_date
GROUP BY 1
ORDER BY 1;


-- QUESTION 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

-- Solution to Question 9:

SELECT s.customer_id,
	SUM(CASE
		WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10
		END) AS max_point
FROM 
	menu AS m
  JOIN 
    sales AS s 
   ON m.product_id = s.product_id
GROUP BY 1
ORDER BY 1;


-- QUESTION 10: In the first week after a customer joins the program (including their join date) they 
-- earn 2x points on all items,not just sushi - how many points do customer A and B have at the end of January?

-- Solution to Question 10:

WITH memb_jan_order AS (
    SELECT s.customer_id, m.product_name, m.price, s.order_date, 
	mr.join_date, (mr.join_date + INTERVAL '6' DAY) AS first_wk_order_date_as_a_memb
    FROM sales s
        JOIN menu m 
			ON s.product_id = m.product_id
        JOIN members mr 
			ON mr.customer_id = s.customer_id 
			AND (s.order_date BETWEEN mr.join_date AND '2021-01-31')
),
memb_jan_points AS (
    SELECT customer_id, product_name, price, order_date, join_date,
        CASE 
            WHEN order_date <= first_wk_order_date_as_a_memb THEN 20 * price 
            WHEN order_date > first_wk_order_date_as_a_memb AND product_name = 'sushi' THEN 20 * price 
            ELSE price * 10 
        END AS points 
    FROM memb_jan_order
)

SELECT customer_id, SUM(points) AS total_points_jan
FROM memb_jan_points 
GROUP BY 1
ORDER BY 1;



SELECT customer_id, SUM(points) total_january_points
FROM members_jan_points
GROUP BY 1
ORDER BY 1;




SELECT * FROM sales
SELECT * FROM menu
SELECT * FROM members