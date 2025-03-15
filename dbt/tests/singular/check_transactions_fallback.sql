SELECT
    import_status,
    transaction_id
FROM {{ ref('transactions_fallback_bronze') }}
