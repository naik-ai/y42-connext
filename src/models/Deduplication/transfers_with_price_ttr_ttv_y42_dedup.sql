SELECT
     *,
     tf.execute_timestamp - tf.xcall_timestamp AS ttv,
     tf.reconcile_timestamp - tf.xcall_timestamp AS ttr,
     row_number() OVER (PARTITION BY `transfer_id` ORDER BY tf.update_time DESC) AS row_num
FROM {{ source('Cartographer', 'public_transfers_with_price') }} AS tf
WHERE TRUE QUALIFY row_num = 1
