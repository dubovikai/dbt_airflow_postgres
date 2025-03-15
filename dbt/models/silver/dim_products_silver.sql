{{ config(materialized="table") }}

SELECT DISTINCT
    CAST(product_id AS INTEGER) AS product_id,
    product_name
FROM {{ ref('dim_products_bronze') }}
WHERE import_status = 'OK'
