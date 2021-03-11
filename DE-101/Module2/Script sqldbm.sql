--
create schema dw;

-- ************************************** Calendar
drop table if exists dw.Calendar;

CREATE TABLE dw.Calendar
(
 date_id date  NOT NULL,
 "date"     date NOT NULL,
 year     int NOT NULL,
 quater   varchar(50) NOT NULL,
 month    int NOT NULL,
 week     int NOT NULL,
 week_day varchar(50) NOT NULL,
 CONSTRAINT PK_calendar PRIMARY KEY ( "date" )
);
truncate table dw.Calendar;--deleting rows
select * from dw.Calendar;
--generating Calendar 
insert into dw.Calendar 
select 
	date::date,	
	date::date as date_id,
 	extract('year' from date)::int as year,
 	extract('quarter' from date)::int as quarter,
 	extract('month' from date)::int as month,
 	extract('week' from date)::int as week,
 	to_char(date, 'dy') as week_day   
from 
	generate_series(date '2015-01-01',
                       date '2030-01-01',
                       interval '1 day')
	as t(date);


-- ************************************** customer
drop table if exists dw.customer
CREATE TABLE dw.customer
(
 cust_id       serial NOT NULL,
 custom_id     varchar(8) NOT NULL,
 customer_name varchar(22) NOT NULL,
 CONSTRAINT PK_customer PRIMARY KEY ( cust_id )
);
truncate table dw.customer;--deleting rows
select * from dw.customer;
--generating customer_id and inserting customer from orders
insert into dw.customer 
select 
	row_number() over() cust_id, 
	a.customer_id   custom_id,
 	a.customer_name customer_name
from (select distinct customer_id,customer_name from public.orders) a;




-- ************************************** geography
drop table if exists dw.geography
CREATE TABLE dw.geography
(
 geo_id      serial NOT NULL,
 country     varchar(13) ,--NOT NULL
 city        varchar(17) ,--NOT NULL
 state        varchar(20) ,--NOT NULL
 postal_code varchar(20) ,--NOT NULL
 CONSTRAINT PK_geography PRIMARY KEY ( geo_id )
);
truncate table dw.geography;--deleting rows
select * from dw.geography;
--generating customer_id and inserting geography from orders
insert into dw.geography 
select 
	row_number() over() cust_id, 
	a.country   country,
 	a.city city,
 	a.state,
 	a.postal_code
from (select distinct country, city, state,postal_code from public.orders) a;

--data quality check
select distinct country, city, state, postal_code from dw.geography
where country is null or city is null or postal_code is null;

-- City Burlington, Vermont doesn't have postal code
update dw.geography
set postal_code = '5401'
where city = 'Burlington'  and postal_code = '05401' --is null;

--also update source file
update public.orders
set postal_code = '5401'
where city = 'Burlington'  and postal_code  -- is null;


select * from dw.geography
where city = 'Burlington'
select * from public.orders o
where city = 'Burlington'



-- ************************************** product
drop table if exists dw.product
CREATE TABLE dw.product
(
 prod_id      serial NOT NULL,
 product_id   varchar(50) NOT NULL,
 product_name varchar(127) NOT NULL,
 category     varchar(15) NOT NULL,
 sub_category varchar(11) NOT NULL,
 segment      varchar(11) NOT NULL,
 CONSTRAINT PK_product PRIMARY KEY ( prod_id )
);

truncate table dw.product;--deleting rows
select * from dw.product;
--generating prod_id and inserting product from orders
insert into dw.product 
select 
	row_number() over() prod_id, 
	a.product_id   product_id,
 	a.product_name product_name,
 	a.category     category,
 	a.subcategory sub_category,
 	a.segment      segment
from (select distinct product_id,product_name,category,subcategory,segment from public.orders) a;

-- ************************************** shipping
drop table if exists dw.shipping;
CREATE TABLE dw.shipping --creating a table
(
 ship_id       serial NOT NULL,
 shipping_mode varchar(14) NOT NULL,
 CONSTRAINT PK_shipping PRIMARY KEY ( ship_id )
);

truncate table dw.shipping;--deleting rows
select * from dw.shipping;
--generating ship_id and inserting ship_mode from orders
insert into dw.shipping 
select 
	100+row_number() over() ship_id, 
	a.ship_mode shipping_mode 
from (select distinct ship_mode from public.orders ) a;

--checking
select * from dw.shipping sd; 


-- ************************************** sales_fact
drop table if exists dw.sales_fact;
CREATE TABLE dw.sales_fact
(
 sales_id      serial NOT NULL,
 order_date_id date NOT NULL,
 ship_date_id  date NOT NULL,
 sales         numeric(9,4) NOT NULL,
 profit        numeric(21,16) NOT NULL,
 quantity      int4 NOT NULL,
 discount      numeric(4,2) NOT NULL,
 cust_id       integer NOT NULL,
 prod_id       integer NOT NULL,
 geo_id        integer NOT NULL,
 ship_id       integer NOT NULL,
 order_id      varchar(25) NOT NULL,
 CONSTRAINT PK_sales_fact PRIMARY KEY ( sales_id ),
 CONSTRAINT FK_68 FOREIGN KEY ( cust_id ) REFERENCES dw.customer ( cust_id ),
 CONSTRAINT FK_71 FOREIGN KEY ( prod_id ) REFERENCES dw.product ( prod_id ),
 CONSTRAINT FK_74 FOREIGN KEY ( geo_id ) REFERENCES dw.geography ( geo_id ),
 CONSTRAINT FK_84 FOREIGN KEY ( ship_id ) REFERENCES dw.shipping ( ship_id )
);

CREATE INDEX fkIdx_69 ON sales_fact
(
 cust_id
);

CREATE INDEX fkIdx_72 ON sales_fact
(
 prod_id
);

CREATE INDEX fkIdx_75 ON sales_fact
(
 geo_id
);

CREATE INDEX fkIdx_85 ON sales_fact
(
 ship_id
);

truncate table dw.sales_fact;--deleting rows
select * from dw.sales_fact;
--generating from dementions tables
insert into dw.sales_fact 
select 
	row_number() over() sales_id, 
	order_date_id ,
 	ship_date_id  ,
 	sales         ,
 	profit       ,
 	quantity      ,
 	discount      ,
 	cust_id       ,
 	prod_id       ,
 	geo_id        ,
 	ship_id       ,
 	order_id      
from 
	(select 
		s2.ship_id ,
		c2.cust_id ,
		g2.geo_id ,
		p2.prod_id ,
		o.order_id ,
		o.discount ,
		o.quantity,
		o.profit,
		o.sales,
		o.ship_date ship_date_id,
		o.order_date order_date_id
		from public.orders o 
		join dw.shipping s2 on o.ship_mode =s2.shipping_mode
		join dw.customer c2 on c2.custom_id=o.customer_id
	    join dw.geography g2 on g2.city = o.city and g2.country = o.country and g2.state = o.state and g2.postal_code = CAST(o.postal_code AS VARCHAR(20))
	   left join dw.product p2 on p2.product_id=o.product_id and p2.segment = o.segment and p2.category =o.category  and p2.sub_category =o.subcategory and p2.product_name = o.product_name 
	) a;
	
select count(sf.ship_id ) from dw.sales_fact sf  -- 9994 

