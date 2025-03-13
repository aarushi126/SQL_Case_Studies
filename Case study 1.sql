CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

USE [Danny's Dinner];

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
 

CREATE TABLE menu (
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
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  /* --------------------
   Case Study Questions
   --------------------*/

CREATE VIEW [CTE_View] AS
SELECT s.*, m.join_date, men.product_name, men.price
FROM sales s 
FULL OUTER JOIN members m ON s.customer_id = m.customer_id
FULL OUTER JOIN menu men ON s.product_id = men.product_id;

select * from CTE_View;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, SUM(price) AS total_amount
FROM CTE_View
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?

Select customer_id, count(distinct(order_date)) as number_of_days_visited
from CTE_View
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte as
(select customer_id, min(order_date) as dates
from CTE_View
group by customer_id)
select t.customer_id, c.product_name
from CTE_View c 
inner join cte t
on c.customer_id = t.customer_id
where c.order_date = t.dates;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select top 1 product_name, count(product_name) No_times_ordered
from CTE_View
group by product_name
order by No_times_ordered desc;

-- 5. Which item was the most popular for each customer?

with t1 as
(select customer_id, product_name, 
rank() over(partition by customer_id order by count(product_name)) as rnk
from CTE_View
group by customer_id, product_name)
select customer_id, product_name
from t1
where rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member?

with t1 as
(select *, dense_rank() over(partition by customer_id order by order_date) as rnk
from (select customer_id, product_name, order_date, join_date from CTE_View where order_date>=join_date) as d)
select customer_id, product_name as first_product_purchased_after_becoming_member
from t1
where rnk = 1;

-- 7. Which item was purchased just before the customer became a member?

with t1 as
(select *, dense_rank() over(partition by customer_id order by order_date desc) as rnk
from (select customer_id, product_name, order_date, join_date from CTE_View where order_date < join_date) as d)
select customer_id, product_name as item_purchased_just_before_becoming_member
from t1
where rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

select customer_id, count(order_date) as total_item_bought, sum(price) as amount_spent
from CTE_View
where order_date < join_date
group by customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id, sum(price_point) price_points
from (select customer_id,
case 
when product_name ! = 'sushi' then price * 10
when product_name = 'sushi' then price * 20
end as price_point
from CTE_View) s
group by customer_id
;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

Select customer_id, coalesce(sum(PRICE_POINT),0) as price_points
from
(select *,
case 
when DATEDIFF(day, join_date, order_date) BETWEEN 0 AND 6 or product_name = 'sushi' then price * 20
when join_date is null or product_name != 'sushi' then price * 10
end as PRICE_POINT
from CTE_View) g
group by customer_id;