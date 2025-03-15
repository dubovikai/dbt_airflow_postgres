WITH csv_null_handle_cte AS (
    SELECT
        NULLIF(transaction_id, '') AS transaction_id,
        NULLIF(customer_id, '') AS customer_id,
        NULLIF(transaction_date, '') AS transaction_date,
        NULLIF(product_id, '') AS product_id,
        NULLIF(product_name, '') AS product_name,
        NULLIF(quantity, '') AS quantity,
        NULLIF(price, '') AS price,
        NULLIF(tax, '') AS tax
    FROM {{ source('bronze_layer', 'transactions_raw_bronze') }}
)

SELECT
    REGEXP_REPLACE(transaction_id,'[[:alpha:]]','','g') AS transaction_id,

    customer_id,

    REGEXP_REPLACE(transaction_date,'^(\d{1,2})-(\d{1,2})-(\d{4})$', '\3-\2-\1') AS transaction_date,

    CASE WHEN product_name = 'Product E'
      THEN REPLACE(product_id, 'P', '')
      ELSE product_id
    END AS product_id,

    product_name,

    quantity, 

    REPLACE(price, 'Two Hundred', '200') AS price,

    REPLACE(tax, 'Fifteen', '15') AS tax

FROM csv_null_handle_cte
