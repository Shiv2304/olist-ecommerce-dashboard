WITH demand AS (
    SELECT
        c.customer_state                                        AS state,
        COUNT(DISTINCT o.order_id)                             AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2)   AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c    ON o.customer_id = c.customer_id
    WHERE o.order_status NOT IN ('canceled')
    GROUP BY c.customer_state
),
supply AS (
    SELECT
        seller_state                        AS state,
        COUNT(DISTINCT seller_id)           AS local_sellers
    FROM sellers
    GROUP BY seller_state
)
SELECT
    d.state,
    d.total_orders,
    d.total_revenue,
    COALESCE(s.local_sellers, 0)           AS local_sellers,
    ROUND(
        d.total_orders::numeric /
        NULLIF(COALESCE(s.local_sellers, 0), 0), 1
    )                                      AS orders_per_local_seller,
    CASE
        WHEN d.total_orders > 1000
         AND COALESCE(s.local_sellers, 0) < 50
        THEN 'High Gap'
        WHEN d.total_orders > 500
         AND COALESCE(s.local_sellers, 0) < 100
        THEN 'Medium Gap'
        ELSE 'Covered'
    END                                    AS gap_classification
FROM demand d
LEFT JOIN supply s ON d.state = s.state
ORDER BY orders_per_local_seller DESC NULLS LAST;