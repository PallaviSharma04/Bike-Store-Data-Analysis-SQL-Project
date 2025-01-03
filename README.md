# 🚲 Bike Store Data Analysis Using MYSQL
## Table of Contents
## Project Overview
This project performs a comprehensive analysis of a bike store's operations using MYSQL. The project aims to uncover insights and trends and provide recommendations for improving store performance and customer satisfaction. The project includes advanced SQL concepts, such as Window Functions, Common Table Expressions(CTEs),etc. to enhance the depth and efficiency of the queries.

## Goals
- To analyze sales trends over time and identify patterns.
- To understand customer preferences and behaviour.
- To evaluate product and category performance.
- To assess staff performance and store contributions to revenue.

## Tools and Technologies
- **Database**: MySQL
- **Query Platform**: MySQL Workbench
- **Data Source**: Public Dataset from <a href="https://www.kaggle.com/datasets/dillonmyrick/bike-store-sample-database?select=orders.csv">Kaggle</a>
           - <a href="https://github.com/PallaviSharma04/Bike-Store-Data-Analysis-SQL-Project/tree/main/Bike%20Store%20Data">Bike Store </a>
- **Data Range** : Jan 2016 to Dec 2018

## Data Schema
The database consists of the following interconnected tables:
- **Customers**: Stores customer details and location information.
- **Orders**: Tracks order details such as status,date, and related store/staff information.
- **Order Items**: Capture details of products sold in each order.
- **Products**: Contains information on product names,prices,brands and categories.
- **Categories**: Groups products into categories such as mountain bikes or road bikes.
- **Brands**: Captures the brand information of products.
- **Stocks**: Tracks inventory levels for each product across stores.
- **Stores**: Contains store location and contact details.
- **Staffs**: Stores staff details and their store association.

