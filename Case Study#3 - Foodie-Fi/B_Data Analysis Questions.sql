
----------- B. Data Analysis Questions
--1. How many customers has Foodie-Fi ever had?
select count( distinct customer_id) as total_customer
from subscriptions
where plan_id <> 0

result:
| total_customer |
|  ------------  |
|     1000       |

--2. What is the monthly distribution of trial plan start_date values for our dataset 
-------- use the start of the month as the group by value
select datepart(month,start_date) as 'Month',
		count(distinct customer_id) as  total_customer
from subscriptions
where plan_id = 0
group by datepart(month,start_date)

Result:
| Month	    |  total_customer |
|  -------- |    --------     |
|	1   |	    88	      |
|	2   |	    68        |
|	3   |	    94        |
|	4   |	    81        |
|	5   |	    88        |
|	6   |	    79        |
|	7   |	    89        |
|	8   |	    88        |
|	9   |	    87        |
|	10  |	    79        |
|	11  |	    75        |
|	12  |	    84        |

Anwers:
March has the highest number of trial plans, while February has the lowest number of trial plans.

--3. What plan start_date values occur after the year 2020 for our dataset? 
------Show the breakdown by count of events for each plan_name
select
	distinct p.plan_id,
	p.plan_name,
	count(s.customer_id) over(partition by p.plan_name order by p.plan_name) as 'count_of_event'	
from subscriptions s join plans p on s.plan_id=p.plan_id
where datepart(year,s.start_date) > 2020;

Result:
|  plan_id  |	 plan_name    |	count_of_event  |
|  -------- |    --------     |      --------   |
|	1   |	basic monthly | 	8       |
|	2   |	pro monthly   | 	60      |
|	3   |	pro annual    | 	63      |
|	4   |	churn	      |         71      |

	
--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select plan_name,
		count( distinct customer_id) as 'total_customer_churn',
		cast(100*count( distinct customer_id)/(select count(distinct customer_id ) from subscriptions) as decimal(16,2)) as'Percentage'
from subscriptions s join plans p on s.plan_id=p.plan_id
where s.plan_id = 4
group by plan_name

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

with cte as (select *,
					lead(plan_id,1) over(partition by customer_id order by start_date) as next_plan
				from subscriptions
			),
churned as (
			select *
			from cte
			where plan_id = 0 and next_plan =4
			)
select count(*) as 'total_churn',
	   cast(100*count(*)/ (select count(distinct customer_id) from subscriptions) as decimal(16,2)) as 'Percentage'
from churned;
--6. What is the number and percentage of customer plans after their initial free trial?

select p.plan_name,p.plan_id,
						count(*) as 'total',
						cast(100*count(*) / (select count(distinct customer_id) from subscriptions) as decimal(16,2)) as 'percentage'
					from subscriptions s join plans p on s.plan_id=p.plan_id
					where p.plan_id <> 0
					group by p.plan_name,p.plan_id
					
--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

--8. How many customers have upgraded to an annual plan in 2020?
select count(distinct customer_id)
from subscriptions
where DATEPART(year,start_date)=2020 and plan_id=3

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with date_join as (select *
							,
							lead(start_date,1) over(partition by customer_id order by start_date) as joining
							
						from subscriptions
						where plan_id in (0,3)		
					)
select avg(DATEDIFF(day,start_date,joining)) as avg_customer_become_annual_plan
from date_join
where joining is not null
--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH next_plan_cte AS
  (SELECT *,
          lead(start_date, 1) over(PARTITION BY customer_id
                                   ORDER BY start_date) AS next_plan_start_date,
          lead(plan_id, 1) over(PARTITION BY customer_id
                                ORDER BY start_date) AS next_plan
   FROM subscriptions)
   ,
  window_details_cte AS
  (
  SELECT *,
          datediff(day,start_date,next_plan_start_date)  AS days,
          round(datediff(day,start_date,next_plan_start_date)/30,2) AS window_30_days
   FROM next_plan_cte
   WHERE next_plan=3
   )
SELECT window_30_days,
       count(*) AS customer_count
FROM window_details_cte
GROUP BY window_30_days
ORDER BY window_30_days;
--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with cte as 
(select * ,
	lag(plan_id) over(partition by customer_id order by start_date) as new_plan_id
from subscriptions
)
select
	count( case when new_plan_id > plan_id then 1 
			else null end) as total_downgrade
from cte
--
select * ,
	lag(plan_id,2) over(partition by customer_id order by start_date) as new_plan_id
from subscriptions

select * ,
	lead(plan_id,2) over(partition by customer_id order by start_date) as new_plan_id
from subscriptions
