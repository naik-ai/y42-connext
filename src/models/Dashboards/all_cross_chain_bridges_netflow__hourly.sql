{{ config(materialized = 'table') }}

-- STEPS
-- 1. get all the cross chain bridges on hourly basis
--[X] 1.1. Connext
--[X] 1.2. Router Protocol
-- 1.3. Cannonical Bridges
-- 1.4. Across Bridges
-- 1.5. De-Bridge Bridges
--[X] 2. union all the netflow
--[X] 3. calculate the netflow on hourly basis

-- 1.1. Connext
WITH
-- adding hourly pricing to final
hourly_price AS (
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

chainlist_metadata AS (
    SELECT DISTINCT
        COALESCE(ct.name, cn.name) AS name,
        COALESCE(ct.chainid, cn.chainid) AS chainid
    FROM
        `mainnet-bigq.raw.source_chainlist_network__chains` AS cn
    LEFT JOIN `mainnet-bigq.raw.source_chaindata_nija__metadata` AS ct ON cn.chainid = ct.chainid
    UNION ALL
    SELECT
        "tron" AS name,
        728126428 AS chainid
),

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
        origin_domain AS `from`,
        destination_domain AS `to`,
        t.destination_local_asset AS asset,
        DATE_TRUNC(TIMESTAMP_SECONDS(t.xcall_timestamp), HOUR) AS xcall_timestamp,
        CAST(destination_transacting_amount AS FLOAT64) / POW(10, COALESCE(CAST(a.decimal AS INT64), 0)) AS amount
    FROM
        `public.transfers` AS t
    LEFT JOIN assets AS a ON (
        t.canonical_id = a.canonical_id
        AND t.destination_domain = a.domain
    )
),

tx_agg AS (
    SELECT
        DATE_TRUNC(xcall_timestamp, HOUR) AS date,
        "connext" AS bridge,
        COALESCE(tm.asset, t.asset) AS asset,
        COALESCE(fcm.chain, t.from) AS `from`,
        COALESCE(tcm.chain, t.to) AS `to`,
        SUM(amount) AS amount
    FROM
        tx AS t
    LEFT JOIN chains_meta AS fcm ON t.from = fcm.domainid
    LEFT JOIN chains_meta AS tcm ON t.to = tcm.domainid
    LEFT JOIN tokens_meta AS tm ON (t.asset = tm.local)
    WHERE
        amount > 0
    GROUP BY
        1,
        2,
        3,
        4,
        5
),

-- 1.2. Router Protocol
raw_router_protocol AS (
    SELECT DISTINCT
        src_chain_id,
        src_symbol,
        dest_stable_symbol,
        -- dest_stable_symbol: use this for price contact for the amount
        dest_chain_id,
        dest_stable_amount AS amount,
        CAST(dest_timestamp AS INT64) AS dest_timestamp
    FROM
        `mainnet-bigq.raw.source_router_protocol__transactions`
    WHERE
        status = "completed"
),

router_protocol_agg AS (
    -- # same cols as connext_flow_usd
    SELECT
        DATE_TRUNC(TIMESTAMP_SECONDS(rt.dest_timestamp), HOUR) AS date,
        "router_protocol" AS bridge,
        rt.dest_stable_symbol AS asset,
        COALESCE(fcm.name, rt.src_chain_id) AS `from`,
        COALESCE(tcm.name, rt.dest_chain_id) AS `to`,
        SUM(CAST(rt.amount AS FLOAT64)) AS amount
    FROM
        raw_router_protocol AS rt
    LEFT JOIN chainlist_metadata AS fcm ON (rt.src_chain_id = CAST(fcm.chainid AS STRING))
    LEFT JOIN chainlist_metadata AS tcm ON (rt.dest_chain_id = CAST(tcm.chainid AS STRING))
    GROUP BY
        1,
        2,
        3,
        4,
        5
),

-- 1.3. Cannonical Bridges
-- 1.4. Across Bridges
-- 1.5. De-Bridge Bridges
-- agg all Bridges hourly data
hourly_flow AS (
    SELECT
        hf.*,
        CASE
            WHEN hf.asset = "ETH" THEN "WETH"
            WHEN hf.asset = "NEXT" THEN "NEXT"
            WHEN STARTS_WITH(hf.asset, "next") THEN REGEXP_REPLACE(hf.asset, "^next", "")
            WHEN hf.asset = "alUSD" THEN "USDT"
            WHEN hf.asset = "nextALUSD" THEN "USDT"
            WHEN hf.asset = "instETH" THEN "WETH"
            WHEN hf.asset = "ezETH" THEN "WETH"
            WHEN hf.asset = "alETH" THEN "WETH"
            WHEN hf.asset = "nextalETH" THEN "WETH"
            ELSE hf.asset
        END AS asset_group
    FROM
        (
            SELECT *
            FROM
                tx_agg
            UNION ALL
            SELECT *
            FROM
                router_protocol_agg
        ) AS hf
),

hourly_flow_usd AS (
    SELECT
        hf.date,
        hf.asset,
        hf.asset_group,
        hf.bridge,
        hf.from,
        hf.to,
        SUM(hf.amount) AS amount,
        SUM(hf.amount * p.price) AS amount_usd
    FROM
        hourly_flow AS hf
    -- removing vol where there is no price available
    INNER JOIN hourly_price AS p
        ON (
            hf.asset_group = p.asset
            AND hf.date = p.date
        )
    GROUP BY
        1,
        2,
        3,
        4,
        5,
        6
),

inflow AS (
    SELECT
        hfu.bridge,
        hfu.date,
        hfu.from AS chain,
        hfu.asset,
        hfu.asset_group,
        SUM(hfu.amount_usd) AS inflow
    FROM
        hourly_flow_usd AS hfu
    GROUP BY
        1,
        2,
        3,
        4,
        5
),

outflow AS (
    SELECT
        hfu.bridge,
        hfu.date,
        hfu.to AS chain,
        hfu.asset,
        hfu.asset_group,
        SUM(hfu.amount_usd) AS outflow
    FROM
        hourly_flow_usd AS hfu
    GROUP BY
        1,
        2,
        3,
        4,
        5
),

net_flow AS (
    SELECT
        i.inflow,
        o.outflow,
        COALESCE(i.date, o.date) AS date,
        COALESCE(i.bridge, o.bridge) AS bridge,
        COALESCE(i.chain, o.chain) AS chain,
        COALESCE(i.asset, o.asset) AS asset,
        COALESCE(i.asset_group, o.asset_group) AS asset_group,
        (COALESCE(i.inflow, 0) + COALESCE(o.outflow, 0)) AS volume,
        (
            COALESCE(i.inflow, 0) - COALESCE(o.outflow, 0)
        ) AS net_amount
    -- (
    --     100 - ABS(
    --         (COALESCE(i.inflow, 0) - COALESCE(o.outflow, 0)) / NULLIF(
    --             (COALESCE(i.inflow, 0) + COALESCE(o.outflow, 0)),
    --             0
    --         )
    --     ) * 100
    -- ) AS percent_netted
    FROM
        inflow AS i
    FULL OUTER JOIN outflow AS o
        ON
            i.date = o.date
            AND i.bridge = o.bridge
            AND i.chain = o.chain
            AND i.asset = o.asset
            AND i.asset_group = o.asset_group
)

SELECT *
FROM
    net_flow
-- WHERE net_flow.asset_group = 'WETH'
