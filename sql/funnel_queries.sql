-- data cleaning and prep
CREATE TABLE events_cleaned AS
SELECT DISTINCT event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session
FROM events
WHERE price > 0
    AND price < 50000
    AND user_id IS NOT NULL
    AND product_id IS NOT NULL;
-- Add time-based features
ALTER TABLE events_cleaned
ADD COLUMN event_date DATE,
    ADD COLUMN event_hour INT,
    ADD COLUMN day_of_week INT;
UPDATE events_cleaned
SET event_date = DATE(event_time),
    event_hour = EXTRACT(
        HOUR
        FROM event_time
    ),
    day_of_week = EXTRACT(
        DOW
        FROM event_time
    );
-- 2. user level funnel analysis
-- Create user funnel summary table
CREATE TABLE user_funnel AS
SELECT user_id,
    MIN(event_time) AS first_event,
    MAX(event_time) AS last_event,
    COUNT(*) AS total_events,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT category_code) AS unique_categories,
    AVG(price) AS avg_price,
    MAX(price) AS max_price,
    MIN(price) AS min_price,
    -- Funnel stage flags
    MAX(
        CASE
            WHEN event_type = 'view' THEN 1
            ELSE 0
        END
    ) AS viewed,
    MAX(
        CASE
            WHEN event_type = 'cart' THEN 1
            ELSE 0
        END
    ) AS added_to_cart,
    MAX(
        CASE
            WHEN event_type = 'purchase' THEN 1
            ELSE 0
        END
    ) AS purchased
FROM events_cleaned
GROUP BY user_id;
-- 3. Funnel Metrics calculation
-- Overall funnel conversion rates
SELECT COUNT(*) AS total_users,
    SUM(viewed) AS users_viewed,
    SUM(added_to_cart) AS users_added_cart,
    SUM(purchased) AS users_purchased,
    -- Conversion rates
    ROUND(SUM(viewed)::NUMERIC / COUNT(*) * 100, 2) AS view_rate,
    ROUND(
        SUM(added_to_cart)::NUMERIC / NULLIF(SUM(viewed), 0) * 100,
        2
    ) AS view_to_cart_rate,
    ROUND(
        SUM(purchased)::NUMERIC / NULLIF(SUM(added_to_cart), 0) * 100,
        2
    ) AS cart_to_purchase_rate,
    ROUND(SUM(purchased)::NUMERIC / COUNT(*) * 100, 2) AS overall_conversion_rate
FROM user_funnel;
-- Drop-off analysis
SELECT 'View to Cart' AS funnel_stage,
    SUM(viewed) - SUM(added_to_cart) AS users_dropped,
    ROUND(
        (SUM(viewed) - SUM(added_to_cart))::NUMERIC / NULLIF(SUM(viewed), 0) * 100,
        2
    ) AS dropoff_rate
FROM user_funnel
UNION ALL
SELECT 'Cart to Purchase' AS funnel_stage,
    SUM(added_to_cart) - SUM(purchased) AS users_dropped,
    ROUND(
        (SUM(added_to_cart) - SUM(purchased))::NUMERIC / NULLIF(SUM(added_to_cart), 0) * 100,
        2
    ) AS dropoff_rate
FROM user_funnel;
-- 4. Cohort analysis
-- User cohorts by first interaction hour
CREATE TABLE user_cohorts AS
SELECT user_id,
    EXTRACT(
        HOUR
        FROM MIN(event_time)
    ) AS cohort_hour,
    DATE(MIN(event_time)) AS cohort_date
FROM events_cleaned
GROUP BY user_id;
-- Cohort performance metrics
SELECT c.cohort_hour,
    COUNT(DISTINCT uf.user_id) AS total_users,
    SUM(uf.added_to_cart) AS cart_users,
    SUM(uf.purchased) AS purchase_users,
    ROUND(
        SUM(uf.added_to_cart)::NUMERIC / COUNT(DISTINCT uf.user_id) * 100,
        2
    ) AS cart_rate,
    ROUND(
        SUM(uf.purchased)::NUMERIC / COUNT(DISTINCT uf.user_id) * 100,
        2
    ) AS purchase_rate
