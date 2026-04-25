SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)     AS order_month,
    ct.product_category_name_english                    AS category,
    COUNT(DISTINCT o.order_id)                          AS total_orders,
    SUM(CASE WHEN o.order_status = 'canceled'
        THEN 1 ELSE 0 END)                              AS canceled_orders,
    ROUND(
        100.0 * SUM(CASE WHEN o.order_status = 'canceled'
            THEN 1 ELSE 0 END) /
        NULLIF(COUNT(DISTINCT o.order_id), 0), 2
    )                                                   AS cancellation_rate_pct,
    ROUND(
        SUM(CASE WHEN o.order_status = 'canceled'
            THEN oi.price + oi.freight_value ELSE 0
        END)::numeric, 2
    )                                                   AS revenue_lost
FROM orders o
JOIN order_items oi      ON o.order_id = oi.order_id
JOIN products p          ON oi.product_id = p.product_id
JOIN category_translation ct ON p.product_category_name = ct.product_category_name
WHERE
    o.order_purchase_timestamp >= '2017-01-01'
    AND o.order_purchase_timestamp < '2019-01-01'
GROUP BY
    DATE_TRUNC('month', o.order_purchase_timestamp),
    ct.product_category_name_english
HAVING COUNT(DISTINCT o.order_id) >= 10
ORDER BY
    order_month DESC,
    cancellation_rate_pct DESC;