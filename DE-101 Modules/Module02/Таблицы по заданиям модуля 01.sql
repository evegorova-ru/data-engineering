select o.*,p.person , r.returned 
from public.orders o 
	join public.people p on p.region = o.region 
	left join (select distinct r.order_id , r.returned from public."returns" r ) r on r.order_id = o.order_id 
	
select count( o.order_id ) --5009 distinct, 9994 all
from public.orders o 

select count( r.order_id ) --296 distinct, 800 all
from public."returns" r 

--Total Sales, Total Profit
select 
	date_part('year',o.order_date)  y,
	date_part('month',o.order_date) m, 
	sum(o.sales) sales,
	sum(o.profit) profit 
from public.orders o 
group by y, m
order by y, m

--Profit, Sales by category
select 
	date_part('year',o.order_date)  y,
	o.category ,
	sum(o.sales) sales,
	sum(o.profit) profit 
from public.orders o 
group by y, category 
order by y, category 


--Sales per Customer
select 
	p.person Customer,
	sum(o.sales) sales,
	sum(o.profit) profit 
from 
	public.orders o 
	join public.people p on p.region = o.region 
group by Customer

--Avg. Discount
select 
	date_part('year',o.order_date)  y,
	date_part('month',o.order_date) m, 
	sum(o.sales) sales,
	sum(o.profit) profit, 
	avg(o.discount) av_discount 
from public.orders o 
group by y, m
order by y, m
--Monthly Sales by Segment 
select 
	date_part('year',o.order_date)  y,
	o.segment segment,
	sum(o.sales) sales,
	sum(o.profit) profit
from public.orders o 
group by y, segment
order by y, segment

--Monthly Sales by Product Category 
select 
	date_part('year',o.order_date)  y,
	o.category category,
	sum(o.sales) sales,
	sum(o.profit) profit
from public.orders o 
group by y, category
order by y, category

--Sales and Profit by Customer
select 
	p.person Customer,
	sum(o.sales) sales,
	sum(o.profit) profit 
from 
	public.orders o 
	join public.people p on p.region = o.region 
group by Customer

--Customer Ranking
select 
	p.person Customer,
	sum(o.sales) sales,
	sum(o.profit) profit 
from 
	public.orders o 
	join public.people p on p.region = o.region 
group by Customer
order by sales

--Sales per region
select 
	o.region region,	
	sum(o.sales) sales,
	sum(o.profit) profit, 
	to_char ( (sum(o.sales)/(select sum(o.sales) from public.orders o) )*100, '99.99%') "%"
from 
	public.orders o 	
group by o.region 
	
--returned
select 
	r.returned returned,
	sum(o.sales) sales ,
	to_char ( (sum(o.sales)/(select sum(o.sales) from public.orders o) )*100, '99.99%') "%"

from public.orders o 
	left join (select distinct r.order_id , r.returned from public."returns" r ) r on r.order_id = o.order_id 
group by returned 
