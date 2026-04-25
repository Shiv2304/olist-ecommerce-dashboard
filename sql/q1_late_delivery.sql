SELECT
    oi.seller_id,
    COUNT(DISTINCT o.order_id)                                          AS total_orders,
    SUM(CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1 ELSE 0
    END)                                                                AS late_deliveries,
    ROUND(
        100.0 * SUM(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0
        END) / COUNT(DISTINCT o.order_id), 2
    )                                                                   AS late_rate_pct,
    ROUND(SUM(oi.price + oi.freight_value)::numeric, 2)                AS total_revenue,
    ROUND(
        SUM(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN oi.price + oi.freight_value ELSE 0
        END)::numeric, 2
    )                                                                   AS revenue_at_risk
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE
    o.order_status = 'delivered'
    AND o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT o.order_id) >= 10   -- filter out sellers with too few orders
ORDER BY late_rate_pct DESC, revenue_at_risk DESC
LIMIT 20;