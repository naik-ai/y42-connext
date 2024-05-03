WITH
daily_transfer_volume AS (
  SELECT * FROM
  {{ ref('daily_transfer_volume_y42_dedup') }}
  --`mainnet-bigq.y42_connext_y42_dev.daily_transfer_volume_y42_view`
  --`mainnet-bigq.y42_connext_y42_dev.source__Cartographer__public_daily_transfer_volume`
  --`mainnet-bigq.y42_connext_y42_dev.daily_transfer_volume_y42_dedup`

),

volumemetrics AS (
  SELECT
    status,
    router,
    asset,
    origin_chain,
    destination_chain,
    SUM(CASE WHEN transfer_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN usd_volume ELSE 0 END)
        AS usd_volume_last_1_day,
    SUM(CASE WHEN transfer_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) THEN usd_volume ELSE 0 END)
        AS usd_volume_last_7_days,
    SUM(CASE WHEN transfer_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN usd_volume ELSE 0 END)
        AS usd_volume_last_30_days,
    SUM(CASE WHEN transfer_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN volume ELSE 0 END)
        AS volume_last_1_day,
    SUM(CASE WHEN transfer_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) THEN volume ELSE 0 END)
        AS volume_last_7_days,
    SUM(CASE WHEN transfer_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN volume ELSE 0 END)
        AS volume_last_30_days,
    MAX(transfer_date) AS last_transfer_date,
    COUNTIF(status = 'CompletedSlow') AS slow_txns
    FROM
    daily_transfer_volume
  GROUP BY
    1, 2, 3, 4, 5
)

SELECT * FROM volumemetrics
