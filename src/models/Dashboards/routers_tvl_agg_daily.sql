{{ config(materialized='table') }}

-- Metrics: TVL, APR, APY
WITH
    chains_meta AS (
        SELECT DISTINCT
            domainid,
            chain_name AS chain
        FROM
            `mainnet-bigq.raw.stg__ninja_connext_prod_chains_tokens_clean` ct
    ),
    tokens_meta AS (
        SELECT DISTINCT
            LOWER(token_address) AS local,
            token_name AS asset
        FROM
            `mainnet-bigq.stage.connext_tokens` ct
            -- WHERE token_address = "0xb368ae21081709d03c00d7dc51737d8abd9384e6"
    ),
    assets AS (
        SELECT DISTINCT
            da.canonical_id,
            da.decimal
        FROM
            `mainnet-bigq.public.assets` da
    ),
    raw_router_tvl AS (
        SELECT
            DATE_TRUNC (TIMESTAMP_SECONDS (r.timestamp), DAY) AS date,
            r.router,
            cm.chain,
            COALESCE(tm.asset, r.asset) AS asset,
            event,
            CASE
                WHEN event = 'Add' THEN CAST(r.amount AS FLOAT64)
                ELSE - CAST(r.amount AS FLOAT64)
            END AS amount,
            SUM(
                CASE
                    WHEN event = 'Add' THEN CAST(r.amount AS FLOAT64)
                    ELSE - CAST(r.amount AS FLOAT64)
                END
            ) OVER (
                PARTITION BY
                    r.router,
                    r.asset,
                    r.domain
                ORDER BY
                    r.timestamp
            ) AS running_amount
        FROM
            `mainnet-bigq.public.router_liquidity_events` r
            LEFT JOIN chains_meta cm ON r.domain = cm.domainid
            LEFT JOIN tokens_meta tm ON (r.asset = tm.local)
        ORDER BY
            1 DESC
    ),
    routers_tvl AS (
        SELECT
            date,
            router,
            chain,
            asset,
            SUM(amount) AS amount,
            SUM(running_amount) AS locked
        FROM
            raw_router_tvl
        GROUP BY
            1,
            2,
            3,
            4
        ORDER BY
            1 DESC
    ),

    tx AS (
        SELECT
            JSON_EXTRACT_SCALAR (t.routers, '$[0]') AS router,
            t.xcall_timestamp,
            t.destination_domain,
            t.destination_local_asset,
            CAST(destination_transacting_amount AS FLOAT64) / POW (10, COALESCE(CAST(a.decimal AS INT64), 0)) AS destination_amount
        FROM
            `public.transfers` t
            LEFT JOIN assets a ON (t.canonical_id = a.canonical_id)
        WHERE
            status = "CompletedFast"
    ),
    
    fees AS (
        SELECT
            DATE_TRUNC (TIMESTAMP_SECONDS (xcall_timestamp), DAY) AS date,
            router,
            cm.chain AS chain,
            COALESCE(tm.asset, t.destination_local_asset) AS asset,
            SUM(destination_amount * 0.0005) AS router_fee,
            SUM(destination_amount) AS destination_volume
        FROM tx t
            LEFT JOIN chains_meta cm ON t.destination_domain = cm.domainid
            LEFT JOIN tokens_meta tm ON (t.destination_local_asset = tm.local)
        GROUP BY
            1,
            2,
            3,
            4
    ),
    date_range AS (
        SELECT
            router,
            chain,
            asset,
            MIN(date) AS min_date,
            MAX(date) AS max_date
        FROM
            fees
        GROUP BY
            router,
            chain,
            asset
    ),
    all_dates AS (
        SELECT
            router,
            chain,
            asset,
            DATE_ADD (min_date, INTERVAL seq DAY) AS date
        FROM
            date_range
            CROSS JOIN UNNEST (
                GENERATE_ARRAY (0, DATE_DIFF (max_date, min_date, DAY))
            ) AS seq
    ),
    -- Fill fees for all dates
    filled_fees AS (
        SELECT
            COALESCE(ad.date, f.date) AS date,
            COALESCE(ad.router, f.router) AS router,
            COALESCE(ad.chain, f.chain) AS chain,
            COALESCE(ad.asset, f.asset) AS asset,
            f.router_fee,
            f.destination_volume AS router_volume,
            SUM(COALESCE(f.router_fee, 0)) OVER (
                PARTITION BY
                    COALESCE(ad.router, f.router),
                    COALESCE(ad.chain, f.chain),
                    COALESCE(ad.asset, f.asset)
                ORDER BY
                    COALESCE(ad.date, f.date)
            ) AS total_fee_earned,
            SUM(COALESCE(f.destination_volume, 0)) OVER (
                PARTITION BY
                    COALESCE(ad.router, f.router),
                    COALESCE(ad.chain, f.chain),
                    COALESCE(ad.asset, f.asset)
                ORDER BY
                    COALESCE(ad.date, f.date)
            ) AS total_router_volume
        FROM
            all_dates ad
            FULL OUTER JOIN fees f ON ad.date = f.date
            AND ad.router = f.router
            AND ad.chain = f.chain
            AND ad.asset = f.asset
    ),
    -- Fill routers TVL for all dates
    filled_routers_tvl AS (
        SELECT
            COALESCE(ad.date, rt.date) AS date,
            COALESCE(ad.router, rt.router) AS router,
            COALESCE(ad.chain, rt.chain) AS chain,
            COALESCE(ad.asset, rt.asset) AS asset,
            rt.amount AS amount,
            -- # Total locked: filling with previous non zero value
            COALESCE(
                rt.locked,
                LAST_VALUE (rt.locked IGNORE NULLS) OVER (
                    PARTITION BY
                        COALESCE(ad.router, rt.router),
                        COALESCE(ad.chain, rt.chain),
                        COALESCE(ad.asset, rt.asset)
                    ORDER BY
                        COALESCE(ad.date, rt.date)
                )
            
            ) AS total_locked
        FROM
            all_dates ad
            FULL OUTER JOIN routers_tvl rt ON ad.date = rt.date
            AND ad.router = rt.router
            AND ad.chain = rt.chain
            AND ad.asset = rt.asset
    ),

    router_bal_hist AS (
        SELECT
            date,
            router,
            chain,
            asset,
            locked AS total_locked,
            fees_earned AS total_fees_earned
        FROM
            (
                SELECT
                    DATE_TRUNC (ab.snapshot_time, DAY) AS date,
                    ab.router_address AS router,
                    cm.chain,
                    tm.asset,
                    ab.locked / POW (10, CAST(a.decimal AS INT64)) AS locked,
                    ab.fees_earned / POW (10, CAST(a.decimal AS INT64)) AS fees_earned,
                    ROW_NUMBER() OVER (
                        PARTITION BY
                            ab.router_address,
                            cm.chain,
                            tm.asset,
                            DATE_TRUNC (ab.snapshot_time, DAY)
                        ORDER BY
                            ab.snapshot_time DESC
                    ) AS rn
                FROM
                    `mainnet-bigq.y42_connext_y42_dev.routers_assets_balance_hist` ab
                    LEFT JOIN `mainnet-bigq.public.assets` a ON a.domain = ab.asset_domain
                    AND a.canonical_id = ab.asset_canonical_id
                    LEFT JOIN chains_meta cm ON ab.asset_domain = cm.domainid
                    LEFT JOIN tokens_meta tm ON a.local = tm.local
            )
        WHERE
            rn = 1
    ),
    combined_router_tvl_fee AS (
        -- combine filled fee + router_tvl
        SELECT
            COALESCE(frt.date, ff.date) AS date,
            COALESCE(frt.router, ff.router) AS router,
            COALESCE(frt.chain, ff.chain) AS chain,
            COALESCE(frt.asset, ff.asset) AS asset,
            ff.router_fee,
            ff.total_fee_earned,
            ff.router_volume,
            ff.total_router_volume,
            frt.amount,
            frt.total_locked
        FROM
            filled_fees ff
            FULL OUTER JOIN filled_routers_tvl frt ON ff.date = frt.date
            AND ff.router = frt.router
            AND ff.chain = frt.chain
            AND ff.asset = frt.asset
    ),
    final AS (
        -- combine route bal hist to use metric for TVL coalesec with combined_router_tvl_fee
        SELECT
            COALESCE(rbh.date, ctv.date) AS date,
            COALESCE(rbh.router, ctv.router) AS router,
            COALESCE(rbh.chain, ctv.chain) AS chain,
            COALESCE(rbh.asset, ctv.asset) AS asset,
            ctv.router_fee,
            ctv.router_volume,
            COALESCE(rbh.total_fees_earned, ctv.total_fee_earned) AS total_fee_earned,
            ctv.amount,
            COALESCE(rbh.total_locked, ctv.total_locked) AS total_locked,
            rbh.total_locked AS rbh_total_locked,
            ctv.total_locked AS ctv_total_locked
        FROM
            combined_router_tvl_fee ctv
            FULL OUTER JOIN router_bal_hist rbh ON ctv.date = rbh.date
            AND ctv.router = rbh.router
            AND ctv.chain = rbh.chain
            AND ctv.asset = rbh.asset
        ORDER BY
            1 DESC
    ),
    clean_final AS (
        SELECT
            DATE_TRUNC (f.date, DAY) AS date,
            f.router,
            COALESCE(r.name, f.router) AS router_name,
            f.chain,
            f.asset,
            -- asset group
            CASE
                WHEN f.asset = 'ETH' THEN 'WETH'
                WHEN f.asset = 'NEXT' THEN 'NEXT'
                WHEN STARTS_WITH (f.asset, 'next') THEN REGEXP_REPLACE (f.asset, '^next', '')
                ELSE f.asset
            END AS asset_group,
            CASE
                WHEN f.asset = 'ETH' THEN 'WETH'
                WHEN f.asset = 'NEXT' THEN 'NEXT'
                WHEN STARTS_WITH (f.asset, 'next') THEN REGEXP_REPLACE (f.asset, '^next', '')
                WHEN f.asset = 'alUSD' THEN 'USDT'
                WHEN f.asset = 'nextALUSD' THEN 'USDT'
                WHEN f.asset = 'instETH' THEN 'WETH'
                WHEN f.asset = 'ezETH' THEN 'WETH'
                WHEN f.asset = 'alETH' THEN 'WETH'
                WHEN f.asset = 'nextalETH' THEN 'WETH'
                ELSE f.asset
            END AS price_group,
            f.router_fee,
            f.router_volume,
            f.total_fee_earned,
            f.amount,
            f.total_locked,
            f.rbh_total_locked,
            f.ctv_total_locked,
            f.total_locked + f.total_fee_earned AS total_balance
        FROM
            final f
            LEFT JOIN `mainnet-bigq.raw.dim_connext_routers_name` r ON LOWER(f.router) = LOWER(r.router)
    ),
    -- adding daily pricing to final
    daily_price AS (
        SELECT
            DATE_TRUNC (CAST(p.date AS TIMESTAMP), DAY) AS date,
            p.symbol AS asset,
            AVG(p.average_price) AS price
        FROM
            `mainnet-bigq.dune.source_hourly_token_pricing_blockchain_eth` p
        GROUP BY
            1,
            2
    ),
    usd_data AS (
        SELECT
            cf.date,
            cf.router,
            cf.router_name,
            cf.chain,
            cf.asset_group,
            cf.asset,
            dp.price,
            cf.router_fee,
            cf.router_volume,
            cf.total_locked,
            cf.total_fee_earned,
            cf.amount,
            cf.total_balance,
            -- USD values
            dp.price * cf.router_fee AS router_fee_usd,
            dp.price * cf.router_volume AS router_volume_usd,
            dp.price * cf.amount AS amount_usd,
            dp.price * cf.total_locked AS total_locked_usd,
            dp.price * cf.total_fee_earned AS total_fee_earned_usd,
            dp.price * cf.total_balance AS total_balance_usd
        FROM
            clean_final cf
            LEFT JOIN daily_price dp ON cf.date = dp.date
            AND cf.price_group = dp.asset
        ORDER BY
            1,
            2,
            3,
            4 DESC
    )
SELECT
    *
FROM
    usd_data
WHERE
    price IS NOT NULL
ORDER BY
    1 DESC
