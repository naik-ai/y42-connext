{{ config(materialized='incremental', unique_key='row_hash', incremental_strategy='append') }}   
SELECT *
FROM {{ ref('slippage_historical') }}

{% if is_incremental() %}

    -- this filter will only be applied on an incremental run
    WHERE row_hash NOT IN (SELECT (row_hash) FROM {{ this }})

{% endif %}
