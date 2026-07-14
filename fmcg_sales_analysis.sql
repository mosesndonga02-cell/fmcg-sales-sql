/* ============================================================
   FMCG Daily Sales Analysis (2022-2024)
   Author:  Moses Ndonga
   Tool:    SQLite (DBeaver)
   Source:  Kaggle - FMCG Daily Sales Data (2022-2024)
   Purpose: Identify what drives revenue across category, brand,
            channel, region and promotions, to support range,
            pricing and availability decisions.
   ============================================================ */


-- 1. Data quality: flag impossible values before trusting the data
SELECT
    SUM(CASE WHEN units_sold < 0 THEN 1 ELSE 0 END)      AS negative_units,
    SUM(CASE WHEN stock_available < 0 THEN 1 ELSE 0 END) AS negative_stock,
    COUNT(*)                                             AS total_rows
FROM sales;


-- 2. Cleaned working view: drop invalid rows, derive revenue
DROP VIEW IF EXISTS clean_sales;
CREATE VIEW clean_sales AS
SELECT
    *,
    ROUND(price_unit * units_sold, 2) AS revenue
FROM sales
WHERE units_sold      >= 0
  AND stock_available >= 0
  AND price_unit       > 0;


-- 3. Headline KPIs
SELECT
    ROUND(SUM(revenue), 2)    AS total_revenue,
    SUM(units_sold)           AS total_units,
    COUNT(*)                  AS records,
    ROUND(AVG(price_unit), 2) AS avg_unit_price
FROM clean_sales;


-- 4. Revenue by year
SELECT
    strftime('%Y', date)   AS year,
    ROUND(SUM(revenue), 2) AS revenue,
    SUM(units_sold)        AS units
FROM clean_sales
GROUP BY year
ORDER BY year;


-- 5. Seasonality: revenue by calendar month
SELECT
    strftime('%m', date)   AS month,
    ROUND(SUM(revenue), 2) AS revenue
FROM clean_sales
GROUP BY month
ORDER BY revenue DESC;


-- 6. Revenue by product category
SELECT
    category,
    ROUND(SUM(revenue), 2) AS revenue,
    SUM(units_sold)        AS units
FROM clean_sales
GROUP BY category
ORDER BY revenue DESC;


-- 7. Top 5 brands by revenue
SELECT
    brand,
    ROUND(SUM(revenue), 2) AS revenue,
    SUM(units_sold)        AS units
FROM clean_sales
GROUP BY brand
ORDER BY revenue DESC
LIMIT 5;


-- 8. Channel mix (share of total revenue)
SELECT
    channel,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM clean_sales), 1) AS pct_of_revenue
FROM clean_sales
GROUP BY channel
ORDER BY revenue DESC;


-- 9. Revenue by region and channel
SELECT
    region,
    channel,
    ROUND(SUM(revenue), 2) AS revenue
FROM clean_sales
GROUP BY region, channel
ORDER BY region, revenue DESC;


-- 10. Promotion effectiveness (average per record, promo vs non-promo)
SELECT
    CASE promotion_flag WHEN 1 THEN 'On promotion' ELSE 'No promotion' END AS promo,
    COUNT(*)                  AS records,
    ROUND(AVG(units_sold), 2) AS avg_units,
    ROUND(AVG(revenue), 2)    AS avg_revenue
FROM clean_sales
GROUP BY promotion_flag;


-- 11. Demand by pack type
SELECT
    pack_type,
    SUM(units_sold)        AS units,
    ROUND(SUM(revenue), 2) AS revenue
FROM clean_sales
GROUP BY pack_type
ORDER BY units DESC;


-- 12. Availability risk: zero-stock records by category
SELECT
    category,
    SUM(CASE WHEN stock_available = 0 THEN 1 ELSE 0 END) AS zero_stock_records
FROM clean_sales
GROUP BY category
HAVING zero_stock_records > 0
ORDER BY zero_stock_records DESC;