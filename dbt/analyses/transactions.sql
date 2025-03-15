SELECT
    product_id,
    product_name,
    SUM(price - tax) AS total_revenue
FROM {{ ref('transactions_silver') }}
GROUP BY 1, 2
ORDER BY 1
