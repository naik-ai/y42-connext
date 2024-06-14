{{ config(materialized='table') }}

WITH
chains_meta AS (
    SELECT DISTINCT
        domainid,
        chain_name AS chain
    FROM
        `mainnet-bigq.raw.stg__ninja_connext_prod_chains_tokens_clean`
),

assets AS (
    SELECT DISTINCT
        da.domain,
        da.canonical_id,
        da.adopted_decimal AS decimal
    FROM
        `mainnet-bigq.public.assets` AS da
),

tokens_meta AS (
    SELECT DISTINCT
        token_name AS asset,
        LOWER(token_address) AS local
    FROM
        `mainnet-bigq.stage.connext_tokens`
),

tx AS (
    SELECT
        t.destination_domain,
        t.destination_local_asset,
        a.decimal,
        TIMESTAMP_SECONDS(t.xcall_timestamp) AS xcall_timestamp,
        CASE
            WHEN
                t.status = "CompletedSlow"
                THEN CAST(destination_transacting_amount AS FLOAT64) / POW(10, COALESCE(CAST(a.decimal AS INT64), 0))
        END AS destination_slow_amount
    FROM
        `public.transfers` AS t
    LEFT JOIN assets AS a
        ON (
            t.canonical_id = a.canonical_id
            AND t.destination_domain = a.domain
        ) -- TODO Remove Filter Later
    WHERE JSON_EXTRACT_SCALAR(t.routers, "$[0]") IS NULL

),

tx_agg AS (
    SELECT
        DATE_TRUNC(xcall_timestamp, HOUR) AS xcall_timestamp,
        cm.chain AS chain,
        COALESCE(tm.asset, t.destination_local_asset) AS asset,
        SUM(destination_slow_amount) AS destination_slow_volume
    FROM
        tx AS t
    LEFT JOIN chains_meta AS cm ON t.destination_domain = cm.domainid
    LEFT JOIN tokens_meta AS tm ON (t.destination_local_asset = tm.local)
    GROUP BY
        1,
        2,
        3
),

clean_final AS (
    SELECT
        chain,
        asset,
        destination_slow_volume,
        DATE_TRUNC(xcall_timestamp, HOUR) AS date,
        CASE
            WHEN asset = "ETH" THEN "WETH"
            WHEN asset = "NEXT" THEN "NEXT"
            WHEN STARTS_WITH(asset, "next") THEN REGEXP_REPLACE(asset, "^next", "")
            ELSE asset
        END AS asset_group,
        CASE
            WHEN asset = "ETH" THEN "WETH"
            WHEN asset = "NEXT" THEN "NEXT"
            WHEN STARTS_WITH(asset, "next") THEN REGEXP_REPLACE(asset, "^next", "")
            WHEN asset = "alUSD" THEN "USDT"
            WHEN asset = "nextALUSD" THEN "USDT"
            WHEN asset = "instETH" THEN "WETH"
            WHEN asset = "ezETH" THEN "WETH"
            WHEN asset = "alETH" THEN "WETH"
            WHEN asset = "nextalETH" THEN "WETH"
            ELSE asset
        END AS price_group
    FROM
        tx_agg
),

-- adding daily pricing to final
daily_price AS (
    SELECT
        DATE_TRUNC(CAST(p.date AS TIMESTAMP), HOUR) AS date,
        p.symbol AS asset,
        AVG(p.average_price) AS price
    FROM
        `mainnet-bigq.dune.source_hourly_token_pricing_blockchain_eth` AS p
    GROUP BY
        1,
        2
),

usd_data AS (
    SELECT
        pcf.date,
        pcf.chain,
        pcf.asset_group,
        pcf.asset,
        dp.price,
        pcf.destination_slow_volume,
        -- USD values
        dp.price * pcf.destination_slow_volume AS destination_slow_volume_usd
    FROM
        clean_final AS pcf
    LEFT JOIN daily_price AS dp
        ON
            pcf.date = dp.date
            AND pcf.price_group = dp.asset
    ORDER BY
        1,
        2,
        3,
        4 DESC
)

SELECT *
FROM
    usd_data
WHERE
    price IS NOT NULL
