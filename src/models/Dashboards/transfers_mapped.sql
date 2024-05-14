--TO DO

--fix_pricing
--Missing assets
WITH connext_tokens AS (
    SELECT DISTINCT
    ct.token_address,
    ct.token_name,
    ct.is_xerc20
  FROM {{ source('bq_stage', 'stage_connext_tokens') }} ct
),

connext_contracts AS (
    SELECT 
        LOWER(xcall_caller) AS xcall_caller,
        * EXCEPT (xcall_caller)
    FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY `xcall_caller` ORDER BY `contract_name`) AS rn
            FROM {{ source('Mapping', 'contracts') }}
        ) AS subquery
    WHERE rn = 1
),

transfers_mapping AS (
    SELECT
    COALESCE(om.domain_name, t.origin_domain) AS origin_domain_name,
    COALESCE(dm.domain_name, t.`destination_domain`) AS destination_domain_name,
    COALESCE(om.asset_name, dm.asset_name, t.`origin_transacting_asset`)  AS origin_asset_name,
    COALESCE(om.`asset_decimals`, NULL) AS origin_asset_decimals,
    COALESCE(dm.`asset_name`, om.`asset_name`, t.`destination_transacting_asset`) AS destination_asset_name,
    COALESCE(dm.`asset_decimals`, NULL) AS destination_asset_decimals,
    CAST(om.is_xerc20 AS BOOL) AS is_origin_asset_xerc20,
    CAST(dm.is_xerc20 AS BOOL) AS is_destination_asset_xerc20,
    om.asset_type AS origin_asset_type,
    dm.asset_type AS destination_asset_type,
    CASE WHEN LOWER(t.xcall_caller) != LOWER(t.xcall_tx_origin) THEN 'Contract' ELSE 'EOA' END AS caller_type,
    --t.destination_transacting_amount, 
    cc.* EXCEPT (xcall_caller, rn),
    t.*
    FROM {{ ref('transfers') }} AS t
    LEFT JOIN {{ ref('token_mapping') }} AS om ON t.`origin_transacting_asset` = om.`asset` AND t.`origin_domain` = om.`domain`
    LEFT JOIN {{ ref('token_mapping') }} AS dm ON t.`destination_transacting_asset` = dm.`asset` AND t.`destination_domain` = dm.`domain`
    LEFT JOIN connext_contracts AS cc ON t.`xcall_caller` = cc.`xcall_caller`
    /*
    LEFT JOIN 'github_parser_chains') }} AS odm ON t.`origin_domain` = odm.`domainid`
    LEFT JOIN 'github_parser_chains') }} AS ddm ON t.`destination_domain` = ddm.`domainid`
    LEFT JOIN 'github_parser_tokens') }} AS otam ON t.`origin_transacting_asset` = otam.`assetid` AND t.`origin_domain` = otam.`domainid`
    LEFT JOIN 'github_parser_tokens') }} AS dtam ON t.`destination_transacting_asset` = dtam.`assetid`AND t.`destination_domain` = dtam.`domainid`
    LEFT JOIN connext_tokens AS cc_origin ON t.origin_transacting_asset = cc_origin.token_address
    LEFT JOIN connext_tokens AS cc_destination ON t.destination_transacting_asset = cc_destination.token_address
    */
),

transfers_amounts AS (
    Select 
    CAST(origin_transacting_amount AS FLOAT64) / POWER(10, origin_asset_decimals) as origin_amount,
    CAST(destination_transacting_amount AS FLOAT64) * POWER(10, 18 - destination_asset_decimals) as normalized_out,
    CAST(destination_transacting_amount AS FLOAT64) / POWER(10, destination_asset_decimals) as destination_amount,
    CAST(bridged_amt AS FLOAT64) / POWER(10, decimals) as bridged_amount,
    * 
    from transfers_mapping
),
--Fixing ezETH pricing
ezeth_price_fix AS (
  SELECT * EXCEPT(asset_usd_price, usd_amount),
    CASE
      WHEN (
        (t1.origin_asset_name in ('dai','xdai','usdt','wxdai','m.usdt','usdc','m.usdc')) OR 
        (t1.destination_asset_name in ('dai','xdai','usdt','wxdai','m.usdt','usdc','m.usdc'))
        ) 
      AND (t1.asset_usd_price = 0) 
        THEN 1
      WHEN (t1.origin_asset_name in ('ezeth','weth','aeth') or t1.destination_asset_name in ('ezeth','weth','aeth')) AND t1.asset_usd_price = 0 
        THEN t2.eth_price
      ELSE t1.asset_usd_price
    END AS asset_usd_price,
    CASE
      WHEN (
        (t1.origin_asset_name in ('dai','xdai','usdt','wxdai','m.usdt','usdc','m.usdc')) OR 
        (t1.destination_asset_name in ('dai','xdai','usdt','wxdai','m.usdt','usdc','m.usdc'))
        ) 
      AND (t1.asset_usd_price = 0) 
        THEN destination_amount
      WHEN (t1.origin_asset_name in ('ezeth','weth','aeth') or t1.destination_asset_name in ('ezeth','weth','aeth')) AND t1.asset_usd_price = 0
      --t1.asset = 'ezeth' OR (t1.asset = 'weth' AND (t1.asset_price = 0)) 
        THEN t2.eth_price * destination_amount
      ELSE t1.usd_amount
    END AS usd_amount,
  FROM transfers_amounts t1
  CROSS JOIN (
    SELECT asset_usd_price as ETH_price
    FROM transfers_amounts
    WHERE origin_asset_name = 'weth' and asset_usd_price > 0
    ORDER BY xcall_timestamp DESC
    LIMIT 1  -- Replace 'ETH' with the asset you want to use for the price
  ) t2
),

