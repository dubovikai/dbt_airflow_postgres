from datetime import datetime
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from cosmos import DbtTaskGroup
from config import DBTConfig
from on_failure_callbacks import failure_callbacks


# Define DAG with optimized parameters
with DAG(
    dag_id="full_update_dag",
    start_date=datetime(2024, 7, 4),  # Ensure backfill does not occur
    schedule_interval="@daily",
    max_active_runs=1,
    catchup=False,
    render_template_as_native_obj=True,
    default_args={"on_failure_callback": failure_callbacks},
) as full_update_dag:

    # Task: Create the raw transactions table
    create_raw_transactions_table = SQLExecuteQueryOperator(
        task_id="create_raw_transactions_table",
        conn_id='postgres_default',
        sql="""
            DROP TABLE IF EXISTS bronze.raw_transactions;
            CREATE TABLE bronze.raw_transactions (
                transaction_id VARCHAR,
                customer_id VARCHAR,
                transaction_date VARCHAR,
                product_id VARCHAR,
                product_name VARCHAR,
                quantity VARCHAR,
                price VARCHAR,
                tax VARCHAR,
                loaded_at TIMESTAMP DEFAULT timezone('utc', now())
            );
        """,
    )

    def _upload_transactions():
        """
        Uploads transactions from a CSV file into the raw transactions table.
        """
        hook = PostgresHook(postgres_conn_id='postgres_default')
        hook.copy_expert(
            sql="""
                COPY bronze.raw_transactions(
                    transaction_id,
                    customer_id,
                    transaction_date,
                    product_id,
                    product_name,
                    quantity,
                    price,
                    tax
                )
                FROM STDIN
                WITH (FORMAT csv, HEADER TRUE)
            """,
            filename='/opt/airflow/csvs/customer_transactions.csv'
        )

    # Task: Upload transactions from CSV to Postgres
    upload_transactions = PythonOperator(
        task_id='upload_transactions',
        python_callable=_upload_transactions
    )

    # Task: Run dbt models using Cosmos
    run_dbt_models = DbtTaskGroup(
        group_id="run_dbt_models",
        render_config=DBTConfig.render_config(),
        project_config=DBTConfig.project_config(),
        execution_config=DBTConfig.execution_config(),
        profile_config=DBTConfig.profile_config(),
        default_args={
            "retries": 1,
            "install_deps": True
        }
    )

    # Final task: Indicate DAG completion
    last_task = EmptyOperator(task_id="end")

    # Define task dependencies
    (
        create_raw_transactions_table >>
        upload_transactions >>
        run_dbt_models >>
        last_task
    )
