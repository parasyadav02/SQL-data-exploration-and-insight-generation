/*markets with atliq exclusicve */
SELECT market from dim_customer where region like "APAC" and customer like 'Atliq Exclusive';

/*products sold in 2021 vs in 2020 with change percent */

 create temporary table hel as(
select * from (select distinct(m.product_code),sum(m.sold_quantity) as unique_sold2020 from fact_sales_monthly m where 
fiscal_year=2020 group by(m.product_code))as cte2);
with cte1 as(
select distinct(m.product_code),sum(m.sold_quantity) as unique_sold2021 from fact_sales_monthly m where 
fiscal_year=2021 group by(m.product_code))

select n.*,m.unique_sold2020,n.unique_sold2021-m.unique_sold2020 as chg,((n.unique_sold2021-m.unique_sold2020)/m.unique_sold2020)*100 as chg_pct 
from cte1 n join hel m on n.product_code=m.product_code;

/*products in different segments */
SELECT distinct(m.segment),
count(distinct(m.product_code)) as no_of_products from gdb023.dim_product m
group by segment;


/*products in 2021 vs in 2020 */

create temporary table lop(select distinct(p.segment),count(distinct(p.product_code))as no_of_products21,sum(m.sold_quantity) as unique_Sold2021
 from
 dim_product p join fact_sales_monthly m on p.product_code=m.product_code  
 where m.fiscal_year=2021 group by segment);
with cte1 as(
select distinct(p.segment),count(distinct(p.product_code))as no_of_products20,sum(m.sold_quantity) as unique_Sold2020
 from
 dim_product p join fact_sales_monthly m on p.product_code=m.product_code  
 where m.fiscal_year=2020 group by segment)
 select e.*,p.no_of_products21,p.unique_Sold2021,p.unique_Sold2021-e.unique_Sold2020 as chg from cte1 e join
 lop p on e.segment=p.segment;
 
 /* product with min and max manufacturing cost*/ 
 
  SELECT n.product_code,m.product,n.manufacturing_cost FROM gdb023.fact_manufacturing_cost n join dim_product
m on m.product_code=n.product_code where manufacturing_cost in (select max(manufacturing_cost)from
gdb023.fact_manufacturing_cost) or manufacturing_cost in (select min(manufacturing_cost) from
gdb023.fact_manufacturing_cost);

/*top 5 customers with high avg discount in india */

with cte1 as
(SELECT m.customer_code,avg(m.pre_invoice_discount_pct) as avg_discount  from gdb023.fact_pre_invoice_deductions m
join dim_customer k on m.customer_code=k.customer_code
where m.fiscal_year=2021
group by m.customer_code
)
select c.*,m.customer from cte1 c join dim_customer m on 
m.customer_code=c.customer_code where m.market like "india"
order by avg_discount desc limit 5;

/* gross sales by customer atliq exclusive over the course of years*/

SET sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));
with cte1 as(
select e.customer,month(s.date) as month,s.fiscal_year,(s.sold_quantity)*p.gross_price as gross_sales 
from fact_sales_monthly s join fact_gross_price p on s.product_code=p.product_code and
p.fiscal_year=s.fiscal_year join dim_customer e on s.customer_code=e.customer_code
where e.customer like 'Atliq Exclusive'
 group by s.fiscal_year,s.date

)
select * from cte1
 order by fiscal_year;
 
 /*quarter vise products sold*/
 
with cte1 as(
select month(s.date) as month,s.fiscal_year,(s.sold_quantity),
case
when month(s.date) in (9,10,11) then "q1"
when month(s.date) in (12,1,2) then "q2"
when month(s.date) in (3,4,5) then "q3"
when month(s.date) in (6,7,8) then "q4"

end as quarter
from fact_sales_monthly s 


 group by s.fiscal_year,s.date

)
select c.quarter,sum(c.sold_quantity) as sold_product from cte1 c 
where c.fiscal_year=2020
group by c.quarter
;

/*division and percentage contribution to total sales in  mln */

SET sql_mode = (SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));
with cte1 as(
select e.division,month(s.date) as month,s.fiscal_year,round(sum((s.sold_quantity)*p.gross_price)/1000000,2) as mln
from fact_sales_monthly s join fact_gross_price p on s.product_code=p.product_code and
p.fiscal_year=s.fiscal_year join dim_product e on s.product_code=e.product_code
  where s.fiscal_year=2021
 group by s.fiscal_year,e.division
)
select c.*,(sum(c.mln)/sum(c.mln)over())*100 as percentage_contribution from
cte1 c
group by division
 order by c.fiscal_year;