
# Case Study #1: Danny's Diner - Solution

## Case Study Questions

1. What is the total amount each customer spent at the restaurant?
2. How many days has each customer visited the restaurant?
3. What was the first item from the menu purchased by each customer?
4. What is the most purchased item on the menu and how many times was it purchased by all customers?
5. Which item was the most popular for each customer?
6. Which item was purchased first by the customer after they became a member?
7. Which item was purchased just before the customer became a member?
8. What is the total items and amount spent for each member before they became a member?
9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
***


To streamline calculations and avoid redundant joins, a View was created:

```sql
CREATE VIEW [CTE_View] AS
SELECT s.*, m.join_date, men.product_name, men.price
FROM sales s 
FULL OUTER JOIN members m ON s.customer_id = m.customer_id
FULL OUTER JOIN menu men ON s.product_id = men.product_id;
```

#### View Table:

| customer_id | order_date | product_id | join_date  | product_name | price |
|-------------|------------|------------|------------|--------------|-------|
| A           | 2021-01-01 | 1          | 2021-01-07 | sushi        | 10    | 
| A           | 2021-01-01 | 2          | 2021-01-07 | curry        | 15    | 
| A           | 2021-01-07 | 2          | 2021-01-07 | curry        | 15    | 
| A           | 2021-01-10 | 3          | 2021-01-07 | ramen        | 12    | 
| A           | 2021-01-11 | 3          | 2021-01-07 | ramen        | 12    | 
| A           | 2021-01-11 | 3          | 2021-01-07 | ramen        | 12    | 
| B           | 2021-01-01 | 2          | 2021-01-09 | curry        | 15    | 
| B           | 2021-01-02 | 2          | 2021-01-09 | curry        | 15    | 
| B           | 2021-01-04 | 1          | 2021-01-09 | sushi        | 10    | 
| B           | 2021-01-11 | 1          | 2021-01-09 | sushi        | 10    | 
| B           | 2021-01-16 | 3          | 2021-01-09 | ramen        | 12    | 
| B           | 2021-02-01 | 3          | 2021-01-09 | ramen        | 12    |
| C           | 2021-01-01 | 3          | NULL       | ramen        | 12    |
| C           | 2021-01-01 | 3          | NULL       | ramen        | 12    |
| C           | 2021-01-07 | 3          | NULL       | ramen        | 12    | 

This view consolidates sales, membership, and menu details into a single dataset for easier querying.


###  1. What is the total amount each customer spent at the restaurant?
<details>
  <summary>Click here for the solution</summary>
  
```sql
SELECT customer_id, SUM(price) AS total_amount
FROM CTE_View
GROUP BY customer_id
ORDER BY customer_id;
```
</details>

#### Output:
|customer|spentamount_cust|
|--------|----------------|
|A|	76
|B	|74
|C	|36

***

###  2. How many days has each customer visited the restaurant?
<details>
  <summary>Click here for the solution</summary>
  
```sql
Select customer_id, count(distinct(order_date)) as number_of_days_visited
from CTE_View
group by customer_id;
```
</details>

#### Output:
|customer_id|	Visit_frequency|
|-----------|----------------|
|A|	4
|B	|6
|C	|2

***

###  3. What was the first item from the menu purchased by each customer?
-- Asssumption: Since the timestamp is missing, all items bought on the first day is considered as the first item(provided multiple items were purchased on the first day)
<details>
  <summary>Click here for the solution</summary>
  
```sql
with cte as
(select customer_id, min(order_date) as dates
from CTE_View
group by customer_id)
select t.customer_id, c.product_name
from CTE_View c 
inner join cte t
on c.customer_id = t.customer_id
where c.order_date = t.dates;
```
</details>
	
#### Output:
|customer	|food_item|
|--------|----------|
|A|	sushi
|B	|curry
|C	|ramen

***

###  4. What is the most purchased item on the menu and how many times was it purchased by all customers?
<details>
  <summary>Click here for the solution</summary>
  
