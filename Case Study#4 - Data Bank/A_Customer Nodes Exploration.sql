use Challenge
========--A. Customer Nodes Exploration
--1.How many unique nodes are there on the Data Bank system?
with cte as (select region_id,node_id
				from customer_nodes
				group by region_id,node_id )
select count(*) as total_unique_nodes
from cte

Result:
| total_unique_nodes |
|     ---------      |
|       25	     |

Answer:
There are 25 nodes in Data Bank system

--2.What is the number of nodes per region?

select r.region_name,
count(node_id) as total_nodes
from customer_nodes a join regions r on a.region_id =r.region_id
group by r.region_name

Result:
| region_name |	total_nodes  |
|  ---------  |   ---------  |
|   Africa    |	    714      |
|   America   |     735      |
|   Asia      |     665      |
|   Australia |     770      |
|   Europe    |     616      |

Answer:
Australia had the highest number of nodes occurrences (770), 
and the least number of nodes (616).

--3.How many customers are allocated to each region?
select r.region_id,
	 r.region_name,
	count( distinct c.customer_id)  total_customers
from regions r join customer_nodes c on r.region_id=c.region_id
group by  r.region_id,r.region_name


Result:
| region_id   |  region_name | total_customers|
|  ---------  |   ---------  |    ---------   |
|	3     |	   Africa    |	    102	      |
|	2     |    America   |      105	      |
|	4     |    Asia	     |       95       |
|	1     |    Australia |      110       |
|	5     |    Europe    |       88       |

Answer:
Australia had the highest number of customers allocated to that region,
followed by America, while Europe had the least number of customers.

---4. How many days on average are customers reallocated to a different node?
with cte as (SELECT 
		customer_id,
		region_id,
		node_id,
		MIN(start_date) AS first_date
	    FROM customer_nodes
	    WHERE start_date not like '%9999%' or end_date not like '%9999%'
	    GROUP BY customer_id, region_id, node_id
) ,
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


Result:
| avg_moving_days  |
|  ----------      |
|	23.69      |

Answer:
It takes 24 days on average for customers to be reallocated to a different region.
