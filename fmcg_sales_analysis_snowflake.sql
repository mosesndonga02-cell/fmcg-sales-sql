/* ================================================================
   FMCG DAILY SALES ANALYSIS (2022-2024)
   ----------------------------------------------------------------
   Author   : Moses Ndonga
   Platform : Snowflake (Snowsight)
   Source   : Kaggle - FMCG Daily Sales Data (2022-2024), ~190k rows
   Purpose  : Identify what drives revenue across category, brand,
              channel, region and promotions to support range,
              pricing and availability decisions.
   ================================================================ */


/* ---------------------------------------------------------------
   0. SESSION CONTEXT
   Point the worksheet at the right compute, database and schema.
   --------------------------------------------------------------- */
USE WAREHOUSE COMPUTE_WH;
USE DATABASE  FMCG_DB;
USE SCHEMA    PUBLIC;


/* ---------------------------------------------------------------
   1. DATA QUALITY CHECK
   Flag impossible values (negative units or stock) before
   trusting the data for analysis.
   --------------------------------------------------------------- */
SELECT
    SUM(CASE WHEN units_sold      < 0 THEN 1 ELSE 0 END) AS negative_units,
    SUM(CASE WHEN stock_available < 0 THEN 1 ELSE 0 END) AS negative_stock,
    COUNT(*)                                             AS total_rows
FROM sales;


/* ---------------------------------------------------------------
   2. CLEANED ANALYSIS VIEW
   Remove invalid rows and derive a revenue column once, so every
   query below runs on the same trustworthy basis.
   --------------------------------------------------------------- */
CREATE OR REPLACE VIEW clean_sales AS
SELECT
    *,
    ROUND(price_unit * units_sold, 2) AS revenue
FROM sales
WHERE units_sold      >= 0
  AND stock_available >= 0
  AND price_unit       > 0;


/* ---------------------------------------------------------------
   3. HEADLINE KPIs
   Total revenue, units, clean record count and average unit price.
   --------------------------------------------------------------- */
SELECT
    ROUND(SUM(revenue), 2)    AS total_revenue,
    SUM(units_sold)           AS total_units,
    COUNT(*)                  AS records,
    ROUND(AVG(price_unit), 2) AS avg_unit_price
FROM clean_sales;


/* ---------------------------------------------------------------
   4. REVENUE BY YEAR
   Is the business growing?
   --------------------------------------------------------------- */
SELECT
    YEAR(date)             AS year,
    ROUND(SUM(revenue), 2) AS revenue,
    SUM(units_sold)        AS units
FROM clean_sales
GROUP BY YEAR(date)
ORDER BY year;


/* ---------------------------------------------------------------
   5. SEASONALITY BY MONTH
   Which months sell hardest?
   --------------------------------------------------------------- */
SELECT
    MONTH(date)            AS month,
    ROUND(SUM(revenue), 2) AS revenue
FROM clean_sales
GROUP BY MONTH(date)
ORDER BY revenue DESC;


/* ---------------------------------------------------------------
   6. REVENUE BY PRODUCT CATEGORY
   Which categories carry the business?
   --------------------------------------------------------------- */
SELECT
    category,
    ROUND(SUM(revenue), 2) AS revenue,
    SUM(units_sold)        AS units
FROM clean_sales
GROUP BY category
ORDER BY revenue DESC;


/* ---------------------------------------------------------------
   7. TOP 5 BRANDS BY REVENUE
   --------------------------------------------------------------- */
SELECT
    brand,
    ROUND(SUM(revenue), 2) AS revenue,
    SUM(units_sold)        AS units
FROM clean_sales
GROUP BY brand
ORDER BY revenue DESC
LIMIT 5;


/* ---------------------------------------------------------------
   8. CHANNEL MIX
   Share of total revenue by sales channel.
   --------------------------------------------------------------- */
SELECT
    channel,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(100.0 * SUM(revenue) / (SELECT SUM(revenue) FROM clean_sales), 1) AS pct_of_revenue
FROM clean_sales
GROUP BY channel
ORDER BY revenue DESC;


/* ---------------------------------------------------------------
   9. REVENUE BY REGION AND CHANNEL
   Where and how customers buy.
   --------------------------------------------------------------- */
SELECT
    region,
    channel,
    ROUND(SUM(revenue), 2) AS revenue
FROM clean_sales
GROUP BY region, channel
ORDER BY region, revenue DESC;


/* ---------------------------------------------------------------
   10. PROMOTION EFFECTIVENESS
   Average units and revenue per record, promo vs non-promo.
   --------------------------------------------------------------- */
SELECT
    CASE promotion_flag WHEN 1 THEN 'On promotion' ELSE 'No promotion' END AS promo,
    COUNT(*)                  AS records,
    ROUND(AVG(units_sold), 2) AS avg_units,
    ROUND(AVG(revenue), 2)    AS avg_revenue
FROM clean_sales
GROUP BY promotion_flag;


/* ---------------------------------------------------------------
   11. DEMAND BY PACK TYPE
   --------------------------------------------------------------- */
SELECT
    pack_type,
    SUM(units_sold)        AS units,
    ROUND(SUM(revenue), 2) AS revenue
FROM clean_sales
GROUP BY pack_type
ORDER BY units DESC;


/* ---------------------------------------------------------------
   12. AVAILABILITY RISK
   Zero-stock records by category: where empty shelves cost sales.
   --------------------------------------------------------------- */
SELECT
    category,
    SUM(CASE WHEN stock_available = 0 THEN 1 ELSE 0 END) AS zero_stock_records
FROM clean_sales
GROUP BY category
HAVING SUM(CASE WHEN stock_available = 0 THEN 1 ELSE 0 END) > 0
ORDER BY zero_stock_records DESC;