```sql
select top 1 product_name, count(product_name) No_times_ordered
from CTE_View
group by product_name
order by No_times_ordered desc;
```
</details>

#### Output:
|product_name|	order_count|
|------------|-------------|
|ramen	|8|
***

###  5. Which item was the most popular for each customer?
-- Asssumption: Products with the highest purchase counts are all considered to be popular for each customer
<details>
  <summary>Click here for the solution</summary>
  
```sql
with t1 as
(select customer_id, product_name, 
rank() over(partition by customer_id order by count(product_name)) as rnk
from CTE_View
group by customer_id, product_name)
select customer_id, product_name
from t1
where rnk = 1;
```
</details>

#### Output:

| customer_id  | product_name  | order_count  | rank  |
|--------------|---------------|--------------|-------|
| A            | ramen         | 3            | 1     |
| B            | ramen         | 2            | 1     |
| B            | curry         | 2            | 1     |
| B            | sushi         | 2            | 1     |
| C            | ramen         | 3            | 1     |

***

###  6. Which item was purchased first by the customer after they became a member?
-- Before answering question 6, I created a membership_validation table to validate only those customers joining in the membership program:
<details>
  <summary>Click here for the solution</summary>
  
```sql
with t1 as
(select *, dense_rank() over(partition by customer_id order by order_date) as rnk
from (select customer_id, product_name, order_date, join_date from CTE_View where order_date>=join_date) as d)
select customer_id, product_name as first_product_purchased_after_becoming_member
from t1
where rnk = 1;
```
</details>

#### Output:
|customer_id|	product_name|	order_date|	purchase_order|
|:---------:|:-----------:|:--------:|:-------------:|
|A|	curry|	2021-01-07|	1|
|B	|sushi|	2021-01-11	|1|

***

###  7. Which item was purchased just before the customer became a member?
<details>
  <summary>Click here for the solution</summary>
  
```sql
with t1 as
(select *, dense_rank() over(partition by customer_id order by order_date desc) as rnk
from (select customer_id, product_name, order_date, join_date from CTE_View where order_date < join_date) as d)
select customer_id, product_name as item_purchased_just_before_becoming_member
from t1
where rnk = 1;
```
</details>

#### Output:
|customer_id	|product_name|	order_date	|purchase_order|
|:---------:|:------------:|:----------:|:-------------:|
|A	|sushi|	2021-01-01|	1|
|A	|curry|	2021-01-01|	1|
|B|	sushi|	2021-01-04|	1|

***

###  8. What is the total items and amount spent for each member before they became a member?
<details>
  <summary>Click here for the solution</summary>
  
```sql
select customer_id, count(order_date) as total_item_bought, sum(price) as amount_spent
from CTE_View
where order_date < join_date
group by customer_id;
```
</details>

#### Output:
|customer_id	|total_spent	|total_items|
|:---------:|:------------:|:---------:|
|A|	25|	2|
|B	|40|	3|

***

###  9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
<details>
  <summary>Click here for the solution</summary>
  
```sql
select customer_id, sum(price_point) price_points
from (select customer_id,
case 
when product_name ! = 'sushi' then price * 10
when product_name = 'sushi' then price * 20
end as price_point
from CTE_View) s
group by customer_id;
```
</details>

#### Output:
|customer_id	|total_points|
|:----------:|:-----------:|
|A|	510|
|B|	440|

###  10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January

<details>
  <summary>Click here for the solution</summary>
  
```sql
Select customer_id, coalesce(sum(PRICE_POINT),0) as price_points
from
(select *,
case 
when DATEDIFF(day, join_date, order_date) BETWEEN 0 AND 6 or product_name = 'sushi' then price * 20
when join_date is null or product_name != 'sushi' then price * 10
end as PRICE_POINT
from CTE_View) g
where customer_id != 'c'
group by customer_id;
```
</details>

#### Output:
|customer_id	|customer_points|
|:----------:|:-------------:|
|A|	1020|
|B|	440|

***

