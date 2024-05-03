/*SELECT *,   
CASE
        WHEN routers = '{0x9584eb0356a380b25d7ed2c14c54de58a25f2581}' THEN 'Mike Nai'
        WHEN routers = '{0xc4ae07f276768a3b74ae8c47bc108a2af0e40eba}' THEN 'P2P 2'
        WHEN routers = '{0xeca085906cb531bdf1f87efa85c5be46aa5c9d2c}' THEN 'Blocktech 2'
        WHEN routers = '{0x22831e4f21ce65b33ef45df0e212b5bebf130e5a}' THEN 'Blocktech 1'
        WHEN routers = '{0xbe7bc00382a50a711d037eaecad799bb8805dfa8}' THEN 'Minerva'
        WHEN routers = '{0x63Cda9C42db542bb91a7175E38673cFb00D402b0}' THEN 'Consensys Mesh'
        WHEN routers = '{0xf26c772c0ff3a6036bddabdaba22cf65eca9f97c}' THEN 'Connext'
        WHEN routers = '{0x97b9dcb1aa34fe5f12b728d9166ae353d1e7f5c4}' THEN 'P2P 1'
        WHEN routers = '{0x8cb19ce8eedf740389d428879a876a3b030b9170}' THEN 'BWare'
        WHEN routers = '{0x0e62f9fa1f9b3e49759dc94494f5bc37a83d1fad}' THEN 'Bazilik'
        WHEN routers = '{0x58507fed0cb11723dfb6848c92c59cf0bbeb9927}' THEN 'Hashquark'
        WHEN routers = '{0x7ce49752ffa7055622f444df3c69598748cb2e5f}' THEN 'Vault Staking'
        WHEN routers = '{0x33b2ad85f7dba818e719fb52095dc768e0ed93ec}' THEN 'Ethereal'
        WHEN routers = '{0x048a5EcC705C280b2248aefF88fd581AbbEB8587}' THEN 'Gnosis'
        WHEN routers = '{0x975574980a5Da77f5C90bC92431835D91B73669e}' THEN '01 Node'
        WHEN routers = '{0x6892d4D1f73A65B03063B7d78174dC6350Fcc406}' THEN 'Unagii'
        WHEN routers = '{0x32d63da9f776891843c90787cec54ada23abd4c2}' THEN 'Ingag'
        WHEN routers = '{0xfaab88015477493cfaa5dfaa533099c590876f21}' THEN 'Paradox'
    END AS router_name 
  
  */
WITH VolumeMetrics AS (
  SELECT
    tm.routers,
    tm.destination_asset_name,
    tm.`destination_transacting_asset`,
    tm.destination_domain_name,
    tm.`destination_domain`,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN usd_amount ELSE 0 END) AS usd_volume_1d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) THEN usd_amount ELSE 0 END) AS usd_volume_7d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN usd_amount ELSE 0 END) AS usd_volume_30d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN destination_amount ELSE 0 END) AS volume_1d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) THEN destination_amount ELSE 0 END) AS volume_7d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN destination_amount ELSE 0 END) AS volume_30d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AND status = 'CompletedFast' THEN usd_amount ELSE 0 END) AS usd_fast_volume_1d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND status = 'CompletedFast' THEN usd_amount ELSE 0 END) AS usd_fast_volume_7d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND status = 'CompletedFast' THEN usd_amount ELSE 0 END) AS usd_fast_volume_30d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) AND status = 'CompletedFast' THEN destination_amount ELSE 0 END) AS fast_volume_1d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND status = 'CompletedFast' THEN destination_amount ELSE 0 END) AS fast_volume_7d,
    SUM(CASE WHEN CAST(xcall_date AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND status = 'CompletedFast' THEN destination_amount ELSE 0 END) AS fast_volume_30d,
    MAX(CAST(xcall_date AS DATE)) AS last_transfer_date
    --COUNTIF(status = 'CompletedSlow') AS slow_txns
    FROM {{ ref('transfers_mapped') }} tm
    GROUP BY 
      1,2,3,4,5 
),
RouterMapping AS (
  SELECT 
  tm.*,
  rm.* EXCEPT(destination_domain_name)
  FROM VolumeMetrics tm
  LEFT JOIN {{ ref('routers_with_balances_mapped') }} rm
    ON tm.`destination_domain` = rm.`domain`
    AND tm.`destination_transacting_asset` = rm.`adopted`
    AND LOWER(
      REPLACE((SELECT ARRAY_AGG(unnested_value LIMIT 1)[OFFSET(0)]
      FROM UNNEST(JSON_EXTRACT_ARRAY(tm.`routers`)) AS unnested_value), '"', '')
    ) = LOWER(rm.`address`)
)

SELECT * from RouterMapping
