-- models/snapshot_public_asset_balances.sql

{{ config(materialized='incremental', unique_key='id') }}

WITH data AS (
    SELECT
        *,
        CURRENT_TIMESTAMP() AS snapshot_time
    FROM {{ source('Cartographer', 'public_asset_balances') }}
)

SELECT * FROM data

{% if is_incremental() %}

  -- This condition allows dbt to only insert new snapshots every 15 minutes
  -- Adjust the interval as needed for your specific requirements
  WHERE snapshot_time >= (SELECT MAX(snapshot_time) FROM {{ this }}) + INTERVAL 15 MINUTE

{% endif %}
