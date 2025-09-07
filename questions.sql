-- -----------------------------------------
-- Advance Query Questions
-- -----------------------------------------


select * from customer;
select * from deliveries;
select * from orders;
select * from restaurants;
select * from riders;



/*
Task 1: 
write a Query to find the top 5 most frequently ordered dishes by customers in the last 1 year
*/

select 
cst.customer_id,
cst.customer_name,
ord.order_item as dishes,
count(*) as total_ordered
from customer as cst
join 
orders as ord
on cst.customer_id = ord.customer_id
where 
ord.order_date >= CURDATE() - INTERVAL 1 YEAR
group by cst.customer_id,
cst.customer_name,
ord.order_item
order by total_ordered desc 
;



/*
Task 2:
Identify the time slots during which the most orders are placed based on 2 hour intervals
*/

#Approach 1

select 
	case
		when hour( order_time) between 0 and 1 then '00:00 - 02:00'
        when hour( order_time) between 2 and 3 then '02:00 - 04:00'
        when hour( order_time) between 4 and 5 then '04:00 - 06:00'
        when hour( order_time) between 6 and 7 then '06:00 - 08:00'
        when hour( order_time) between 8 and 9 then '08:00 - 10:00'
        when hour( order_time) between 10 and 11 then '10:00 - 12:00'
        when hour( order_time) between 12 and 13 then '12:00 - 14:00'
        when hour( order_time) between 14 and 15 then '14:00 - 16:00'
        when hour( order_time) between 16 and 17 then '16:00 - 18:00'
        when hour( order_time) between 18 and 19 then '18:00 - 20:00'
        when hour( order_time) between 20 and 21 then '20:00 - 22:00'
        when hour( order_time) between 22 and 23 then '22:00 - 00:00'
	
	end as time_slot,
    
    count(order_id) as order_count

		
 from orders
 group by time_slot
 order by order_count desc;
 
 
 
 # Approach 2
 
 select 
 
	floor(hour(order_time)/2) * 2 as start_time,
    floor(hour(order_time)/2) * 2 + 2 as end_time,
    count(*) as total_orders
    
 from orders
 
 group by start_time , end_time
 order by total_orders desc;
 
 
 /*
 Task 3:
 Find the average order value per customer who has placed more than 50 orders.
 return customer_name , aov(average order value)
 */
 
 select 
	cst.customer_name,
	cst.customer_id,
    avg(total_amount) as aov,
    count(order_id) as total_orders
 from orders as ord
 join
 customer as cst
 on ord.customer_id = cst.customer_id
 group by customer_id
 having count(order_id) > 25
 order by count(order_id) desc ; 
 
 /*
 Task 4:
 List the customer who have spent more than 10k in total food orders return customer_name , customer_id
 */
 
 select 
	cst.customer_name,
	ord.customer_id,
    sum(total_amount) as total_expense
 from orders as ord
 join
 customer as cst
 on ord.customer_id = cst.customer_id
 group by customer_id
 having sum(total_amount) between 20000 and 50000;
 
 /*
 Task 5:
 Write a Query to find orders that were placed but cancelled
 return each restaurant name , city , and number of cancelled orders
 
 */
 
 
select 

    rst.restaurant_name,

    count(ord.order_id) as cancelled_order
from orders as ord
left join
restaurants as rst
on ord.restaurant_id = rst.restaurant_id
left join
deliveries as del
on ord.order_id = del.order_id
where del.delivery_time is null
group by
    rst.restaurant_name
order by count(ord.order_id) desc 
;

/*
Task 6:
Rank Restaurant by their annual total revenue from the last year including their name , total revenue and rank within their city.alter
*/
 
select 
	rst.restaurant_id,
    rst.restaurant_name,
    rst.city,
    sum(ord.total_amount) as total_revenue,
    rank() over(
		partition by rst.city 
        )
        as city_ranking
