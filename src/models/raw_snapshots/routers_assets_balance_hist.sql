{{ config(materialized='incremental') }}

WITH source_data AS (
    SELECT
        *,
        CURRENT_TIMESTAMP() AS snapshot_time  -- Captures the current UTC timestamp
    FROM {{ source('Cartographer', 'public_asset_balances') }}
)

SELECT
    *
FROM source_data
{% if is_incremental() %}
{% endif %}
