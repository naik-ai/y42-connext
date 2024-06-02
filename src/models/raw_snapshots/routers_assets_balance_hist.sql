{{ config(materialized='incremental',     incremental_strategy='append') }}

WITH source_data AS (
    SELECT
        *,
        CURRENT_TIMESTAMP() AS snapshot_time  -- Captures the current UTC timestamp
    FROM {{ source('Cartographer', 'public_asset_balances') }}
)

SELECT *
FROM source_data