from orders as ord
join 
restaurants as rst
on ord.restaurant_id = rst.restaurant_id
where ord.order_date >= curdate() - interval 1 year
group by rst.restaurant_id ,
		 rst.restaurant_name , 
         rst.city
 order by sum(ord.total_amount) desc;



/*
Task 7:
Most Poplular dish by city
Identify the most popular dish in each city based on the number of orders
*/

#using CTE

with ranking_table
as
(
		select 
			rst.city,
			ord.order_item as dish,
			count(ord.order_id) as dish_count,
			rank() over(partition by rst.city order by count(ord.order_id) desc) as dish_ranking
		from orders as ord
		join
		restaurants as rst
		on ord.restaurant_id = rst.restaurant_id
		group by rst.city,
		ord.order_item
)

select 
*
from ranking_table 
where dish_ranking = 1;


# using subquery

select
*
from
(
select 
	rst.city,
	ord.order_item as dish,
	count(ord.order_id) as dish_count,
	rank() over(partition by rst.city order by count(ord.order_id) desc) as dish_ranking
from orders as ord
join
restaurants as rst
on ord.restaurant_id = rst.restaurant_id
group by rst.city,
ord.order_item
) as t1

where dish_ranking = 1;


/*
Task 8:
Customer Churn:
Find Customers who haven't placed an order in 2024 but did in 2023.
*/

select 
	distinct customer_id
from orders
where year(order_date) = 2023
and
customer_id not in
(select distinct customer_id
from orders as ord
where year(order_date) = 2024);


/*
Task 9:
calculate and compare the order cancellation rate for each restaurant between the current year and the previous year.
*/

#for year 2025

with cancel_ratio_2025
as(
select 
	ord.restaurant_id,
    count(ord.order_id) as total_orders,
    count(case when del.delivery_status = 'Cancelled' then 1 end) as cancelled_orders
from orders as ord
left join
deliveries as del
on ord.order_id = del.order_id
where year(order_date) = 2025
group by ord.restaurant_id
 
),
cancel_ratio_2024
as
(
select 
	ord.restaurant_id,
    count(ord.order_id) as total_orders,
    count(case when del.delivery_status = 'Cancelled' then 1 end) as cancelled_orders
from orders as ord
left join
deliveries as del
on ord.order_id = del.order_id
where year(order_date) = 2024
group by ord.restaurant_id
 
)
,
current_year_data
as
(
SELECT
    restaurant_id,
    total_orders,
    cancelled_orders,
    ROUND(
        (CAST(cancelled_orders AS DECIMAL(10,2)) / NULLIF(CAST(total_orders AS DECIMAL(10,2)), 0)) * 100,
        2
    ) AS cancellation_ratio
FROM cancel_ratio_2025
)
,
last_year_data as
(
SELECT
    restaurant_id,
    total_orders,
    cancelled_orders,
    ROUND(
        (CAST(cancelled_orders AS DECIMAL(10,2)) / NULLIF(CAST(total_orders AS DECIMAL(10,2)), 0)) * 100,
        2
    ) AS cancellation_ratio
FROM cancel_ratio_2024
)

select 
	cyd.restaurant_id as rest_id,
    cyd.cancellation_ratio cy_ratio,
    lyd.cancellation_ratio ly_ratio
from current_year_data as cyd
join
last_year_data as lyd
on cyd.restaurant_id = lyd.restaurant_id;


/*
Task 10: Rider average Delivery Time
Determine each rider's average delivery time
*/

select 
	ord.order_id,
    ord.order_time,
    del.delivery_time,
    del.rider_id,
    SEC_TO_TIME(MOD(TIME_TO_SEC(delivery_time) - TIME_TO_SEC(order_time) + 86400, 86400)) as time_diff
	#avg(time(del.delivery_time)) as rider_avg_time
 from orders as ord
 join
 deliveries as del
 on ord.order_id = del.order_id
 where del.delivery_status = 'Delivered';
 
 


/*
Task 11: 
Determine each rider's delivery time and impose a fine if rider take more than 30 mintues to deliver the order
*/