FROM user_cohorts c
    JOIN user_funnel uf ON c.user_id = uf.user_id
GROUP BY c.cohort_hour
ORDER BY c.cohort_hour;
-- 5. Catagory performance analysis
-- Top performing categories by conversion rate
SELECT COALESCE(category_code, 'unknown') AS category,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) AS total_events,
    SUM(
        CASE
            WHEN event_type = 'view' THEN 1
            ELSE 0
        END
    ) AS views,
    SUM(
        CASE
            WHEN event_type = 'cart' THEN 1
            ELSE 0
        END
    ) AS carts,
    SUM(
        CASE
            WHEN event_type = 'purchase' THEN 1
            ELSE 0
        END
    ) AS purchases,
    ROUND(
        SUM(
            CASE
                WHEN event_type = 'purchase' THEN 1
                ELSE 0
            END
        )::NUMERIC / COUNT(DISTINCT user_id) * 100,
        2
    ) AS purchase_rate
FROM events_cleaned
GROUP BY category_code
HAVING COUNT(DISTINCT user_id) >= 100 -- Filter categories with sufficient data
ORDER BY purchase_rate DESC
LIMIT 10;
-- 6. User segmentation
-- Segment users based on behavior
SELECT user_id,
    CASE
        WHEN purchased = 1 THEN 'Buyer'
        WHEN added_to_cart = 1
        AND purchased = 0 THEN 'Cart Abandoner'
        WHEN viewed = 1
        AND added_to_cart = 0 THEN 'Browser'
        ELSE 'Other'
    END AS user_segment,
    total_events,
    unique_products,
    avg_price
FROM user_funnel;
-- Segment summary statistics
SELECT CASE
        WHEN purchased = 1 THEN 'Buyer'
        WHEN added_to_cart = 1
        AND purchased = 0 THEN 'Cart Abandoner'
        WHEN viewed = 1
        AND added_to_cart = 0 THEN 'Browser'
        ELSE 'Other'
    END AS user_segment,
    COUNT(*) AS user_count,
    ROUND(
        COUNT(*)::NUMERIC / (
            SELECT COUNT(*)
            FROM user_funnel
        ) * 100,
        2
    ) AS percentage,
    ROUND(AVG(total_events), 1) AS avg_events,
    ROUND(AVG(avg_price), 2) AS avg_price_viewed
FROM user_funnel
GROUP BY user_segment
ORDER BY user_count DESC;
-- 7. time to convert analysis
-- calculate time from first view to purchase
WITH purchase_times AS (
    SELECT e.user_id,
        MIN(
            CASE
                WHEN e.event_type = 'view' THEN e.event_time
            END
        ) AS first_view,
        MIN(
            CASE
                WHEN e.event_type = 'purchase' THEN e.event_time
            END
        ) AS first_purchase
    FROM events_cleaned e
    GROUP BY e.user_id
    HAVING MIN(
            CASE
                WHEN e.event_type = 'purchase' THEN e.event_time
            END
        ) IS NOT NULL
)
SELECT AVG(
        EXTRACT(
            EPOCH
            FROM (first_purchase - first_view)
        ) / 3600
    ) AS avg_hours_to_convert,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY EXTRACT(
                EPOCH
                FROM (first_purchase - first_view)
            ) / 3600
    ) AS median_hours_to_convert,
    MIN(
        EXTRACT(
            EPOCH
            FROM (first_purchase - first_view)
        ) / 3600
    ) AS min_hours,
    MAX(
        EXTRACT(
            EPOCH
            FROM (first_purchase - first_view)
        ) / 3600
    ) AS max_hours
FROM purchase_times;
-- 8. Cart Abandmont
-- Identify cart abandoners with high potential
SELECT uf.user_id,
    uf.total_events,
    uf.unique_products,
    uf.avg_price,
    c.cohort_hour,
    -- Calculate engagement score
    (
        uf.total_events * 0.3 + uf.unique_products * 0.4 + uf.unique_categories * 0.3
    ) AS engagement_score
FROM user_funnel uf
    JOIN user_cohorts c ON uf.user_id = c.user_id
WHERE uf.added_to_cart = 1
    AND uf.purchased = 0
    AND uf.total_events >= 5 -- Active users
