{{ config(materialized='incremental') }}

WITH source_data AS (
    SELECT
        pool_id,
        other_columns,
        CURRENT_TIMESTAMP() AS snapshot_time  -- Captures the current UTC timestamp
    FROM {{ source('Cartographer', 'public_asset_balances') }}
)

SELECT
    *,
    snapshot_time,
    pool_id
FROM source_data
{% if is_incremental() %}
{% endif %}
