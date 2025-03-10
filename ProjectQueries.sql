-- I. SALES TRENDS
-- *****************
/* Q1: Which months record the highest number of orders, and which
       store is responsible for the largest share of these orders? */
       
WITH cte AS
	(
	SELECT COUNT(order_id) AS No_of_orders ,MONTHNAME(order_date) AS Month
	FROM orders
	GROUP BY Month
	ORDER BY No_of_orders DESC
	),
	cte2 AS
	(
	SELECT count(orders.order_id) No_of_orders, monthname(orders.order_date) Month, stores.store_name, 
	RANK()OVER(PARTITION BY monthname(orders.order_date) ORDER BY count(orders.order_id) DESC) AS rnk
	FROM orders JOIN stores
	ON orders.store_id=stores.store_id
	GROUP BY stores.store_name,Month
	ORDER BY Month
	)
SELECT cte.*,cte2.store_name AS Store_with_max_orders
FROM cte JOIN cte2 ON cte.Month=cte2.Month
WHERE cte2.rnk=1
ORDER BY 1 DESC ;

/* Q2: What is the progression of revenue over time for each category 
	   and which categories show significant growth decline? */
       
SELECT year(o.order_date) as year,c.category_name,ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS tot_rev
FROM orders o JOIN order_items oi ON o.order_id=oi.order_id 
JOIN products p ON oi.product_id=p.product_id
JOIN categories c ON c.category_id=p.category_id
GROUP BY c.category_name,year
ORDER BY c.category_name DESC,year ASC; 

-- II. PRODUCT & CATEGORY ANALYSIS
-- *********************************
/* Q3: Which bike categories generate the highest revenue? */

SELECT c.category_name,ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS tot_rev
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name 
ORDER BY tot_rev DESC;

/* Q4: Which is the most expensive bike category on an average? */
 
WITH cte AS
	 (      
	SELECT c.category_name,SUM(p.list_price) AS price
	FROM products p JOIN categories c
	ON p.category_id=c.category_id
	GROUP BY c.category_name
	ORDER BY price DESC
    ),
num AS 
	(
	SELECT c.category_name,COUNT(p.product_id) AS cn 
	FROM products p JOIN categories c
	ON p.category_id=c.category_id
	GROUP BY c.category_name
	)
SELECT cte.category_name,round((cte.price/num.cn ),2) AS avg_price
FROM cte JOIN num ON cte. category_name=num.category_name
ORDER BY avg_price DESC;

/* Q5: Write a query to track the number of units sold over time for each brand,
		reflecting consumer demand trends */
        
SELECT YEAR(o.order_date) as year, b.brand_name, SUM(oi.quantity) as No_of_units_sold
FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
JOIN products p ON p.product_id=oi.product_id
JOIN brands b ON b.brand_id=p.brand_id
GROUP BY b.brand_name,year
ORDER BY b.brand_name DESC,year ASC;

-- III. STAFF & STORE PERFORMANCE
-- ********************************
/* Q6: Which store contributes the most to the sales? */

WITH RECURSIVE 
	rev_per_store AS (
	SELECT s.store_name,ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS revenue
	FROM orders o JOIN stores s ON o.store_id=s.store_id
	JOIN order_items oi ON o.order_id=oi.order_id
	GROUP BY s.store_name
	ORDER BY revenue DESC),
	sum_rev AS (SELECT sum(revenue) AS total
	FROM rev_per_store)
SELECT rev_per_store.*,concat(ROUND(100*rev_per_store.revenue/(sum_rev.total)),"%") as percentage_of_total
FROM rev_per_store JOIN sum_rev ;

/* Q7: Which store has the highest number of deliveries that were rejected? */

SELECT count(*) as Rejected_Deliveries , store_name 
FROM orders o JOIN stores s ON o.store_id=s.store_id
WHERE order_status=3
GROUP BY store_name
ORDER BY 1 DESC ; 

/* Q8: Write a query that returns the store name and staff name who has
	   generated the most revenue of top 3 best selling bike categories. */
       
