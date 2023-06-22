use Challenge
--====== B. Customer Transactions
--What is the unique count and total amount for each transaction type?
select txn_type,
		count(*) as total_transaction,
		sum(txn_amount) as total_amount
from customer_transactions
group by txn_type

--What is the average total historical deposit counts and amounts for all customers?
with cte as (		select customer_id,
						 txn_type,
				        count(*) as total_transaction,
						sum(txn_amount) as total_amount
				from customer_transactions
				where txn_type='deposit'
				group by customer_id,txn_type
				)
select  txn_type,
		avg(total_transaction) as avg_transaction,
		avg(total_amount) as avg_amount
from cte
group by  txn_type
--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
with cte as (select customer_id,
					   DATEPART(month,txn_date) as month_id,
					   DATENAME(MONTH,txn_date) as month_name,
					   sum(case when txn_type ='deposit' then 1
							else null end) as deposit_count,
						sum(case when txn_type ='purchase' then 1
							else null end) as purchase_count,
						sum(case when txn_type='withdrawal' then 1
							else null end) as withdrawal_count
				from customer_transactions
				group by customer_id,
					   DATEPART(month,txn_date),
					   DATENAME(MONTH,txn_date) 
				)
select  month_id,
		month_name,
		count(*) as total_customer
from cte
where (deposit_count >1 and purchase_count >=1) or (deposit_count >1 and withdrawal_count  >=1) 
group by  month_id,
		month_name
--What is the closing balance for each customer at the end of the month?
with cte as( select		customer_id,
						DATEADD(MONTH, DATEDIFF(MONTH, 0, txn_date), 0) as start_of_month,
						sum(case when txn_type='deposit' then txn_amount
							else -1* txn_amount end) as total_amount
				from customer_transactions
				group by customer_id,DATEADD(MONTH, DATEDIFF(MONTH, 0, txn_date), 0)
				--order by customer_id
				)
select 
	 customer_id,
	DATEPART(month,start_of_month) as month_id,
	DATENAME(month,start_of_month) as month_name,
   sum(total_amount) over(partition by customer_id order by start_of_month) as closing_balance
		
from cte 
group by customer_id,DATEPART(month,start_of_month),
	                 DATENAME(month,start_of_month),total_amount,start_of_month
order by customer_id


--What is the percentage of customers who increase their closing balance by more than 5%?
WITH monthly_transactions AS
(
	SELECT customer_id,
	       EOMONTH(txn_date) AS end_date,
	       SUM(CASE WHEN txn_type IN ('withdrawal', 'purchase') THEN -txn_amount
			ELSE txn_amount END) AS transactions
	FROM customer_transactions
	GROUP BY customer_id, EOMONTH(txn_date)
)
,
closing_balances AS 
(
	SELECT customer_id,
	       end_date,
	       COALESCE(SUM(transactions) OVER(PARTITION BY customer_id ORDER BY end_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0) AS closing_balance
	FROM monthly_transactions
)
,
pct_increase AS 
(
  SELECT customer_id,
         end_date,
         closing_balance,
         LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date) AS prev_closing_balance,
         100 * (closing_balance - LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date)) / NULLIF(LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY end_date), 0) AS pct_increase
 FROM closing_balances
)
SELECT CAST(100.0 * COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) AS FLOAT) AS pct_customers
FROM pct_increase
WHERE pct_increase > 5;