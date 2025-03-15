{% macro check_constraints(destination_model_name) %}
    {#
    Checks constraints on the specified destination model and updates import status.

    This macro performs the following operations:
    1. Finds the metadata for the specified destination model in the graph.
    2. Adds an `import_status` column to the target table if it does not exist.
    3. Creates a temporary table with constraints defined in the destination model.
    4. Iterates over each record in the target table and attempts to insert it into the temporary table.
    5. Updates `import_status` to 'OK' for successful inserts and logs errors for failed ones.

    Args:
        destination_model_name (str): The name of the destination model whose constraints will be checked.

    Returns:
        None
    #}
    {% if not execute %}
        {% do return(True) %}
    {% endif %}

    {% set found_node = graph.nodes.values() | selectattr('name', 'equalto', destination_model_name) | list | first %}
    {% if not found_node %}
        {% do exceptions.raise_compiler_error("Model " ~ destination_model_name ~ " not found in the graph.") %}
    {% endif %}

    DO $$
    DECLARE
        rec RECORD;
        err_code VARCHAR;
        msg_text VARCHAR;
    BEGIN
        ALTER TABLE {{ this }} ADD COLUMN IF NOT EXISTS import_status TEXT;
        UPDATE {{ this }} SET import_status = NULL;

        {% set temp_table_name = this.identifier ~ '__tmp' %}
        CREATE TABLE {{ temp_table_name }} (
            {%- set raw_column_constraints = adapter.render_raw_columns_constraints(raw_columns=found_node['columns']) -%}
            {%- set raw_model_constraints = adapter.render_raw_model_constraints(raw_constraints=found_node['constraints']) -%}

            {{ raw_column_constraints | join(', ') }}
            {%- if raw_model_constraints -%}
                , {{ raw_model_constraints | join(', ') }}
            {%- endif -%}
        );

        FOR rec IN (
            SELECT ctid, {{ found_node['columns'].keys() | join(', ') }} FROM {{ this }}
        )
        LOOP
            BEGIN
                INSERT INTO {{ temp_table_name }} ({{ found_node['columns'].keys() | join(', ') }})
                VALUES (
                    {%- for key, value in found_node['columns'].items() -%}
                        CAST(rec.{{ key }} AS {{ 'NUMERIC(15, 0)' if value['data_type'] == 'INTEGER' else value['data_type'] }})
                        {%- if not loop.last -%}, {%- endif -%}
                    {%- endfor -%}
                );
                UPDATE {{ this }} SET import_status = 'OK' WHERE ctid = rec.ctid;
            EXCEPTION WHEN OTHERS THEN
                GET STACKED DIAGNOSTICS err_code = RETURNED_SQLSTATE, msg_text = MESSAGE_TEXT;
                UPDATE {{ this }} SET import_status = 'ERR: ' || err_code || ': ' || msg_text WHERE ctid = rec.ctid;
            END;
        END LOOP;
    DROP TABLE {{ temp_table_name }};
    END;
    $$;
{% endmacro %}
