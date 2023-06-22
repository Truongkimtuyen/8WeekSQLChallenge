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

Results:
|  customer_id	 |  total_orders  |
|  ------------  |  ------------  |
|	101	 |	3	  |	
|	102	 |	2	  |
|	103	 |	2	  |
|	104	 |	2	  |
|	105	 |	1	  |

Answer:
There are 10 unique customer orders.

--3.How many successful orders were delivered by each runner?
select r.runner_id,count(distinct c.order_id) as total_orders
from customer_orders c join runner_orders r on c.order_id=r.order_id
where r.pickup_time <> 'null'
group by r.runner_id

Result:
|   runner_id	 |   total_orders |
|  ------------  |  ------------  |
|	1	 |	4	  |
|	2	 |	3	  |
|	3	 |	1	  |

Answer:
Runner 1 has 4 successful delivered orders.
Runner 2 has 3 successful delivered orders.
Runner 3 has 1 successful delivered order.

--4.How many of each type of pizza was delivered?
select p.pizza_name,count(c.order_id) as total_product
from pizza_names p join customer_orders c on p.pizza_id = c.pizza_id
		join runner_orders r on r.order_id=c.order_id
where r.pickup_time <> 'null'
GROUP BY p.pizza_name

Result:
|   pizza_name	 |  total_product |
|  ------------  |  ------------  |
|   Meatlovers	 |	9	  |
|   Vegetarian	 | 	3	  |

Anwers:
There are 9 delivered Meatlovers pizzas and 3 Vegetarian pizzas.
 
--5.How many Vegetarian and Meatlovers were ordered by each customer?
select c.customer_id,p.pizza_name, count(c.customer_id) as total_customer
from customer_orders c join pizza_names p on c.pizza_id=p.pizza_id
group by c.customer_id,p.pizza_name
order by c.customer_id

Result:
|  customer_id	 |  pizza_name    |   total_customer |
|  ------------  |  ------------  |   ------------   |
|	101	 |  Meatlovers	  |	  2	     |
|	101	 |  Vegetarian	  |	  1	     |
|	102	 |  Meatlovers	  |	  2	     |
|	102	 |  Vegetarian	  |	  1          |
|	103	 |  Meatlovers	  |	  3          |
|	103	 |  Vegetarian	  |	  1          |
|	104	 |  Meatlovers	  |	  3          |
|	105	 |  Vegetarian	  |	  1          |

Anwer:
- Customer 101 ordered 2 Meatlovers and 1 Vegetarian
- Customer 102 ordered 2 Meatlovers pizzas and 2 Vegetarian pizzas.
- Customer 103 ordered 3 Meatlovers pizzas and 1 Vegetarian pizza.
- Customer 104 ordered 1 Meatlovers pizza.
- Customer 105 ordered 1 Vegetarian pizza.

--6.What was the maximum number of pizzas delivered in a single order?
select top 1
	order_id,count(*) as total_pizza
from customer_orders
group by order_id
order by count(*) desc

Result:
|   order_id	 |   total_pizza  |
|  ------------  |  ------------  |
| 	4	 |	3	  |

Answer:
Maximum number of pizza delivered in a sigle order is 3 pizzas

--7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
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

Results:
|  customer_id	 |    changes	  |  no_changes    |
|  ------------  |  ------------  |  ------------  |
| 	101	 | 	0	  |       2	   |
| 	102	 | 	0	  | 	  3	   |
| 	103	 | 	3	  | 	  0	   |
| 	104	 | 	2	  | 	  1        |
| 	105	 | 	1	  | 	  0        |

Anwers:
- Customer 101 and 102 likes the pizzas per the original recipe.
- Customer 103, 104 and 105 have their own preference for pizza topping 
		and requested at least 1 change (extra or exclusion topping) on their pizza.


--8.How many pizzas were delivered that had both exclusions and extras?
select co.customer_id,
	sum(case when ((len(exclusions)>0 ) and (len(extras)>0  ))  then  1
			else 0 end ) as change
from customer_orders co join runner_orders r on co.order_id=r.order_id
where r.pickup_time <> 'null'
group by co.customer_id
order by co.customer_id

Result:
|  customer_id	 |    change      | 
|  ------------  |  ------------  |
| 	101	 |	 0	  |
| 	102	 | 	 0        |
| 	103	 | 	 0	  |
| 	104	 | 	 1	  |
| 	105	 |	 0        |

Anwers:
 Only 1 pizza delivered that had both extra and exclusion topping
 
--9.What was the total volume of pizzas ordered for each hour of the day?
with cte as (select distinct datepart(hour,order_time) as time_in_day,
			     count(order_id) as total_orders
	     from customer_orders
	     group by datepart(hour,order_time)
	    ),
select time_in_day,total_orders,
	concat(100*total_orders/(sum(total_orders) over()) ,' ','%')as total_volume_pizza_hour
from cte
	
Result:
|   time_in_day	 |  total_orders  | total_volume_pizza_hour|
|  ------------  |  ------------  |   ------------------   |
|	11	 |	1	  |	      7 %	   |
|	13	 |	3	  |	     21 %	   |
|	18	 |	3	  |	     21 %	   |
|	19	 |	1	  |	      7 %          |
|	21	 |	3	  |	     21 %	   |
|	23	 |	3	  |	     21 %          |

Anwers:
- Highest volume of pizza ordered is at 13pm, 18pm, 21pm and 23pm
- Lowest volume of pizza ordered is at 11am and 19pm

--10.What was the volume of orders for each day of the week?
with cte as (
		select distinct DATENAME(dw,order_time)as time_in_week,
			 count(order_id) as total_orders
		from customer_orders
		group by DATENAME(dw,order_time)  
			)
select time_in_week,total_orders,
	concat(100*total_orders/(sum(total_orders) over()),' ','%')as total_volume_pizza_day
from cte
order by total_orders desc

Result:
| time_in_week	 |total_orders    |  total_volume_pizza_day |
|  ------------  |  ------------  |   ------------------    |
|   Saturday	 |	5	  |	 	35 %	    |
|   Wednesday	 |	5	  |	 	35 %	    |
|   Thursday	 |	3	  |		21 %	    |
|   Friday	 |	1	  |		7 %         |

Answer:
- There are 5 pizzas ordered on Friday and Monday.
- There are 3 pizzas ordered on Saturday.
- There is 1 pizza ordered on Sunday.







