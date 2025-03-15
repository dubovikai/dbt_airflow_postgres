# Data Pipeline with Airflow, dbt, and PostgreSQL

## Overview
The goal of this project was to develop a data pipeline using Airflow, dbt, and PostgreSQL.

Successfully integrated Airflow v2.10.2 and DBT-Core v2.9.2 using Astronomer Cosmos.

## Running the Project
To start the project locally, execute the following command in the root directory:

```sh
docker compose up
```

DBT model development can be conducted using the console.

The resulting DAG lineage is illustrated below:

![Here should be an image](https://github.com/dubovikai/dbt_airflow_postgres/blob/master/dag.png?raw=true)

## DAG Structure
The DAG consists of four high-level tasks:

### 1. `create_raw_transactions_table`
- Utilizes `SQLExecuteQueryOperator` to recreate the table for loading raw data from a CSV file.
- A simulated external storage is used for file storage in the directory: `external_file_storage`.

### 2. `upload_transactions`
- Uses `PythonOperator` and `PostgresHook` to load data into the table created in the first task without any transformations.
- **Note:** DBT Seeds were not used for data loading as it is not recommended by dbt developers. More details can be found [here](https://docs.getdbt.com/docs/build/seeds#faqs).

### 3. `run_dbt_models`
- Uses `DbtTaskGroup` ([documentation](https://astronomer.github.io/astronomer-cosmos/index.html)).
- The model organization follows the **Medallion pattern** with bronze, silver, and gold levels:
  - **Bronze Level:**
    - Data cleansing and transformation.
    - Records are marked to determine whether they can be promoted to the silver level based on DBT constraints.
    - Constraints validation is implemented using a post-hook: `dbt/macros/check_constraints.sql`.
    - Failed records are directed to fallback models (views), and a simple data test ensures at least one such record exists.
    - In the current implementation, 28 records from the test dataset fail due to empty `customer_id` or `quantity` fields.
    - One business approach to handling this issue is ignoring such records, which was the chosen solution in this implementation.
  - **Silver Level:**
    - Stores refined data marts with strict typing and contracts.
  - **Gold Level:**
    - Intended for final business reports (not implemented in this project).
- **No dbt contracts** are used at the bronze level.
- Ensures a structured model update sequence: dimensions first, followed by facts.

### 4. `last_task`
- Uses `EmptyOperator` as the final DAG step.

## Out of Scope
The following aspects were not considered within the scope of this task:
- Data access control and permissions.
- Dedicated storage for sensitive information (e.g., GDPR, financial data).
- Secret management (e.g., storing credentials in a secure backend).
- Fine-tuning Airflow and PostgreSQL (used with default configurations).
- Deployment process in a production environment. The manifest file is currently under Git, but it is preferable to parse the project during deployment.