## Entity Relationship Diagram
![Database Schema](https://github.com/user-attachments/assets/f9c7bb92-3553-4c45-aa63-9772271c07b7)

## Data Analysis
### 1. Sales Trends
<details>
<summary>Click to view</summary>
<br>

**Q1: Which months record the highest number of orders, and which store is responsible for the largest share of these orders?**
```sql
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
```
*Output*

![image](https://github.com/user-attachments/assets/25d20ee0-7cef-4c3a-8eef-39a7bea461c1)

**Q2: What is the progression of revenue over time for each category and which categories show significant growth decline?**
```sql
	SELECT year(o.order_date) as year,c.category_name,ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS tot_rev
	FROM orders o JOIN order_items oi ON o.order_id=oi.order_id 
	JOIN products p ON oi.product_id=p.product_id
	JOIN categories c ON c.category_id=p.category_id
	GROUP BY c.category_name,year
	ORDER BY c.category_name DESC,year ASC; 
```
*Output*

![image](https://github.com/user-attachments/assets/8d294f5a-2587-4d8a-ab9b-04a98026f5ce)
</details>

### 2. Product & Category Analysis
<details>
<summary>Click to view</summary>
<br>
	
**Q3: Which bike categories generate the highest revenue?**
```sql
SELECT c.category_name,ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS tot_rev
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name 
ORDER BY tot_rev DESC;
```
*Output*

![image](https://github.com/user-attachments/assets/3343eebe-942c-43f7-b00b-f06dcde16a71)

**Q4: Which is the most expensive bike category on an average?**
```sql
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
```
*Output*

![image](https://github.com/user-attachments/assets/fbc7ddeb-0834-4509-be8a-fd978d17c835)

**Q5: Write a query to track the number of units sold over time for each brand, reflecting consumer demand trends.**
```sql
	SELECT YEAR(o.order_date) as year, b.brand_name, SUM(oi.quantity) as No_of_units_sold
	FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
	JOIN products p ON p.product_id=oi.product_id
	JOIN brands b ON b.brand_id=p.brand_id
	GROUP BY b.brand_name,year
	ORDER BY b.brand_name DESC,year ASC;
```
*Output*

![image](https://github.com/user-attachments/assets/bda562e4-e115-41cf-a963-27e04547ddfe)
</details>

### 3. Staff & Store Performance
<details>
<summary>Click to view</summary>
<br>

**Q6: Which store contributes the most to the sales?**
```sql
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
FROM rev_per_store JOIN sum_re
```
*Output*

![image](https://github.com/user-attachments/assets/6bb1431e-8711-4fe2-9034-6427d65e6064)

**Q7: Which store has the highest number of deliveries that were rejected?**
```sql
SELECT count(*) as Rejected_Deliveries , store_name 
FROM orders o JOIN stores s ON o.store_id=s.store_id
WHERE order_status=3
GROUP BY store_name
ORDER BY 1 DESC ;
```
*Output*

![image](https://github.com/user-attachments/assets/ab277a51-3c16-44f2-b73f-dc5fd8478258)

**Q8: Write a query that returns the store name and staff name who has generated the most revenue of top 3 best selling bike categories.**
```sql
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
```
*Output*

![image](https://github.com/user-attachments/assets/7f618b67-2cec-4e01-8d4e-cf012749b2a9)

**Q9: We want to find out the most popular bike category for each store. We detemine the most popular  bike category as the one with the highest amount of purchases. Write a query that returns each store along with the top category.**
```sql
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
```
*Output*

![image](https://github.com/user-attachments/assets/7025fbea-a9c2-4ae0-8435-2b49014e9b8c)
</details>

### 4. Customer Insights
<details>
<summary>Click to view</summary>
<br>

**Q10: Which are the top 5 customers based on sales?**
```sql
	SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS full_name,
	ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS sales
	FROM  orders o JOIN customers c ON o.customer_id=c.customer_id
	JOIN order_items oi ON oi.order_id=o.order_id
	GROUP BY full_name,c.customer_id
	ORDER BY sales DESC
	LIMIT 5;
```
*Output*

![image](https://github.com/user-attachments/assets/f9be5bed-3d8c-43a5-9396-91faf39302b6)

**Q11: Find how much amount spent by each customer on best_selling bike category. Output top 5 rows.**
```sql
	SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS full_name,
	ROUND(SUM((oi.quantity*oi.list_price)*(1-oi.discount)),2) AS sales
	FROM  orders o JOIN customers c ON o.customer_id=c.customer_id
	JOIN order_items oi ON oi.order_id=o.order_id
	WHERE oi.product_id in 
	(SELECT p.product_id FROM products p JOIN categories c on p.category_id=c.category_id 
	WHERE c.category_id =3)
	GROUP BY full_name,c.customer_id
	ORDER BY sales DESC
	LIMIT 5;
```
*Output*

![image](https://github.com/user-attachments/assets/15728786-eeb4-4d74-a926-92700da8f801)
</details>

### 5. Delivery Insights
<details>
<summary>Click to view</summary>
<br>

**Q12: What is the total number of deliveries made on time, how many were delivered after the required date? What percentage of deliveries were punctual v/s delayed?**
```sql
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
```
*Output*

![image](https://github.com/user-attachments/assets/635fe50d-ec40-4021-ad97-483a39d815f1)
</details>

## Business Insights
The following insights were derived from the analysis:
### Sales Trends:
- **April & March** recorded the highest number of orders.
- **Electric Bikes** sales are consistently rising, while **Comfort Bicycles** & **Children Bicycles** peaked in 2017 but declined in 2018. Sales for all other categories are declining.

### Product Category & Brand Insights:
- **Mountain Bikes** generated the highest revenue of **$2.72M** followed by **Road Bikes** and **Cruiser Bicycles**.
- **Electric Bikes** are the most expensive category followed by **Road Bikes** and **Cyclocross Bikes**.
- **Cruiser Bicycles,Mountain Bikes and Children Bicycles** are the three most sold categories.
- **Trek** brand sales increased in 2017, then declined in 2018. All other brands show a steady decline from 2016 to 2018.

### Store & Staff Contributions:
- **Baldwin Bikes** store contributes the most to total revenue(**68%**), followed by **Santa Cruz Bikes (21%)** and **Rowlett Bikes (11%)**.
- **Rowlett Bikes** has the highest number of **rejected deliveries**, followed by Baldwin Bikes and Santa Cruz Bikes. 
- **Cruiser Bicycle** is the best selling category for each store.

## Customer Insights:
- **Top 5 customers by sales** are Sharyn,Pamelia,Abby,Lyndsey and Emmitt.
- **Emmitt** spent the most on **Cruisers Bicycles**, the best selling category.

## Recommendations


