SELECT
    *,
    row_number() OVER (PARTITION BY `id` ORDER BY `volume` DESC) AS ROW_NUM
FROM {{ source('Cartographer', 'public_daily_transfer_volume') }}
WHERE TRUE QUALIFY ROW_NUM = 1
