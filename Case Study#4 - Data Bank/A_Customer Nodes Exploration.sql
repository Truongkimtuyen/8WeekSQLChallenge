use Challenge
========--A. Customer Nodes Exploration
--How many unique nodes are there on the Data Bank system?
with cte as (select region_id,node_id
				from customer_nodes
				group by region_id,node_id )
select count(*) as total_unique_nodes
from cte

--What is the number of nodes per region?

select r.region_name,
count(distinct node_id) as total_nodes
from customer_nodes a join regions r on a.region_id =r.region_id
group by r.region_name

--How many customers are allocated to each region?
select
	distinct r.region_name,
	count(c.customer_id) over(partition by r.region_id order by r.region_id) as total_customers
from regions r join customer_nodes c on r.region_id=c.region_id
order by r.region_name

---How many days on average are customers reallocated to a different node?
with cte as (SELECT 
				customer_id,
				region_id,
				node_id,
				MIN(start_date) AS first_date
			  FROM customer_nodes
			  where start_date not like '%9999%' or end_date not like '%9999%'
			  GROUP BY customer_id, region_id, node_id
       )
		  ,
customerDates AS (
 SELECT
    customer_id,
    node_id,
    region_id,
    first_date,
   
           datediff(DAY,first_date,LEAD(first_date) OVER(PARTITION BY customer_id 
                                   ORDER BY first_date)) AS moving_days
  FROM cte
  )
  SELECT 
  round(avg(cast((moving_days) as float)),2) AS avg_moving_days
FROM customerDates;

