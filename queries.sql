create table trader.orders(
order_id INT PRIMARY KEY,
customer_id CHARACTER varying,
employee_id INT,
order_date DATE,
required_date DATE,
shipped_date DATE,
shipper_name CHARACTER VARYING,
freight_cost numeric
);
create table trader.order_details(
order_id INT, 
product_id INT,
unit_price numeric,
quantity INT,
discount numeric,
primary key (order_id, product_id)
);
create table trader.products(
product_id INT primary key,
product_name CHARACTER VARYING, 
quantity_per_unit CHARACTER VARYING,
discontinued INT,
category_name CHARACTER VARYING
);
create table trader.employees(
employee_id INT primary key,
employee_name CHARACTER VARYING,
title CHARACTER VARYING,
city CHARACTER VARYING,
country CHARACTER VARYING
);

select *
from trader.employees 

select *
from trader.order_details 

select *
from trader.orders

select *
from trader.products

--1. Berapa hari rata-rata durasi dari pesanan dari konsumen sampai pengiriman?
select avg(shipped_date-order_date) as avg_day
from trader.orders 
where shipped_date is not null;

--2. Pada saat-saat kapan biasanya penjualan kita ramai?
select 
		extract (year from order_date) as year,
		extract (month from order_date) as month,
		count(*) as total_order
from 	trader.orders
group by year, month
order by total_order desc;

--3. Urutkan vendor shipping berdasarkan rasio ongkos kirim dengan penjualan bersih (setelah diskon) selama ini.
select 
		shipper_name,
		sum(unit_price * quantity*(1-discount)) as total_sales,
		sum(freight_cost) as total_freight,
		sum(freight_cost) / sum(unit_price * quantity*(1-discount)) as ratio
from trader.orders as o 
join trader.order_details od 
	on o.order_id = od.order_id
group by o.shipper_name 
order by ratio asc;

--4.Tunjukkan 5 produk unggulan dan 5 produk terburuk kita selama ini.
(select 
		p.product_name,
		sum(od.unit_price * od.quantity * (1 - od.discount)) as total_sales,
		'TOP' as category
from 	trader.order_details od 
join 	trader.products p 
		on od.product_id = p.product_id 
group by p.product_name 
order by total_sales desc
limit 5)

UNION ALL

(select 
		p.product_name,
		sum(od.unit_price * od.quantity * (1 - od.discount)) as total_sales,
		'BOTTOM' as category
from 	trader.order_details od 
join 	trader.products p 
		on od.product_id = p.product_id 
group by p.product_name 
order by total_sales asc
limit 5);

--5. Manajer penjualan ingin mengetahui:
--performa penjualan kotor (sebelum diskon) 
--dan penjualan bersih (setelah diskon) selama ini. 
--Dia meminta data total penjualan tersebut beserta total pesanan per bulan. Tolong bantu menyediakan data ini.
select 
	extract (month from o.order_date) as month,
	sum(od.unit_price * od.quantity) as gross_sales,
	sum(od.unit_price * od.quantity *(1 - od.discount)) as net_sales,
	count(distinct o.order_id) as total_orders
from trader.orders as o
join trader.order_details as od
	on o.order_id = od.order_id
group by month
order by month


--6. Lebih lanjut lagi, manajer penjualan meminta data pertumbuhan total penjualan kotor dari tahun ke tahun. Sediakan data yang diminta.
select 
	year,
	gross_sales,
	lag(gross_sales) over (order by year) as prev_sales,
	(gross_sales -lag(gross_sales) over (order by year)) / lag(gross_sales) over (order by year) as growth
from (
	select
		extract (year from o.order_date) as year,
		sum(od.unit_price * od.quantity) as gross_sales
	from trader.orders as o
	join trader.order_details as od
		on o.order_id = od.order_id
	group by year
) t
order by year

--7. Perusahaan ingin memberikan penghargaan kepada para pegawai penjualan setelah sumbangsih mereka selama ini. 
--Urutkan nama karyawan bidang sales dari yang kontribusi penjualannya terbesar selama ini beserta besaran penjualannya.
select 
	employee_name,
	total_sales,
	rank() over (order by total_sales desc) as rank
from(
	select
		e.employee_name,
		sum(od.unit_price * od.quantity * (1 - discount)) as total_sales
	from trader.orders o
	join trader.order_details od
		on o.order_id = od.order_id
	join trader.employees e
		on o.employee_id = e.employee_id 
	group by e.employee_name 
)t
order by total_sales desc

--8. Manajer produk ingin mengetahui kontribusi dari setiap kategori produk terhadap penjualan total per tahunnya. 
--Tolong sediakan data yang diminta dan urutkan tahunnya.
select 
	year,
	category_name,
	total_sales,
	total_sales / sum(total_sales) over (partition by year) as contribution
from (
	select
		extract (year from o.order_date) as year,
		p.category_name, 
		sum(od.unit_price * od.quantity * (1 - od.discount)) as total_sales
	from trader.orders o
	join trader.order_details od
		on o.order_id = od.order_id
	join trader.products p
	 	on od.product_id = p. product_id
	group by year, p.category_name
)t
order by year, contribution desc
	
	
