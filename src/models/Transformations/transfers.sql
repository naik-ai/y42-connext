SELECT
    *,
    
    FORMAT_TIMESTAMP('%Y-%m-%d', TIMESTAMP_SECONDS(xcall_timestamp)) AS xcall_date
FROM {{ ref('transfers_with_price_ttr_ttv_y42_dedup') }}
