use Challenge
--1. What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price) as total_amount
from sales s join menu m on s.product_id=m.product_id
group by s.customer_id

--2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as total_days
from sales s 
group by customer_id

--3. What was the first item from the menu purchased by each customer?
with cte as (
			select s.customer_id,m.product_name,s.order_date,
			rank() over(partition by s.customer_id order by s.order_date) as Ranking
			from sales s join menu m on s.product_id=m.product_id
			)
select distinct *
from cte
where Ranking =1
--
select * from sales s join menu m on s.product_id=m.product_id

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with cte as (select top 1 
					m.product_name,s.product_id,
					count(m.product_name) as total_products
			from sales s join menu m on s.product_id=m.product_id
			group by  m.product_name,s.product_id
			order by count(m.product_name) desc)
select customer_id, count(s.product_id) as counting
from cte left join sales s on cte.product_id=s.product_id
group by customer_id

--5. Which item was the most popular for each customer?
select customer_id,
		product_name
		-- total_products,
		-- Ranking
from (
	  select s.customer_id,
				m.product_name,
				count(m.product_name) as total_products,
				rank() over(partition by s.customer_id order by count(m.product_name) desc) as Ranking
		from sales s join menu m on s.product_id=m.product_id
		group by s.customer_id,m.product_name)  as a		
where Ranking = 1

--6. Which item was purchased first by the customer after they became a member?
with cte as (	select s.customer_id,
		   nu.product_name,
		   rank() over(partition by s.customer_id order by s.order_date) as ranking
	from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
	where s.order_date >= me.join_date
)
select *
from cte
where ranking = 1

--7. Which item was purchased just before the customer became a member?
with cte as (	select s.customer_id,
		   nu.product_name,
		   rank() over(partition by s.customer_id order by s.order_date desc) as ranking
	from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
	where s.order_date < me.join_date
)
select *
from cte
where ranking = 1
--8. What is the total items and amount spent for each member before they became a member?
	select s.customer_id,
			sum(nu.price) as amount
	from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
	where s.order_date < me.join_date
    group by s.customer_id
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select
	s.customer_id,
	sum((case when nu.product_name = 'sushi' then (nu.price *20)
		else (nu.price*10) end)) as points
from sales s join menu nu on s.product_id = nu.product_id
group by s.customer_id


--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?
select
	s.customer_id,
	sum(case when s.order_date between me.join_date and DATEADD(DAY,6,me.join_date) then (nu.price*20)
	     when nu.product_name = 'sushi' then (nu.price*20)
		 else (nu.price*10) 
	end) tota_point
from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
where s.order_date <='2021-01-30'
group by s.customer_id
-- Bonus
with cte as (
		select s.customer_id,s.order_date,nu.product_name,nu.price,
				(case when (m.customer_id =s.customer_id and s.order_date >= m.join_date) then 'Y'
				else 'N' end) as member
		from sales s join menu nu on s.product_id=nu.product_id
			left join members m on m.customer_id=s.customer_id
			
)
select *,
	case when member = 'N' then null
		 when member = 'Y' then dense_rank() over(partition by customer_id,member order by order_date) end as Ranking
from cte
order by customer_id,order_date

