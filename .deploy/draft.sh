#!/bin/bash

rm -r dbt/target
rm dbt/models/metabase/exposures.yml

dbt parse

dbt-metabase models \
    --manifest-path ./dbt/target/manifest.json \
    --metabase-url http://localhost:3000 \
    --metabase-api-key mb_yQ8OcJZbt4cdOVZGBSNdv8v3jSZBqepAiFBksOU5xTg= \
    --metabase-database "Test PostreSQL DWH" \
    --include-schemas bronze,silver,gold

dbt-metabase exposures \
    --manifest-path ./dbt/target/manifest.json \
    --metabase-url http://localhost:3000 \
    --metabase-api-key mb_yQ8OcJZbt4cdOVZGBSNdv8v3jSZBqepAiFBksOU5xTg= \
    --output-path ./dbt/models/metabase \
    --exclude-collections "temp*"

dbt parse