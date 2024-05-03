/*
SELECT 
tm.*,
rm.asset_usd_price as router_asset_usd_price,
rm.* EXCEPT(ETH_price, canonical_domain, canonical_id, asset_usd_price)
FROM {{ ref('transfers_mapped') }} tm
LEFT JOIN {{ ref('routers_with_balances_mapped') }} rm
ON tm.`destination_domain` = rm.`domain`
AND tm.`destination_transacting_asset` = rm.`adopted`
AND LOWER(
  REPLACE((SELECT ARRAY_AGG(unnested_value LIMIT 1)[OFFSET(0)]
   FROM UNNEST(JSON_EXTRACT_ARRAY(tm.`routers`)) AS unnested_value), '"', '')
) = LOWER(rm.`address`)
*/
SELECT * FROM {{ ref('transfers_mapped') }}
