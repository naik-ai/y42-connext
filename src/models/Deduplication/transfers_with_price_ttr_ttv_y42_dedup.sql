SELECT
     *,
     row_number() OVER (PARTITION BY `transfer_id` ORDER BY tf.update_time DESC) AS row_num
FROM {{ source('Cartographer', 'public_transfers_with_price_ttr_ttv') }} AS tf
WHERE TRUE QUALIFY row_num = 1
