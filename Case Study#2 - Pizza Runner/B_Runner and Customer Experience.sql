
--============================= B. Runner and Customer Experience
--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

select
		datepart(wk,registration_date) as Week_number,
		count(runner_id) as Total_runners_registration
from runners
group by datepart(wk,registration_date)

Result:
| Week_number |	Total_runners_registration |
|  ---------  |          ---------         |
|	1     |		    1              |
|	2     |		    2              |
|	3     |             1              |

Answer:
- On Week 2 of Jan 2021, 2 new runner signed up.
- On Week 1 and 3 of Jan 2021, 1 new runner signed up.


--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

select round(avg(datediff(minute,co.order_time,try_cAST(ro.pickup_time AS DATETIME2))),2) as avg_time
from customer_orders co join runner_orders ro on co.order_id=ro.order_id

Result:
|  avg_time  |
|------------|
|	18   |

Answer:
It takes each runner 16 minutes on the average to pick up the order

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

Result:
| total_order |	     avg_time     |
|  ---------  |     ---------     |
|	1     |		12	  |
|	2     |		18	  |
|	3     |		30	  |

Answer:
From the above, the more the pizza contained in an order, the longer it takes for that order to be ready.

--4. What was the average distance travelled for each customer?

select co.customer_id,round(avg(cast(REPLACE(distance,'km','') as float)),2)as avg_distance
from customer_orders co join runner_orders ro on ro.order_id=co.order_id
where ro.pickup_time <> 'null'
group by co.customer_id

Result:
|  customer_id	|   avg_distance    |
|  ---------    |    ---------      |
|	101	|	20	    |
|	102	|	16.73       |  
|	103	|	23.4        |
|	104	|	10          |
|	105	|	25          |

Answer:
Customer 105 stays farthest (25km) while Customer 104 stays closest (10km).

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

Results:
|   min_minute	|   max_minute	  |  variability   |
|  ---------    |    ---------    |   ---------    |
|	10	|  	40	  |      30        |

Answer:
The difference between the longest and shortest delivery times is 30 minutes

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

select distinct runner_id,customer_id,
		round((new_distance/(new_duration/60)),2) as avg_speed,
		round((new_distance),2) as avg_distance
from cte c join customer_orders co on c.order_id = co.order_id
where new_distance is not null
order by runner_id

Results:
|   runner_id	|   customer_id   |   avg_speed	   |  avg_distance |
|  ---------    |    ---------    |   ---------    |    ---------  |
| 	1	| 	101	  | 	37.5	   | 	  20       |
| 	1	| 	101	  | 	44.44	   |      20       |
| 	1	| 	102	  | 	40.2	   |     13.4      |
| 	1	| 	104	  | 	60	   |      10       |
| 	2	| 	102	  | 	93.6	   |     23.4      |
| 	2	| 	103	  | 	35.1	   |     23.4      |
| 	2	| 	105	  | 	60	   |      25       |
| 	3	|	104	  | 	40	   |      10       |

Answer:
Of concern is Runner 2’s speed.
There is a large variance between the lowest(35.1km/hr) and highest speeds (93.6km/hr).

--7. What is the successful delivery percentage for each runner?
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

Result:
|   runner_id	|  total_order	  | total_order_success	|   Percentage_order_success   |
|  ---------    |    ---------    |       ---------     |          ---------           |
|	1	|	4	  |	     4		|		100            |
|	2	|	4	  |	     3		|		75	       |
|	3	|	2	  |	     1		|		50             |

Anwers:
Runner 1 has highest percentage of successful deliveries (100%) while Runner 3 has the least (50%). 
But it’s important to note that it’s beyond the control of the runner as either the customer or the restaurant can cancel orders.



