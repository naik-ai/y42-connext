{{ config(materialized = 'table') }}

WITH inflow AS (
    SELECT
        TIMESTAMP_SECONDS(d.date) AS date,
        d.symbol AS asset,
        d.chain AS chain,
        d.name AS bridge,
        SUM(d.usd_value) AS inflow
    FROM `mainnet-bigq.raw.stg__cln_source_defilamma_bridges_history_tokens` AS d
    WHERE symbol IS NOT NULL AND usd_value > 0 AND tx_type= "deposit"
    GROUP BY 1, 2, 3,4
),
outflow AS (
    SELECT
        TIMESTAMP_SECONDS(d.date) AS date,
        d.symbol AS asset,
        d.chain AS chain,
        d.name AS bridge,
        SUM(d.usd_value) AS outflow
    FROM `mainnet-bigq.raw.stg__cln_source_defilamma_bridges_history_tokens` AS d
    WHERE symbol IS NOT NULL AND usd_value > 0 AND tx_type= "withdrawal"
    GROUP BY 1, 2, 3,4
),
net_flow AS (
    SELECT
        COALESCE(i.date, o.date) AS date,
        COALESCE(i.chain, o.chain) AS chain,
        COALESCE(i.bridge, o.bridge) AS bridge,
        COALESCE(i.asset, o.asset) AS asset,
        i.inflow,
        o.outflow,
        COALESCE(i.inflow, 0) - COALESCE(o.outflow, 0) AS net_amount,
        100 - ABS((COALESCE(i.inflow, 0) - COALESCE(o.outflow, 0)) / NULLIF((COALESCE(i.inflow, 0) + COALESCE(o.outflow, 0)), 0)) * 100 AS percent_netted
    FROM inflow i
    FULL OUTER JOIN outflow o ON i.date = o.date AND i.chain = o.chain AND i.bridge = o.bridge
)

SELECT * FROM net_flow

-- windowed_net_flow AS (
--     SELECT
--         date,
--         chain,
--         bridge,
--         net_amount,
--         percent_netted,
--         AVG(net_amount) OVER (PARTITION BY date) AS avg_net_amount_by_date,
--         AVG(net_amount) OVER (PARTITION BY chain) AS avg_net_amount_by_chain,
--         AVG(net_amount) OVER (PARTITION BY bridge) AS avg_net_amount_by_bridge,
--         AVG(percent_netted) OVER (PARTITION BY date) AS avg_percent_netted_by_date,
--         AVG(percent_netted) OVER (PARTITION BY chain) AS avg_percent_netted_by_chain,
--         AVG(percent_netted) OVER (PARTITION BY bridge) AS avg_percent_netted_by_bridge
--     FROM net_flow
-- )
-- SELECT 
--     date,
--     chain,
--     bridge,
--     avg_net_amount_by_date,
--     avg_net_amount_by_chain,
--     avg_net_amount_by_bridge,
--     avg_percent_netted_by_date,
--     avg_percent_netted_by_chain,
--     avg_percent_netted_by_bridge
-- FROM windowed_net_flow

