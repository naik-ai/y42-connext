SELECT 
DISTINCT
`router_address`,
`destination_domain` AS router_domain,
--`origin_domain`,
`token_address`,
MAX(`last_bid`) AS last_bid
FROM {{ source('slippage_monitoring', 'router_monitoring') }}
GROUP BY 1,2,3