ORDER BY engagement_score DESC
LIMIT 1000;
-- 9. Revenue analysis
-- Revenue by category
SELECT COALESCE(category_code, 'unknown') AS category,
    COUNT(DISTINCT user_id) AS buyers,
    SUM(price) AS total_revenue,
    AVG(price) AS avg_order_value,
    SUM(price) / COUNT(DISTINCT user_id) AS revenue_per_buyer
FROM events_cleaned
WHERE event_type = 'purchase'
GROUP BY category_code
ORDER BY total_revenue DESC;
-- Revenue potential from cart abandoners
SELECT COUNT(DISTINCT e.user_id) AS cart_abandoners,
    SUM(e.price) AS potential_revenue,
    AVG(e.price) AS avg_cart_value
FROM events_cleaned e
    JOIN user_funnel uf ON e.user_id = uf.user_id
WHERE e.event_type = 'cart'
    AND uf.purchased = 0;
-- 10. Daily/hourly patterns
-- Traffic and conversion by hour of day
SELECT event_hour,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS unique_users,
    SUM(
        CASE
            WHEN event_type = 'view' THEN 1
            ELSE 0
        END
    ) AS views,
    SUM(
        CASE
            WHEN event_type = 'cart' THEN 1
            ELSE 0
        END
    ) AS carts,
    SUM(
        CASE
            WHEN event_type = 'purchase' THEN 1
            ELSE 0
        END
    ) AS purchases,
    ROUND(
        SUM(
            CASE
                WHEN event_type = 'purchase' THEN 1
                ELSE 0
            END
        )::NUMERIC / COUNT(DISTINCT user_id) * 100,
        2
    ) AS conversion_rate
FROM events_cleaned
GROUP BY event_hour
ORDER BY event_hour;
-- 11. A/B Test setup
-- Randomly assign users to test groups (50/50 split)
CREATE TABLE ab_test_assignments AS
SELECT user_id,
    CASE
        WHEN RANDOM() < 0.5 THEN 'Control'
        ELSE 'Treatment'
    END AS test_group
FROM (
        SELECT DISTINCT user_id
        FROM events_cleaned
    ) u;
-- Monitor A/B test results Queries
SELECT ab.test_group,
    COUNT(DISTINCT uf.user_id) AS total_users,
    SUM(uf.added_to_cart) AS cart_users,
    SUM(uf.purchased) AS purchase_users,
    ROUND(
        SUM(uf.purchased)::NUMERIC / SUM(uf.added_to_cart) * 100,
        2
    ) AS cart_conversion_rate
FROM ab_test_assignments ab
    JOIN user_funnel uf ON ab.user_id = uf.user_id
WHERE uf.added_to_cart = 1
GROUP BY ab.test_group;
-- 12. Dashboard Queries for Tableau
-- KPI Summary for dashboard
SELECT (
        SELECT COUNT(DISTINCT user_id)
        FROM events_cleaned
    ) AS total_users,
    (
        SELECT COUNT(*)
        FROM events_cleaned
    ) AS total_events,
    (
        SELECT SUM(purchased)
        FROM user_funnel
    ) AS total_purchases,
    (
        SELECT ROUND(SUM(price), 2)
        FROM events_cleaned
        WHERE event_type = 'purchase'
    ) AS total_revenue,
    (
        SELECT ROUND(AVG(price), 2)
        FROM events_cleaned
        WHERE event_type = 'purchase'
    ) AS avg_order_value,
    (
        SELECT ROUND(SUM(purchased)::NUMERIC / COUNT(*) * 100, 2)
        FROM user_funnel
    ) AS overall_conversion_rate;
-- Funnel data for visualization
SELECT 'Step 1: Viewed Product' AS stage,
    SUM(viewed) AS users,
    1 AS stage_order
FROM user_funnel
UNION ALL
SELECT 'Step 2: Added to Cart' AS stage,
    SUM(added_to_cart) AS users,
    2 AS stage_order
FROM user_funnel
UNION ALL
SELECT 'Step 3: Completed Purchase' AS stage,
    SUM(purchased) AS users,
    3 AS stage_order
FROM user_funnel
ORDER BY stage_order;
