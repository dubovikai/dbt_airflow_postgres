{{ config(materialized="table") }}

SELECT
    import_status,
    transaction_id,
    customer_id,
    transaction_date,
    product_id,
    product_name,
    quantity,
    price,
    tax
FROM {{ ref('transactions_bronze') }}
WHERE import_status != 'OK'
