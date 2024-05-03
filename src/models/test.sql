SELECT * FROM {{ source('Cartographer', 'public_transfers_with_numeric_id') }}
