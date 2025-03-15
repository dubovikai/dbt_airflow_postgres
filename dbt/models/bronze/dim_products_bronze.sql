{{ config(
    materialized='table',
    post_hook=[
        "{{ check_constraints('dim_products_silver') }}"
    ]
) }}

SELECT DISTINCT
    product_id,
    product_name,
    NULL AS import_status
FROM {{ ref('raw_transactions_bronze') }}
