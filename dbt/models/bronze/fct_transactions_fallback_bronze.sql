SELECT
    import_status,
    transaction_id,
    customer_id,
    transaction_date,
    product_id,
    quantity,
    price,
    tax
FROM {{ ref('fct_transactions_bronze') }}
WHERE import_status != 'OK'
