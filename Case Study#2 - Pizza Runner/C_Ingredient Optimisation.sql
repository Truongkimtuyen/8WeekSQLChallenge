----======C. Ingredient Optimisation
--1. What are the standard ingredients for each pizza?
----- create a temporary table to split ingridients
SELECT
		pizza_id,
		value toppings
INTO standar_pizza_recipes_temp
FROM pizza_recipes cross apply string_split(toppings,',')
select * from standar_pizza_recipes_temp

--change datatype in standar_pizza_recipes_temp at topping column
alter table standar_pizza_recipes_temp
alter column toppings int
---							
select 
s.pizza_id,pn.pizza_name
,STRING_AGG(topping_name,',') as name_topping_recipe
from standar_pizza_recipes_temp s join pizza_toppings  pt on s.toppings = pt.topping_id
	join pizza_names pn on pn.pizza_id = s.pizza_id
group by s.pizza_id,pn.pizza_name
order by s.pizza_id,pn.pizza_name	

Result:
|  pizza_id   |	   pizza_name    |                 name_topping_recipe                   	        |
|  ---------  | ---------------- |                  ----------------					|	
|	1     |    Meatlovers	 |	Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami  |
|	2     |    Vegetarian	 |	Cheese,Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce           |



--2. What was the most commonly added extra?
with cte as (select 
				*,
				value as new_extra
			from customer_orders outer apply string_split(extras,',')
			WHERE 
				extras NOT LIKE 'MB%' OR extras is NULL		
			)
select top 1
	pt.topping_id,
	pt.topping_name,
	count(cte.new_extra)	as total_apparence
from cte left join standar_pizza_recipes_temp a on cte.new_extra =a.toppings
		join pizza_toppings pt on pt.topping_id=a.toppings
group by pt.topping_id,pt.topping_name
order by count(cte.new_extra) desc

Result:
|  topping_id	| topping_name	| total_apparence | 
|  ---------    | ------------- |  -------------  | 
|      1	|     Bacon	|         4	  | 

--3. What was the most common exclusion?
with cte as (select 
					order_id,
					pizza_id,
					value new_exclusions
			from customer_orders cross apply string_split(exclusions,',')
			)

select top 1
		pt.topping_name,
		count(*) as total_appearance
from cte join pizza_recipes pr on cte.pizza_id=pr.pizza_id
		join pizza_toppings pt on pt.topping_id=cte.new_exclusions
group by pt.topping_name
order by count(*) desc

Result:
| topping_name	| total_appearance | 
|  ---------    |  -------------   |  
|    Cheese	|        4         |

--4. Generate an order item for each record in the customers_orders table in the format of one of the following:
--4.1 Meat Lovers
--4.2 Meat Lovers - Exclude Beef
--4.3 Meat Lovers - Extra Bacon
--4.4 Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
--create extra_tepm
select order_id,customer_id,pizza_id,value new_extras
into customer_orders_extra_tepm
from customer_orders outer apply string_split(extras,',') 
--create exclusions_tepm
select order_id,customer_id,pizza_id,value new_exclusions
into customer_orders_exclusions_tepm
from customer_orders outer apply string_split(exclusions,',') 
--join tables to find name of topping
-------create a table with string_agg  have name_extra
with topping_name_new_extra as (
				select distinct ce.order_id,ce.customer_id,ce.pizza_id,ce.new_extras,a.topping_name
				from customer_orders_extra_tepm ce left join standar_pizza_recipes_temp b on b.toppings=ce.new_extras
						join pizza_toppings a on a.topping_id=b.toppings
						),
new_extra as (select order_id,pizza_id, string_agg(topping_name,',') as name_extra
				from topping_name_new_extra 
				group by order_id,pizza_id
),
					
					------create a table with string_agg  have name_extra							,
 topping_name_new_exclusion as (
				select distinct ce.order_id,ce.customer_id,ce.pizza_id,ce.new_exclusions,a.topping_name
				from customer_orders_exclusions_tepm ce left join standar_pizza_recipes_temp b on b.toppings=ce.new_exclusions
						 join pizza_toppings a on a.topping_id=b.toppings
						),
new_exclusion as (select order_id,pizza_id, string_agg(topping_name,',') as name_exclusion
						from topping_name_new_exclusion
						group by order_id,pizza_id
),
sumary_cte as (
		select distinct a.order_id,a.customer_id,a.pizza_id,b.name_extra,c.name_exclusion
		from customer_orders a left join new_extra b on a.order_id = b.order_id
		left join new_exclusion c on a.order_id = c.order_id
		)
select order_id,
		(case when name_extra is null and name_exclusion is null then 'Meat Lovers'
			when name_extra  is null and name_exclusion is not null then CONCAT('Meat Lovers','- Exclude ',name_exclusion)
			when name_extra is not null and name_exclusion is null then CONCAT('Meat Lovers','- Extra ',name_extra)
			when name_extra is not null and name_exclusion is not null then CONCAT('Meat Lovers','- Extra ',name_extra,'- Exclude ',name_exclusion ) end) as order_items
from sumary_cte

Result:

|   order_id	|  			order_items   			          |
|  ---------    | 			-------------  	 	                  |  
|	1       |  Meat Lovers						          |
|	2	|  Meat Lovers				                          |
|	3	|  Meat Lovers                                                    |
|	3	|  Meat Lovers                                                    |
|	4	|  Meat Lovers- Exclude Cheese                                    |
|	4	|  Meat Lovers- Exclude Cheese                                    |
|	5	|  Meat Lovers- Extra Bacon                                       |
|	6	|  Meat Lovers                                                    |
|	7	|  Meat Lovers- Extra Bacon                                       |
|	8	|  Meat Lovers                                            	  |
	|	9	|  Meat Lovers- Extra Chicken,Bacon- Exclude Cheese       |
|	10	|  Meat Lovers- Extra Cheese,Bacon- Exclude Mushrooms,BBQ Sauce   |
