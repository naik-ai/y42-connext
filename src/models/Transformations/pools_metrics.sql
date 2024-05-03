WITH sp AS (
  SELECT
    *,
    CASE
      WHEN domain = '6648936' THEN 'Ethereum'
      WHEN domain = '1869640809' THEN 'Optimism'
      WHEN domain = '6450786' THEN 'BNB'
      WHEN domain = '6778479' THEN 'Gnosis'
      WHEN domain = '1886350457' THEN 'Polygon'
      WHEN domain = '1634886255' THEN 'Arbitrum One'
      WHEN domain = '1818848877' THEN 'Linea'
      WHEN domain = '31338' THEN 'Local Optimism'
      WHEN domain = '31339' THEN 'Local Arbitrum One'
      WHEN domain = '1835365481' THEN 'Metis'
      WHEN domain = '1650553709' THEN "Base Mainnet"
      WHEN domain = '1836016741' THEN 'Mode'
    ELSE
      CONCAT("Add this domain to Google sheet, not found for:", domain)
    END
    AS chain,
    JSON_EXTRACT_STRING_ARRAY(pooled_tokens)[0] AS token_1,
    JSON_EXTRACT_STRING_ARRAY(pooled_tokens)[1] AS token_2,
    CAST(JSON_EXTRACT_STRING_ARRAY(pool_token_decimals)[0] AS NUMERIC) AS pool_token_decimals_1,
    CAST(JSON_EXTRACT_STRING_ARRAY(pool_token_decimals)[1] AS NUMERIC) AS pool_token_decimals_2,
    CAST(JSON_EXTRACT_STRING_ARRAY(balances)[0] AS NUMERIC) AS balances_1,
    CAST(JSON_EXTRACT_STRING_ARRAY(balances)[1] AS NUMERIC) AS balances_2
  FROM
    {{ source('Cartographer', 'public_stableswap_pools') }}
  WHERE
    balances IS NOT NULL 
),
MaxAssetPrices AS (
  SELECT
    canonical_id,
    MAX(timestamp) AS max_timestamp
  FROM
    {{ source('Cartographer', 'public_asset_prices') }} asset_prices
  GROUP BY
    canonical_id 
),
pools_tvl_usd AS (
  SELECT
    DISTINCT
    sp.key AS pool_id,
    sp.token_2 as asset,
    assets.canonical_id,
    sp.domain,
    ct_1.domain_name,
    CASE
      WHEN ct_1.asset_name = '0x609aefb9fb2ee8f2fdad5dc48efb8fa4ee0e80fb' THEN 'nextWETH'
      ELSE COALESCE(ct_1.asset_name , sp.token_1)
    END as token_1_name, 
    COALESCE(ct_2.asset_name , sp.token_2) AS token_2_name,
    sp.balances_1 / POW(10, sp.pool_token_decimals_1) AS pool_1_amount,
    sp.balances_2 / POW(10, sp.pool_token_decimals_2) AS pool_2_amount,
    -- USD
    asset_prices.price * sp.balances_1 / POW(10, sp.pool_token_decimals_1) AS usd_pool_1_amount,
    asset_prices.price * sp.balances_2 / POW(10, sp.pool_token_decimals_2) AS usd_pool_2_amount
  FROM
    sp
  LEFT JOIN 
   {{ref('token_mapping')}} ct_1
  ON
    sp.token_1 = ct_1.asset AND sp.domain = ct_1.domain
  LEFT JOIN
    {{ref('token_mapping')}} ct_2
  ON
    sp.token_2 = ct_2.asset AND sp.domain = ct_1.domain
  LEFT JOIN
    {{ source('Cartographer', 'public_assets') }} assets
  ON
    sp.token_1 = assets.id
    AND sp.domain = assets.domain
  LEFT JOIN
    {{ source('Cartographer', 'public_asset_prices') }} asset_prices
  ON
    assets.canonical_id = asset_prices.canonical_id
  INNER JOIN
    MaxAssetPrices
  ON
    asset_prices.canonical_id = MaxAssetPrices.canonical_id
    AND asset_prices.timestamp = MaxAssetPrices.max_timestamp
),
RouterVolume AS (
  SELECT
  Distinct
    COALESCE(pr.token_2_name, rmt.destination_asset_name) as asset,
    COALESCE(pr.domain_name, rmt.destination_domain_name) as domain_name,
    SUM(usd_volume_1d) AS usd_volume_last_1_day,
    SUM(usd_volume_7d) AS usd_volume_last_7_days,
    SUM(usd_volume_30d) AS usd_volume_last_30_days,
    SUM(volume_1d) AS volume_1_day,
    SUM(volume_7d) AS volume_7_days,
    SUM(volume_30d) AS volume_30_days,
    SUM(usd_fast_volume_1d) AS fast_usd_volume_1_day,
    SUM(usd_fast_volume_7d) AS fast_usd_volume_7_days,
    SUM(usd_fast_volume_30d) AS fast_usd_volume_30_days,
    SUM(fast_volume_1d) AS fast_volume_1_day,
    SUM(fast_volume_7d) AS fast_volume_7_days,
    SUM(fast_volume_30d) AS fast_volume_30_days,
    MAX(CAST(rmt.last_transfer_date as DATE)) AS last_txn_date,
    SUM(CASE WHEN CAST(rmt.last_transfer_date as DATE) <= DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY) THEN rmt.balance_usd ELSE 0 END) AS inactive_balance_usd,
    SUM(CASE WHEN CAST(rmt.last_transfer_date as DATE) <= DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY) THEN rmt.locked_usd ELSE 0 END) AS inactive_locked_usd,
    SUM(CASE WHEN CAST(rmt.last_transfer_date as DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY) THEN rmt.balance_usd ELSE 0 END) AS active_balance_usd,
    SUM(CASE WHEN CAST(rmt.last_transfer_date as DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY) THEN rmt.locked_usd ELSE 0 END) AS active_locked_usd,
    SUM(rmt.balance_usd) AS total_balance_usd,
    SUM(rmt.locked_usd) AS total_locked_usd,
    SUM(rmt.balance/POWER(10,rmt.adopted_decimal)) AS total_balance_asset,
    SUM(rmt.locked/POWER(10,rmt.adopted_decimal)) AS total_locked_asset,
    SUM(usd_volume_1d)/SUM(rmt.locked_usd) AS utilization_last_1_day,
    SUM(usd_volume_7d)/SUM(rmt.locked_usd) AS utilization_last_7_days,
    SUM(usd_volume_30d)/SUM(rmt.locked_usd) AS utilization_last_30_days,
    MAX(pr.usd_pool_1_amount) as usd_pool_1_amount,
    MAX(pr.usd_pool_2_amount) as usd_pool_2_amount,
    MAX(pr.usd_pool_1_amount) + MAX(pr.usd_pool_2_amount) as pool_balance
  FROM 
    pools_tvl_usd pr
    FULL OUTER JOIN 
    {{ref('router_metrics')}} rmt ON pr.asset = rmt.destination_transacting_asset AND pr.domain = rmt.destination_domain
  GROUP BY 1,2
)

SELECT * FROM RouterVolume order by usd_volume_last_30_days desc
