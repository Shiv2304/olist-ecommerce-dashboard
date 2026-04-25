SELECT
    ct.product_category_name_english           AS category,
    COUNT(DISTINCT o.order_id)                 AS total_orders,
    ROUND(AVG(r.review_score), 2)              AS avg_review_score,
    ROUND(
        100.0 * SUM(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END) / COUNT(DISTINCT o.order_id), 2
    )                                          AS late_rate_pct,
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (
                o.order_delivered_customer_date - o.order_estimated_delivery_date
            )) / 86400
        ), 1
    )                                          AS avg_days_late,
   CASE
        WHEN AVG(r.review_score) < 4
         AND 100.0 * SUM(CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1 ELSE 0
             END) / COUNT(DISTINCT o.order_id) > 15
        THEN 'Logistics Problem'
        WHEN AVG(r.review_score) < 4
         AND 100.0 * SUM(CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1 ELSE 0
             END) / COUNT(DISTINCT o.order_id) <= 15
        THEN 'Product Problem'
        ELSE 'Acceptable'
    END                                        AS problem_type
FROM orders o
JOIN order_items oi      ON o.order_id = oi.order_id
JOIN order_reviews r     ON o.order_id = r.order_id
JOIN products p          ON oi.product_id = p.product_id
JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY ct.product_category_name_english
HAVING COUNT(DISTINCT o.order_id) >= 50
ORDER BY avg_review_score ASC
LIMIT 20;