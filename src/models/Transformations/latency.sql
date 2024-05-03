SELECT
    status,
    origin_transacting_asset,
    origin_domain,
    destination_transacting_asset,
    destination_domain,
    xcall_date,
    COUNT(*) AS count,
    (
        SELECT COUNT(*)
        FROM {{ ref('transfers') }} AS tf1
        WHERE
            (updated_slippage > 0 OR error_status LIKE '%slippage%')
            AND tf1.origin_transacting_asset = tf.origin_transacting_asset
            AND tf1.origin_domain = tf.origin_domain
            AND tf1.destination_transacting_asset = tf.destination_transacting_asset
            AND tf1.destination_domain = tf.destination_domain
            AND tf1.xcall_date = tf.xcall_date
    ) AS count_bumped_transfers,
    (
        SELECT SUM(usd_amount)
        FROM {{ ref('transfers') }} AS tf2
        WHERE
            (updated_slippage > 0 OR error_status LIKE '%slippage%')
            AND tf2.origin_transacting_asset = tf.origin_transacting_asset
            AND tf2.origin_domain = tf.origin_domain
            AND tf2.destination_transacting_asset = tf.destination_transacting_asset
            AND tf2.destination_domain = tf.destination_domain
            AND tf2.xcall_date = tf.xcall_date
    ) AS sum_bumped_transfers,
    COUNTIF(
        (status = 'CompletedFast' AND ttv > 300)
        OR (destination_domain = '6648936' AND ttv > 43200)
        OR (destination_domain != '6648936' AND ttv > 21600)
    ) AS count_txns_non_sla,
    SUM(
      CASE WHEN ttv > CASE
        WHEN (status = 'CompletedFast') THEN 300
        WHEN (status = 'CompletedSlow' AND destination_domain = '6648936') THEN 43200
        WHEN (status = 'CompletedSlow' AND destination_domain != '6648936') THEN 21600
        END
      THEN usd_amount
      ELSE 0
      END
    ) AS sum_txns_non_sla,
    SUM(usd_amount) AS total_usd_amount,
    SUM(CAST(normalized_in AS NUMERIC)) AS sum_normalized_in,
    AVG(ttv) AS avg_ttv,
    MAX(ttv) AS max_ttv,
    MIN(ttv) AS min_ttv,
    APPROX_QUANTILES(ttv, 100)[ORDINAL(50)] AS median_ttv,
    APPROX_QUANTILES(ttv, 100)[ORDINAL(10)] AS per10th_ttv,
    APPROX_QUANTILES(ttv, 100)[ORDINAL(80)] AS per80th_ttv,
    APPROX_QUANTILES(ttv, 100)[ORDINAL(90)] AS per90th_ttv,
    APPROX_QUANTILES(ttv, 100)[ORDINAL(95)] AS per95th_ttv,
    APPROX_QUANTILES(ttv, 100)[ORDINAL(99)] AS per99th_ttv,
    APPROX_QUANTILES(ttr, 100)[ORDINAL(50)] AS median_ttr,
    APPROX_QUANTILES(ttr, 100)[ORDINAL(10)] AS per10th_ttr,
    APPROX_QUANTILES(ttr, 100)[ORDINAL(80)] AS per80th_ttr,
    APPROX_QUANTILES(ttr, 100)[ORDINAL(90)] AS per90th_ttr,
    APPROX_QUANTILES(ttr, 100)[ORDINAL(95)] AS per95th_ttr,
    APPROX_QUANTILES(ttr, 100)[ORDINAL(99)] AS per99th_ttr
FROM
    {{ ref('transfers_mapped') }} AS tf
WHERE
    CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY
    1, 2, 3, 4, 5, 6
