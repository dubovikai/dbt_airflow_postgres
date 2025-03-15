{# 
  - name: test_transaction_taxes
    description: >
      This test checks for invalid transactions where the tax amount exceeds the total price. 
      Such cases may indicate data quality issues, incorrect tax calculations, or upstream data 
      ingestion errors. If any records are returned, further investigation is required.
#}

SELECT
    transaction_id,
    transaction_date,
    price,
    tax
FROM {{ ref('fct_transactions_silver') }}
WHERE tax > price