with rider_penality
as(

select 
	ord.order_id,
    ord.order_time,
    del.delivery_time,
    del.rider_id,
    SEC_TO_TIME(MOD(TIME_TO_SEC(delivery_time) - TIME_TO_SEC(order_time) + 86400, 86400)) as time_diff
	#avg(time(del.delivery_time)) as rider_avg_time
 from orders as ord
 join
 deliveries as del
 on ord.order_id = del.order_id
 where del.delivery_status = 'Delivered'
 )
 
SELECT 
    order_id,
    order_time,
    delivery_time,
    time_diff,
    SEC_TO_TIME(MOD(TIME_TO_SEC(delivery_time) - TIME_TO_SEC(order_time) + 86400, 86400)) AS time_diff_penality,
    
    CASE 
        WHEN MOD(TIME_TO_SEC(delivery_time) - TIME_TO_SEC(order_time) + 86400, 86400) > 3600 THEN 'Fine'
        ELSE 'No Fine'
    END AS penalty_status
FROM rider_penality;


/*
Task 12: Calculate each Restaurant's growth ratio based on the total number of delivered orders since its joining
*/

select 
	ord.restaurant_id,
    date_format(ord.order_date , '%m-%y') as month_year,
    count(ord.order_id) as delivered_order
from orders as ord
join 
deliveries as del
on ord.order_id = del.order_id
where del.delivery_status = 'Delivered'
group by ord.restaurant_id,
month_year
order by ord.restaurant_id,
month_year;







WITH monthly_orders AS (
    SELECT 
        ord.restaurant_id,
        DATE_FORMAT(ord.order_date, '%Y-%m') AS month_year,
        COUNT(ord.order_id) AS delivered_orders
    FROM orders AS ord
    JOIN deliveries AS del
      ON ord.order_id = del.order_id
    WHERE del.delivery_status = 'Delivered'
    GROUP BY ord.restaurant_id, month_year
),

first_month_orders AS (
    SELECT 
        restaurant_id,
        MIN(month_year) AS first_month
    FROM monthly_orders
    GROUP BY restaurant_id
),

base_orders AS (
    SELECT 
        mo.restaurant_id,
        mo.month_year,
        mo.delivered_orders,
        fmo.first_month
    FROM monthly_orders mo
    JOIN first_month_orders fmo
      ON mo.restaurant_id = fmo.restaurant_id
),

first_month_values AS (
    SELECT 
        restaurant_id,
        delivered_orders AS first_month_orders
    FROM base_orders
    WHERE month_year = first_month
)

SELECT 
    b.restaurant_id,
    b.month_year,
    b.delivered_orders,
    f.first_month_orders,
    ROUND(b.delivered_orders / f.first_month_orders, 2) AS growth_ratio
FROM base_orders b
JOIN first_month_values f
  ON b.restaurant_id = f.restaurant_id
ORDER BY b.restaurant_id, b.month_year;


/*
Task 13: Customer Segmentation: Segment customers into 'Gold' or 'Silver' groups based on their total spending
compared to the average order value (AOV). If a customer's total spending exceeds the AOV,
label them as 'Gold'; otherwise, label them as 'Silver'. Write an SQL query to determine each segment's
total number of orders and total revenue
*/


select
	customer_category,
    round(sum(total_spent), 2) as total_revenue,
    sum(total_orders) as total_orders
from

	(select 
			customer_id,
			sum(total_amount) as total_spent,
			count(order_id) as total_orders,
			Case 
				when sum(total_amount) > (select avg(total_amount) as AOV from orders)  then 'Gold'
				else 'Silver'
			end as customer_category
	from orders
	group by customer_id
	) as customer_data
group by customer_category
;


/*
Task 14: Rider Monthly Earnings:
Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
*/


select
	del.rider_id,
    DATE_FORMAT(order_date, '%m-%Y') AS month_no,
    round(sum(total_amount), 2) as total_revenue,
    round(sum((total_amount) * 0.008), 2)as Rider_earning
