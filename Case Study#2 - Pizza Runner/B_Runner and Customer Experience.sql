use Challenge
--============================= B. Runner and Customer Experience
--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select
		datepart(wk,registration_date) as Week_number,
		count(runner_id) as Total_runners_registration
from runners
group by datepart(wk,registration_date)

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select runner_id,round(avg(datediff(minute,co.order_time,try_cAST(ro.pickup_time AS DATETIME2))),2) as avg_time
from customer_orders co join runner_orders ro on co.order_id=ro.order_id
group by runner_id

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
with cte as (select co.order_id,
					count(co.pizza_id) as total_order,
					max(DATEDIFF(minute,co.order_time,try_cast(ro.pickup_time as datetime2))) as time_pre
			from customer_orders co join runner_orders ro on co.order_id=ro.order_id
			where ro.pickup_time <> 'null'
			group by co.order_id
	)
select total_order,
		avg(time_pre) as avg_time
from cte
group by total_order
--4. What was the average distance travelled for each customer?

select co.customer_id,round(avg(cast(REPLACE(distance,'km','') as float)),2)as avg_distance
from customer_orders co join runner_orders ro on ro.order_id=co.order_id
where ro.pickup_time <> 'null'
group by co.customer_id

--5. What was the difference between the longest and shortest delivery times for all orders?
with cte as (select*,
			cast((case when duration like '%min%' then LEFT(duration,2)
				when duration = 'null' then null
				else duration end) as int) as new
			from runner_orders
			)
select min(new) as min_minute
		,max(new) as max_minute
		, max(new)-min(new) as variability
from cte

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
with cte as(	select order_id,runner_id,
		cast((case when duration like '%min%' then LEFT(duration,2)
				when duration = 'null' then null
				else duration end) as float) as new_duration,
		cast((case when distance like '%km' then REPLACE(distance,'km','')
				when distance = 'null' then null
				else distance end)as float) as new_distance
	from runner_orders
)

select runner_id,
		round((new_distance*(new_duration/60)),2) as avg_speed,
		round((new_distance),2) as avg_distance
from cte 
where new_distance is not null
order by runner_id



--7. What is the successful delivery percentage for each runner?
with cte as (select co.customer_id,ro.pickup_time,
				cast(count(co.order_id) over(partition by co.customer_id order by co.customer_id) as float) as total_order
			from runner_orders ro join customer_orders co on co.order_id=ro.order_id
						)
select
	customer_id, total_order,
	cast(count(*) as float) as total_order_success,
	round((count(*)/total_order)*100,2) as Percentage_order_success
from cte
where pickup_time <> 'null'
group by customer_id,total_order
order by customer_id
--- runner ch? l?y b?ng runner order vì ch? có 10 order, b?ng customer_order có 14 order_id, do có có nhi?u s?n ph?m cùng bill nên cùng order_id 
with cte as (select ro.runner_id,ro.order_id,ro.pickup_time,
				cast(count(ro.order_id) over(partition by ro.runner_id order by ro.runner_id) as float) as total_order
			from runner_orders ro 
			
						)
select
	runner_id, total_order,
	cast(count(*) as float) as total_order_success,
	round((count(*)/total_order)*100,2) as Percentage_order_success
from cte
where pickup_time <> 'null'
group by runner_id,total_order
order by runner_id