-- depends_on: {{ ref('dim_products_silver') }}
{{ config(materialized="table") }}

SELECT
    CAST(CAST(transaction_id AS NUMERIC(15,0)) AS INTEGER) AS transaction_id,
    CAST(CAST(customer_id AS NUMERIC(15,0)) AS INTEGER) AS customer_id,
    CAST(transaction_date AS DATE) AS transaction_date,
    CAST(product_id AS INTEGER) AS product_id,
    CAST(CAST(quantity AS NUMERIC(15,0)) AS INTEGER) AS quantity,
    CAST(price AS REAL) AS price,
    CAST(tax AS REAL) AS tax
FROM {{ ref('fct_transactions_bronze') }}
WHERE import_status = 'OK'
