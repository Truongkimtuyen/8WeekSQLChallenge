
--A. Pizza Metrics
--1.How many pizzas were ordered?
SELECT count(*) as total_orders
from customer_orders

Result:
|  total_orders  |
|  ------------  |
|	14	 |

--2.How many unique customer orders were made?
select customer_id,
	COUNT(DISTINCT order_id) as total_orders		
from customer_orders 
group by customer_id


--3.How many successful orders were delivered by each runner?
select r.runner_id,count(distinct c.order_id) as total_orders
from customer_orders c join runner_orders r on c.order_id=r.order_id
where r.pickup_time <> 'null'
group by r.runner_id

--4.How many of each type of pizza was delivered?
select p.pizza_name,count(c.order_id) as total_product
from pizza_names p join customer_orders c on p.pizza_id = c.pizza_id
		join runner_orders r on r.order_id=c.order_id
where r.pickup_time <> 'null'
GROUP BY p.pizza_name
 
--5.How many Vegetarian and Meatlovers were ordered by each customer?
select c.customer_id,p.pizza_name, count(c.customer_id) as total_customer
from customer_orders c join pizza_names p on c.pizza_id=p.pizza_id
group by c.customer_id,p.pizza_name
order by c.customer_id
--6.What was the maximum number of pizzas delivered in a single order?
select top 1
	order_id,count(*) as total_pizza
from customer_orders
group by order_id
order by count(*) desc

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- x? lý null d?ng str ? colum : exclusions,extras
UPDATE customer_orders
SET exclusions = CASE WHEN exclusions = 'null' THEN NULL ELSE exclusions END,
    extras = CASE WHEN extras = 'null' THEN NULL ELSE extras END
--
with cte as (select 
				customer_id,order_id,exclusions,extras,
				(case when (len(exclusions) >0 or LEN(extras) >0) then 1
					else 0 end ) as change
			from customer_orders
		)
select
	cte.customer_id,
	count(case when change =1 then cte.order_id else null end) as changes,
	count(case when change =0 then cte.order_id else null end) as no_changes
from cte join runner_orders r on cte.order_id=r.order_id
where r.pickup_time <> 'null'
group by cte.customer_id;
-- cách ng?n h?n
select co.customer_id,
	sum(case when ((len(exclusions)>0 ) or (len(extras)>0  ))  then  1
			else 0 end ) as change,
	sum(case when ((len(exclusions)>0 ) or (len(extras)>0 ))  then  0
			else 1 end ) as not_change
from customer_orders co join runner_orders r on co.order_id=r.order_id
where r.pickup_time <> 'null'
group by co.customer_id
order by co.customer_id

--8.How many pizzas were delivered that had both exclusions and extras?
select co.customer_id,
	sum(case when ((len(exclusions)>0 ) and (len(extras)>0  ))  then  1
			else 0 end ) as change
from customer_orders co join runner_orders r on co.order_id=r.order_id
where r.pickup_time <> 'null'
group by co.customer_id
order by co.customer_id
--9.What was the total volume of pizzas ordered for each hour of the day?
with cte as (select distinct datepart(hour,order_time) as time_in_day,
				 count(order_id) as total_orders
			from customer_orders
			group by datepart(hour,order_time))
			-- order by datepart(hour,order_time)),
select time_in_day,total_orders,
	    100*total_orders/(sum(total_orders) over()) as total_volume_pizza_hour
	from cte

--10.What was the volume of orders for each day of the week?
with cte as (
			select distinct DATENAME(dw,order_time)as time_in_week,
				 count(order_id) as total_orders
			from customer_orders
			group by DATENAME(dw,order_time)  
			)
select time_in_week,total_orders,
	    100*total_orders/(sum(total_orders) over()) as total_volume_pizza_day
from cte
order by total_orders desc
