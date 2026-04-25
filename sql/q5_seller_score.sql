WITH seller_stats AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT o.order_id)                          AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value)::numeric, 2) AS total_revenue,

        -- Late delivery rate
        ROUND(100.0 * SUM(CASE
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 1 ELSE 0 END) /
            NULLIF(COUNT(DISTINCT o.order_id), 0), 2)       AS late_rate_pct,

        -- Avg review score
        ROUND(AVG(r.review_score), 2)                       AS avg_review_score,

        -- Cancellation rate
        ROUND(100.0 * SUM(CASE
            WHEN o.order_status = 'canceled'
            THEN 1 ELSE 0 END) /
            NULLIF(COUNT(DISTINCT o.order_id), 0), 2)       AS cancellation_rate_pct

    FROM orders o
    JOIN order_items oi  ON o.order_id = oi.order_id
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.order_purchase_timestamp >= '2017-01-01'
    GROUP BY oi.seller_id
    HAVING COUNT(DISTINCT o.order_id) >= 10
),
scored AS (
    SELECT
        *,
        -- Normalize each metric 0-100 (higher = worse performance)
        ROUND(late_rate_pct, 2)                             AS late_score,
        ROUND((5 - avg_review_score) * 25, 2)              AS review_score_inv,
        ROUND(cancellation_rate_pct, 2)                     AS cancel_score,

        -- Weighted composite (late 40%, review 40%, cancel 20%)
        ROUND(
            (late_rate_pct * 0.40) +
            ((5 - avg_review_score) * 25 * 0.40) +
            (cancellation_rate_pct * 0.20), 2
        )                                                   AS composite_risk_score
    FROM seller_stats
)
SELECT
    seller_id,
    total_orders,
    total_revenue,
    late_rate_pct,
    avg_review_score,
    cancellation_rate_pct,
    composite_risk_score,
    CASE
        WHEN composite_risk_score >= 40 THEN 'Flag - Immediate Review'
        WHEN composite_risk_score >= 25 THEN 'Watch - Monitor Closely'
        ELSE 'Good Standing'
    END                                                     AS seller_status
FROM scored
ORDER BY composite_risk_score DESC
LIMIT 30;