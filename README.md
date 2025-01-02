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
**Q1: Which store contributes the most to the sales?** 
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

**Q2: Which store has the highest number of deliveries that were rejected?**
```sql
SELECT count(*) as Rejected_Deliveries , store_name 
FROM orders o JOIN stores s ON o.store_id=s.store_id
WHERE order_status=3
GROUP BY store_name
ORDER BY 1 DESC ;
```
*Output*


## Business Insights

## Recommendations