relayerfees AS (
  SELECT 
  --(LENGTH(relayer_fees)) AS relayerfees_lenght,
  t.*,
  REGEXP_EXTRACT(relayer_fees, r'"(0x[a-fA-F0-9]{40})": "\d+"') AS relayerfee_address1,
  REGEXP_EXTRACT(relayer_fees, r'"0x[a-fA-F0-9]{40}": "(\d+)"') AS relayerfee_amount1,
  REGEXP_EXTRACT(relayer_fees, r'"(0x[a-fA-F0-9]{40})": "\d+"', 1, 2) AS relayerfee_address2,
  REGEXP_EXTRACT(relayer_fees, r'"0x[a-fA-F0-9]{40}": "(\d+)"', 1, 2) AS relayerfee_amount2
  FROM ezeth_price_fix t 
--ORDER BY (LENGTH(relayer_fees)) desc
),

rf AS (
  SELECT 
    t.*,
    tm.asset_name as relayer_fee_token_1,
    tm.asset_decimals as relayer_fee_token_1_decimals,
    CAST(t.relayerfee_amount1 AS FLOAT64)/POWER(10, CAST(tm.asset_decimals AS FLOAT64)) relayer_amount_1,
    tm2.asset_name as relayer_fee_token_2,
    tm2.asset_decimals as relayer_fee_token_2_decimals,
    CAST(t.relayerfee_amount2  AS FLOAT64)/POWER(10, CAST(tm2.asset_decimals AS FLOAT64)) relayer_amount_2
  
  FROM relayerfees t
  LEFT JOIN  {{ ref('token_mapping') }} tm ON t.relayerfee_address1 = tm.asset AND t.origin_domain = tm.domain
  LEFT JOIN  {{ ref('token_mapping') }} tm2 ON t.relayerfee_address2 = tm2.asset AND t.origin_domain = tm2.domain
),

router_regexp AS (
  SELECT
    t.*,
    REGEXP_REPLACE(t.routers, r'[\[\]\"]', '') AS router
  FROM rf t
),

router_mapping AS (
  SELECT
    t.*,
    COALESCE(rm.`name`, t.`router`)  AS router_name
  FROM router_regexp AS t
  LEFT JOIN {{ source('bq_raw', 'raw_dim_connext_routers_name') }} AS rm ON LOWER(t.`router`) = LOWER(rm.`router`)
),

domain_name_fix AS (
    SELECT 
      CASE
        WHEN destination_domain_name = '6648936' THEN 'Ethereum Mainnet'
        WHEN destination_domain_name = '1869640809' THEN 'Optimistic Ethereum'
        WHEN destination_domain_name = '6450786' THEN 'Binance Smart Chain Mainnet'
        WHEN destination_domain_name = '6778479' THEN 'xDAI Chain'
        WHEN destination_domain_name = '1886350457' THEN 'Matic Mainnet'
        WHEN destination_domain_name = '1634886255' THEN 'Arbitrum One'
        WHEN destination_domain_name = '1818848877' THEN 'Linea Mainnet'
        WHEN destination_domain_name = '1835365481' THEN 'Metis Andromeda Mainnet'
        WHEN destination_domain_name = '1650553709' THEN 'Base Mainnet'
        WHEN destination_domain_name = '1836016741'THEN 'Mode Mainnet'
        ELSE destination_domain_name
      END AS destination_domain_name,
    t.* EXCEPT (destination_domain_name)

    FROM router_mapping AS t
)

SELECT * FROM domain_name_fix

--ttt AS (select * from ezeth_price_fix)

--SELECT * FROM TTT

/*
SELECT --origin_domain_name, 
origin_asset_name, 
--destination_domain_name, 
destination_asset_name, 
sum(destination_amount) as s, sum(CAST(destination_transacting_amount AS numeric)) as ss, sum(CAST(usd_amount AS numeric)) as sss, count(*) as c
FROM ttt where xcall_date >= '2024-01-01' AND CAST(destination_transacting_amount AS numeric) != 0
 group by 1,2--,3,4 
 order by count(*) desc
 -- WHERE (destination_transacting_asset IS NOT NULL and destination_asset_name IS NULL) OR (origin_transacting_asset IS NOT NULL and origin_asset_name IS NULL)
 */
