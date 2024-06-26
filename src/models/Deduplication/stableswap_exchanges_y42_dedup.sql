SELECT
    *,
    row_number() OVER (PARTITION BY `id` ORDER BY `timestamp` DESC) AS row_num
FROM {{ source('Cartographer', 'public_stableswap_exchanges') }}
WHERE TRUE QUALIFY row_num = 1
