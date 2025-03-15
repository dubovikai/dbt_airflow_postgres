{#
  - name: test_fallback
    description: |
      This DBT test checks whether the given model contains any records.
    arguments:
      - name: model
        type: dbt model reference
        description: The DBT model to be tested.
 #}

{% test test_fallback(model) %}
    SELECT * FROM {{ model }}
{% endtest %}
