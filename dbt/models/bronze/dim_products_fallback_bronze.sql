SELECT
    import_status,
    product_id,
    product_name
FROM {{ ref('dim_products_bronze') }}
WHERE import_status != 'OK'