from orders as ord
join 
deliveries as del
on ord.order_id = del.order_id
where rider_id is not null
group by del.rider_id, month_no
order by del.rider_id , month_no;


/*
Q.14 Rider Ratings Analysis:
Find the number of 5-star, 4-star, and 3-star ratings each rider has.
riders receive this rating based on delivery time.
If orders are delivered less than 15 minutes of order received time the rider get 5 star rating,
if they deliver 15 and 20 minute they get 4 star rating
if they deliver after 20 minute they get 3 star rating.
*/


SELECT 
    del.rider_id,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, ord.order_time, del.delivery_time) < 15 THEN 1 ELSE 0 END) AS five_star,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, ord.order_time, del.delivery_time) BETWEEN 15 AND 20 THEN 1 ELSE 0 END) AS four_star,
    SUM(CASE WHEN TIMESTAMPDIFF(MINUTE, ord.order_time, del.delivery_time) > 20 THEN 1 ELSE 0 END) AS three_star
FROM orders ord
JOIN deliveries del ON ord.order_id = del.order_id
GROUP BY del.rider_id
order by del.rider_id ;

/*
Task 16:
Order Frequency by Day;
Analyze order frequency per day of the week and identify the peak day for each restaurant
*/


 
 SELECT restaurant_id, day_name, total_orders
FROM (
    SELECT 
        ord.restaurant_id,
        DAYNAME(ord.order_date) AS day_name,
        COUNT(*) AS total_orders,
        RANK() OVER (
            PARTITION BY ord.restaurant_id 
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM orders ord
    GROUP BY ord.restaurant_id, day_name
) t
WHERE rnk = 1;

/*
Task 17:
Customer Lifetime value(CLV)
Calculate the total revenue generated by each customer over all their orders
*/

select * from orders;
select
	cst.customer_id,
    cst.customer_name,
    floor(sum(total_amount) ) as CLV
from orders as ord
join customer as cst
on ord.customer_id = cst.customer_id
group by cst.customer_id;

/*
TAsk 18:
Monthly Sales Trends:
Identify sales trends by comparing each month's total sales to the previous month.
*/

select 
	year(order_date) as year_name,
    month(order_date) as month_name,
    floor(sum(total_amount)) as total_sale,
    lag(sum(total_amount) , 1)   over(order by year(order_date) , month(order_date)) as previous_month_sales
from orders
group by year_name, month_name
;

/*
Task 19: Rider Efficency
Evaluate Ride Efficiency by determining average delivery times and identifying  those with the lowest and highest average.
*/

with delivery_table
as
(
	select 
		d.rider_id as riders_id,
		timestampdiff(minute, o.order_time, d.delivery_time) as delivery_time
	from orders as o
	join 
	deliveries as d
	on o.order_id = d.order_id
	where d.delivery_status = 'Delivered'

),

average_delivery_time
as
(
	select
		riders_id ,
		avg(delivery_time) as avg_delivery_time
	from delivery_table
	group by riders_id
)

select 
	min(avg_delivery_time),
    max(avg_delivery_time)
from average_delivery_time;


/*
Task 20:
Order Item Popularity
Track the Popularity of Specific order items over time and identify seasonal demand spikes
*/
select
	order_item,
    seasons,
    count(order_id) as total_orders
from
(
select
		*,
		month(order_date) as month,
		case 
			when month(order_date) between 3 and 5 then 'spring'
			when month(order_date) > 5 and month(order_date) < 9 then 'summer'
			else
			'winter'
		end as seasons
from orders
) as t1
group by order_item, seasons
order by order_item , total_orders desc
;


/*
Rank each city based on the total revenue for last year 2024
*/

select 
	r.city,
    floor(sum(o.total_amount)) as total_revenue,
    rank() over(order by floor(sum(o.total_amount)) desc) as city_rank
from orders as o
join restaurants as r
on o.restaurant_id = r.restaurant_id
group by r.city;


/* END OF QUERY */