WITH best_selling_category AS
	(SELECT categories.category_id,categories.category_name,SUM(order_items.quantity) AS No_of_units_sold
	FROM order_items
	JOIN products ON order_items.product_id = products.product_id
	JOIN categories ON products.category_id = categories.category_id
	GROUP BY categories.category_name,categories.category_id
	ORDER BY No_of_units_sold DESC
	LIMIT 3),
	CTE AS 
	(SELECT sto.store_name,CONCAT(sta.first_name,' ',sta.last_name) AS staff_name,
	ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) as sales,c.category_name,
	RANK()OVER(PARTITION BY c.category_name ORDER BY ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) DESC) as rnk
	FROM orders o JOIN stores sto ON o.store_id=sto.store_id
	JOIN staffs sta ON sta.staff_id=o.store_id
	JOIN order_items oi ON oi.order_id=o.order_id
	JOIN products p on p.product_id=oi.product_id
	JOIN categories c on p.category_id=c.category_id
	WHERE p.category_id in (SELECT category_id FROM best_selling_category)
	GROUP BY store_name,staff_name,c.category_name)
SELECT  best_selling_category.category_name,store_name,staff_name,sales 
FROM CTE JOIN best_selling_category ON cte.category_name=best_selling_category.category_name
WHERE rnk=1 
ORDER BY sales DESC; 

/* Q9: We want to find out the most popular bike category for each store. We detemine the most popular 
	    bike category as the one with the highest amount of purchases. Write a query that returns
        each store along with the top category. */
       
WITH CTE AS 
(SELECT st.store_name,c.category_name AS most_popular_category,SUM(oi.quantity) AS no_of_units_sold,
RANK()OVER(PARTITION BY st.store_name ORDER BY SUM(oi.quantity) DESC) AS rnk 
FROM orders o JOIN stores st ON o.store_id=st.store_id
JOIN order_items oi ON oi.order_id=o.order_id
JOIN products p on p.product_id=oi.product_id
JOIN categories c on c.category_id=p.category_id
GROUP BY st.store_name,c.category_name
ORDER BY 1, 3 DESC)
SELECT store_name,most_popular_category,no_of_units_sold
FROM CTE WHERE rnk=1;

-- IV. CUSTOMER INSIGHTS
-- ***********************
/* Q10: Which are the top 5 customers based on sales? */

SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS full_name,
ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS sales
FROM  orders o JOIN customers c ON o.customer_id=c.customer_id
JOIN order_items oi ON oi.order_id=o.order_id
GROUP BY full_name,c.customer_id
ORDER BY sales DESC
LIMIT 5;

/* Q11: Find how much amount spent by each customer on best_selling bike category. Output top 5 rows. */

SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS full_name,
ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS sales
FROM  orders o JOIN customers c ON o.customer_id=c.customer_id
JOIN order_items oi ON oi.order_id=o.order_id
WHERE oi.product_id in (SELECT p.product_id FROM products p JOIN categories c on p.category_id=c.category_id WHERE c.category_id =3)
GROUP BY full_name,c.customer_id
ORDER BY sales DESC
LIMIT 5;

-- V. DELIVERY INSIGHTS
-- **********************
/* Q12: What is the total number of deliveries made on time, how many were delivered after
        the required date? What percentage of deliveries were punctual v/s delayed?   */
    
 WITH RECURSIVE deliveries AS
		(SELECT  *,
			CASE WHEN required_date >= shipped_date AND shipped_date IS NOT NULL
			THEN 'Punctual'
			WHEN required_date < shipped_date AND shipped_date IS NOT NULL
			THEN 'Delayed'
			END AS type
		FROM orders),
        perc AS 
        (SELECT 
			SUM(CASE WHEN order_status=4 then 1 else 0 END) AS Total_Completed_Deliveries,
            SUM(CASE WHEN type='Punctual' then 1 else 0 END) AS Punctual_Deliveries,
            SUM(CASE WHEN type='Delayed' then 1 else 0 END) AS Delayed_Deliveries
		FROM deliveries)
SELECT Total_Completed_Deliveries,
CONCAT(Punctual_Deliveries,' ( ',ROUND(100*(Punctual_Deliveries/Total_Completed_Deliveries)),'% )') AS Punctual_deliveries,
CONCAT(Delayed_Deliveries,' ( ',ROUND(100*(Delayed_Deliveries/Total_Completed_Deliveries)),'% )') AS Delayed_deliveries
FROM perc;

