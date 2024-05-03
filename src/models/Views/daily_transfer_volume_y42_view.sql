SELECT
    tf.status,
    tf.origin_domain AS origin_chain,
    tf.destination_domain AS destination_chain,
    tf.origin_transacting_asset AS asset,
    DATE_TRUNC(CAST(TIMESTAMP_SECONDS(tf.xcall_timestamp) AS DATE), DAY) AS transfer_date,
    REGEXP_REPLACE(tf.routers, r'[\{\}]', '') AS router,
    SUM(CAST(tf.origin_transacting_amount AS NUMERIC)) AS volume,
    AVG(tf.asset_usd_price) AS avg_price,
    SUM(tf.usd_amount) AS usd_volume,
    ROW_NUMBER() OVER () AS id
FROM {{ ref('transfers_mapped') }} AS tf
GROUP BY
    tf.status,
    DATE_TRUNC(CAST(TIMESTAMP_SECONDS(tf.xcall_timestamp) AS DATE), DAY),
    tf.origin_domain,
    tf.destination_domain,
    REGEXP_REPLACE(tf.routers, r'[\{\}]', ''),
    tf.origin_transacting_asset
