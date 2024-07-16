SELECT
    *,
    FORMAT_TIMESTAMP('%Y-%m-%d', TIMESTAMP_SECONDS(xcall_timestamp)) AS xcall_date
FROM {{ ref('transfers_mapped') }}
