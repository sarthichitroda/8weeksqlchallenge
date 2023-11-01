use dannys_diner;

select *
from sales;

select *
from menu;

select *
from members;

Q.1 What is the total amount each customer spent at the restaurant?
select s.customer_id, sum(m.price)
from sales s
join menu m
on s.product_id=m.product_id
group by s.customer_id;

Q.2 How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as days_of_visits
from sales
group by customer_id;

Q.3 What was the first item from the menu purchased by each customer?
select distinct product_name, customer_id
from(
select s.customer_id, s.order_date, dense_rank() over(partition by s.customer_id order by s.order_date) as rnk, m.product_name
from sales s
join menu m
on s.product_id=m.product_id
) as der
where rnk=1;

Q.4 What is the most purchased item on the menu and how many times was it purchased by all customers?
select customer_id, count(product_id)
from sales
where product_id in (
select product_id
from(
select product_id, dense_rank() over(order by ctr desc) as rnk
from(
select product_id, count(product_id) as ctr
from sales
group by product_id
) as der
) as der2
where rnk=1)
group by customer_id;

Q.5 Which item was the most popular for each customer?
select *
from(
select customer_id, product_name, dense_rank() over(partition by customer_id order by ctr desc) as rnk
from(
select s.customer_id, s.product_id, count(s.product_id) as ctr, m.product_name
from sales s
join menu m
on s.product_id=m.product_id
group by s.customer_id, s.product_id
) as der
) as f
where rnk=1
;

Q.6 Which item was purchased first by the customer after they became a member?
with cte as(
select customer_id, product_id, order_date
from(
select s.customer_id, s.product_id, s.order_date, m.join_date, dense_rank() over(partition by s.customer_id order by s.order_date) as rnk
from sales s
join members m
on s.customer_id=m.customer_id
where s.order_date>m.join_date
) as der
where rnk=1
)
select cte.*, m.product_name
from cte
join menu m
on cte.product_id=m.product_id;

Q.7 Which item was purchased just before the customer became a member?
with cte as(
select s.customer_id, s.product_id, s.order_date,m.join_date, dense_rank() over(partition by s.customer_id order by s.order_date desc) as rnk
from sales s
join members m
on s.customer_id=m.customer_id
where s.order_date<m.join_date
)
select cte.customer_id, cte.order_date, m.product_name
from cte
join menu m
on cte.product_id=m.product_id
where rnk=1
order by customer_id, order_date
;

Q.8 What is the total items and amount spent for each member before they became a member?
with cte as(
select s.customer_id, s.product_id, count(s.product_id) as ctr, s.order_date,m.join_date
from sales s
join members m
on s.customer_id=m.customer_id
where s.order_date<m.join_date
group by s.customer_id, s.product_id
)
select customer_id, sum(ctr) as total_items_purchased, sum(m.price*cte.ctr) as amt_spent
from cte
join menu m
on cte.product_id=m.product_id
group by customer_id
order by customer_id;

Q.9 If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, sum(points) as total_points
from(
select s.customer_id, m.*,
case
when m.product_name='sushi' then m.price*20
else m.price*10
end as points
from sales s
join menu m
on s.product_id=m.product_id
) as der
group by customer_id;

Q.10 In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
 how many points do customer A and B have at the end of January?
 select customer_id, sum(points) as total_points
 from(
 with cte as(
 select s.*, m.join_date
 from sales s
 join members m
 on s.customer_id=m.customer_id
)
select cte.customer_id, cte.order_date, cte.join_date, menu.*,
case 
when
datediff(order_date, join_date)>=7
then menu.price*20
else menu.price*10
end as points
from cte
join menu
on cte.product_id=menu.product_id
where month(order_date)=1
) as derg
group by customer_id;