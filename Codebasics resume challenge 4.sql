1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT distinct market 
     FROM dim_customer 
       WHERE customer = 'Atliq Exclusive' AND region = 'APAC';
   
-------------------------------------------------------------------------------------------------------------------
 2.What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

with cte_2020 as
(
SELECT count(distinct(product_code)) AS unique_products_2020 FROM fact_sales_monthly
WHERE fiscal_year = 2020
),
cte_2021 as
(
SELECT count(distinct(product_code)) AS unique_products_2021 FROM fact_sales_monthly
WHERE fiscal_year = 2021
),
cte_percentage as
(
SELECT round(((unique_products_2021) - (unique_products_2020)) / (unique_products_2020) * 100,2) as percentage_change
FROM cte_2020,cte_2021
)
 SELECT * FROM cte_2020,cte_2021,cte_percentage; 
 ---------------------------------------------------------------------------------------------------------------------
3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, segment product_count


SELECT segment,count(distinct(product_code)) AS product_count FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

--------------------------------------------------------------------------------------------------------------------------

4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference

with cte_2020 as (
SELECT dc.segment,
 count(distinct dc.product_code) AS product_count_2020
FROM dim_product AS dc INNER JOIN fact_sales_monthly AS fsm
ON dc.product_code = fsm.product_code
WHERE fiscal_year = 2020
GROUP BY dc.segment
ORDER BY product_count_2020 DESC
)
,cte_2021 AS (
SELECT dc.segment,
 count(distinct dc.product_code) AS product_count_2021
FROM dim_product as dc INNER JOIN fact_sales_monthly AS fsm
ON dc.product_code = fsm.product_code
WHERE fiscal_year = 2021
GROUP BY dc.segment
ORDER BY product_count_2021 DESC
)
SELECT cte_2020.segment, product_count_2020, product_count_2021, 
(product_count_2021-product_count_2020) AS Difference
FROM cte_2020 INNER JOIN cte_2021 
ON cte_2020.segment = cte_2021.segment
ORDER BY Difference DESC;
--------------------------------------------------------------------------------------------------------------

5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code product manufacturing_cost

SELECT DISTINCT
    dp.product_code,
    dp.product,
    fmc.manufacturing_cost
FROM
    dim_product AS dp
        INNER JOIN
    fact_manufacturing_cost AS fmc ON dp.product_code = fmc.product_code
WHERE
    fmc.manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR fmc.manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;
-----------------------------------------------------------------------------------------------------------
6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields, customer_code customer average_discount_percentage

select fpid.customer_code,dc.customer,round(avg(fpid.pre_invoice_discount_pct)*100,2) as average_discount_percentage
from dim_customer dc
inner join
fact_pre_invoice_deductions fpid
on
dc.customer_code = fpid.customer_code
where dc.market = 'India'
and
fpid.fiscal_year = 2021
group by dc.customer_code
order by average_discount_percentage desc
limit 5;

----------------------------------------------------------------------------------------------------------------------
7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month Year Gross sales Amount

select fsm.date,monthname(fsm.date) as month,year(fsm.date) as year,round(fgp.gross_price*fsm.sold_quantity,2) as Gross_sales_amount
from dim_customer dc
inner join
fact_sales_monthly fsm
on dc.customer_code = fsm.customer_code
inner join
fact_gross_price fgp
on fsm.product_code = fgp.product_code
where dc.customer = 'Atliq Exclusive'
group by month,year
order by date;
------------------------------------------------------------------------------------------------------------------------
8.In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity

WITH my_cte AS 
(
    SELECT *,
      CASE
         WHEN MONTH(date) IN(09,10,11) THEN 'First Quarter'
         WHEN MONTH(date) IN(12,01,02) THEN 'Second Quarter'
         WHEN MONTH(date) IN(03,04,05) THEN 'Third Quarter'
         WHEN MONTH(date) IN(06,07,08) THEN 'Fourth Quarter'
     END AS quarter
     from fact_sales_monthly
)
select quarter,sum(sold_quantity) as total_sold_quantity
from my_cte 
where fiscal_year =2020
group by quarter
order by total_sold_quantity;
---------------------------------------------------------------------------------------------------------------------
9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage

 with cte as (
select a.channel as Channel,
round(sum(c.gross_price*b.sold_quantity)/1000000,2) as Gross_sales_mln

FROM gdb023.dim_customer AS a JOIN
    gdb023.fact_sales_monthly AS b ON
    a.customer_code = b.customer_code JOIN
    fact_gross_price AS c on 
    c.fiscal_year = b.fiscal_year and 
    c.product_code = b.product_code
where b.fiscal_year = 2021
group by Channel
order by Gross_sales_mln desc
)
,cte1 as (
select sum(Gross_sales_mln) as Total_gross_sales_mln
from cte
)
select cte.*,
round((Gross_sales_mln*100/Total_gross_sales_mln),2) as Percentage
from cte join cte1;
----------------------------------------------------------------------------------------------------------------------
10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division product_code

with cte as (
SELECT dp.division ,
dp.product_code,
dp.product,
sum(fsm.sold_quantity) as Total_sold_quantity
FROM gdb023.dim_product AS dp INNER JOIN  gdb023.fact_sales_monthly AS fsm ON
dp.product_code = fsm.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY  Division, Product_code, dp.product
),
cte1 as (
SELECT *,
DENSE_RANK() OVER (PARTITION BY Division ORDER BY Total_sold_quantity DESC) AS Rank_Order
from  cte
)
select * 
from cte1
where Rank_Order <=3;
------------------------------------------------------------------------------------------------------------------------
