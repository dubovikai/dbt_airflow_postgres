-- depends_on: {{ ref('dim_products_silver') }}
{{ config(
    materialized='table',
    post_hook=[
        "{{ check_constraints('fct_transactions_silver') }}"
    ]
) }}

SELECT
    transaction_id,
    customer_id,
    transaction_date,
    product_id,
    quantity,
    price,
    tax,
    NULL AS import_status
FROM {{ ref('raw_transactions_bronze') }}
