
--1. What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(m.price) as total_sales
from sales s join menu m on s.product_id=m.product_id
group by s.customer_id

Result:
| customer_id | total_sales |
| ----------- | ----------  |
|      A      |   76        |
|      B      |   74        |
|      C      |   36        |


--2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) as total_days
from sales s 
group by customer_id

Result:
|customer_id	|total_days |
| -----------   |-----------|
|	A       |    4      |
|	B       |    6      |
|       C       |    2      |
--3. What was the first item from the menu purchased by each customer?
with cte as (
			select s.customer_id,m.product_name,s.order_date,
			rank() over(partition by s.customer_id order by s.order_date) as Ranking
			from sales s join menu m on s.product_id=m.product_id
			)
select distinct customer_id,
		product_name
from cte
where Ranking =1

Result:
|customer_id  |	product_name|
| ----------- | ----------- |
|	A     |   curry	    |
|	A     |   sushi	    |
|	B     |   curry	    |
|	C     |   ramen	    |

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

Result:
|  product_name   | most_purchased  |
|    -----------  |   -----------   |
|      ramen      |        8        |

--5. Which item was the most popular for each customer?
select customer_id,
	product_name,
	total_products,
		
from (
	  select s.customer_id,
			m.product_name,
			count(m.product_name) as total_products,
			rank() over(partition by s.customer_id order by count(m.product_name) desc) as Ranking
		from sales s join menu m on s.product_id=m.product_id
		group by s.customer_id,m.product_name)  as a		
where Ranking = 1

Result:
| customer_id	| product_name	| total_products | 
|  -----------  |   ----------- |  -----------   |
| 	A	|     ramen	| 	3	 | 
| 	B	|     sushi	| 	2	 | 
| 	B	|     curry	| 	2	 | 
| 	B	|     ramen	| 	2	 | 
| 	C	|     ramen	| 	3	 | 

Answer:
Customer A and C’s favourite item is ramen.
Customer B enjoys all items on the menu

--6. Which item was purchased first by the customer after they became a member?
with cte as (	select s.customer_id,
		   nu.product_name,
		   rank() over(partition by s.customer_id order by s.order_date) as ranking
	from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
	where s.order_date >= me.join_date
)
select ustomer_id,
       product_name
from cte
where ranking = 1

Result:
|  customer_id	|  product_name |
|  -----------  |  -----------  |  
|     A	        |     curry     |
|     B	        |     sushi     |

Answer:
Customer A’s first order as a member is ramen.
Customer B’s first order as a member is sushi.

--7. Which item was purchased just before the customer became a member?
with cte as (	select s.customer_id,
		   nu.product_name,
		   rank() over(partition by s.customer_id order by s.order_date desc) as ranking
	from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
	where s.order_date < me.join_date
)
select customer_id,
       product_name
from cte
where ranking = 1

Result:
|  customer_id	|   product_name  | 
|  -----------  |   -----------   |  
|      A	|     sushi       | 
|      A	|     curry	  | 
|      B	|     sushi       | 

Answer:
Last order of customer A are SuShi and Curry,customer B is only Sushi

--8. What is the total items and amount spent for each member before they became a member?
	select s.customer_id,
		COUNT(s.product_id) AS total_items,
		sum(nu.price) as amount
	from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
	where s.order_date < me.join_date
    group by s.customer_id
  
Result:
|  customer_id	|  total_items  |     amount    |
|  -----------  |  -----------  |  -----------  |  
|      A	|       2	|	25      |
|      B	|	3	|	40	|

Answer:
Before becoming members,
Customer A spent $25 on 2 items.
Customer B spent $40 on 3 items.
    
--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select
	s.customer_id,
	sum((case when nu.product_name = 'sushi' then (nu.price *20)
		else (nu.price*10) end)) as points
from sales s join menu nu on s.product_id = nu.product_id
group by s.customer_id

Result:
|  customer_id	|    points     |
|  -----------  |  -----------  |  
|	A	|	860     |
|	B	|	940	|
|	C	|	360	|

Answer:
The total points for Customers A, B and C are $860, $940 and $360.

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?
select
	s.customer_id,
	sum(case when s.order_date between me.join_date and DATEADD(DAY,6,me.join_date) then (nu.price*20)
	     when nu.product_name = 'sushi' then (nu.price*20)
		 else (nu.price*10) 
	end) tota_points
from members me join sales s on me.customer_id=s.customer_id
		 join menu nu on nu.product_id=s.product_id
where s.order_date <='2021-01-30'
group by s.customer_id

|   customer_id |   tota_points  |
|  -----------  |  -----------   | 
|	A	|	1370	 |
|	B	|	820	 |

Answer:
Customer A has 1,370 points.
Customer B has 820 points.

-- Bonus
---Join All The Things and Rank All The Things (Danny also requires further information about the ranking of customer products, 
		but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records 
		when customers are not yet part of the loyalty program.)
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

Result:
|  customer_id	|   order_date   |  product_name |    price       |	member    |	Ranking    |
|  -----------  |  -----------   |  -----------  |  -----------   |  -----------  |  -----------   | 
|	A	|   2021-01-01	 |	sushi	 |	10	  |	N	  |	NULL	   | 
|	A	|   2021-01-01	 | 	curry	 |	15	  | 	N	  |	NULL	   |
|	A	|   2021-01-07	 |	curry	 |	15	  |	Y	  |	1          |
|	A	|   2021-01-10	 |	ramen	 |	12	  |	Y	  |	2          |
|	A	|   2021-01-11	 |	ramen	 |	12	  |	Y	  |	3          |
|	A	|   2021-01-11   |	ramen	 |	12	  |	Y	  |     3	   |
|	B	|   2021-01-01	 |	curry	 |	15	  |	N	  |     NULL       |
|	B	|   2021-01-02	 | 	curry	 |	15	  |	N	  |	NULL       |
|	B	|   2021-01-04	 |	sushi	 |	10	  |	N	  |	NULL       |
|	B	|   2021-01-11	 |	sushi	 |	10	  |	Y	  |	1          |
|	B	|   2021-01-16	 |	ramen	 |	12	  |	Y	  |	2          |
|	B	|   2021-02-01	 |	ramen	 |	12	  |	Y	  |	3          |
|	C	|   2021-01-01	 |	ramen	 |	12	  |	N	  |	NULL       |
|	C	|   2021-01-01	 |	ramen	 |	12	  |	N	  |	NULL       |
|	C	|   2021-01-07	 |	ramen	 |	12	  |	N	  |	NULL       |

Summary:
From the analysis, we discover a few interesting things that would be certainly useful for Danny:
 - Customer B is the most frequent visitor with 6 visits 
 - Customer A spend  the most on the restaurant, so his total points is higher than B and C . He get 
 940 point
 - Ramen is the most purchased product, followed by curry and sushi
 - Customer A and C love ramen while customer B like eating sushi, curry and ramen equally
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
