WITH connext_tokens AS (
    SELECT DISTINCT
        ct.token_address,
        ct.token_name,
        ct.is_xerc20
    FROM {{ source('bq_stage', 'stage_connext_tokens') }} AS ct
),

assets_tr AS (
    SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY domain, id ORDER BY adopted_decimal desc) AS rn
  FROM {{ source('Cartographer', 'public_assets') }}
    
),

assets_fix AS (
    SELECT * FROM assets_tr WHERE rn = 1
),

fj AS (
    SELECT *
    FROM {{ source('Cartographer', 'public_assets') }} AS pa
    FULL JOIN
        {{ source('github_tokens_parser', 'github_parser_tokens') }} AS gtp
        ON pa.`domain` = gtp.`domainid` AND pa.`id` = gtp.`assetid`
),

origin_unmapped AS (
    SELECT DISTINCT
        t.`origin_transacting_asset`,
        t.`origin_domain`
    FROM
        {{ ref('transfers') }} AS t LEFT JOIN
        {{ source('Cartographer', 'public_assets') }} AS pa
        ON t.`origin_transacting_asset` = pa.`id` AND t.`origin_domain` = pa.`domain`
    WHERE pa.id IS NULL
),

destination_unmapped AS (
    SELECT DISTINCT
        t.`destination_transacting_asset`,
        t.`destination_domain`
    FROM
        {{ ref('transfers') }} AS t LEFT JOIN
        {{ source('Cartographer', 'public_assets') }} AS pa
        ON t.`destination_transacting_asset` = pa.`id` AND t.`destination_domain` = pa.`domain`
    WHERE pa.id IS NULL
),

destination_mapped AS (
    SELECT *
    FROM destination_unmapped AS dum
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_tokens') }} AS gtp
        ON dum.`destination_domain` = gtp.`domainid` AND dum.`destination_transacting_asset` = gtp.`assetid`
    WHERE `destination_transacting_asset` IS NOT NULL
),

origin_mapped AS (
    SELECT *
    FROM origin_unmapped AS dum
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_tokens') }} AS gtp
        ON dum.`origin_domain` = gtp.`domainid` AND dum.`origin_transacting_asset` = gtp.`assetid`
),

combinations AS (
    SELECT DISTINCT
        domain,
        asset
    FROM (
        SELECT
            origin_domain AS domain,
            origin_transacting_asset AS asset
        FROM {{ ref('transfers') }}

        UNION ALL

        SELECT
            destination_domain AS domain,
            destination_transacting_asset AS asset
        FROM {{ ref('transfers') }}
    ) AS combined
    WHERE asset IS NOT NULL
),

mapping AS (
    SELECT
        t.*,
        dm.name AS domain_name,
        COALESCE(tam.assetid_symbol, LOWER(cc.`token_name`)) AS asset_name,
        COALESCE(CAST(tam.assetid_decimals AS NUMERIC), pa.`decimal`) AS asset_decimals,
        tam.assetid_mainnetequivalent AS mainnet_equivalent,
        CASE
            WHEN
                pa.id = pa.`local`
                AND STARTS_WITH(COALESCE(tam.assetid_symbol, LOWER(cc.`token_name`)), 'next')
                AND CAST(cc.is_xerc20 AS BOOLEAN) IS FALSE
                THEN 'local'
            WHEN
                pa.id = pa.`adopted` AND NOT STARTS_WITH(COALESCE(tam.assetid_symbol, LOWER(cc.`token_name`)), 'next')
                THEN 'adopted'
            WHEN
                pa.id IS NULL
                AND STARTS_WITH(COALESCE(tam.assetid_symbol, LOWER(cc.`token_name`)), 'next')
                AND CAST(cc.is_xerc20 AS BOOLEAN) IS FALSE
                THEN 'local'
            WHEN
                pa.id IS NULL
                AND (
                    NOT STARTS_WITH(COALESCE(tam.assetid_symbol, LOWER(cc.`token_name`)), 'next')
                    OR CAST(cc.is_xerc20 AS BOOLEAN) IS TRUE
                )
                THEN 'adopted'
        --ELSE "adopted"
        END AS asset_type,
        CAST(cc.`is_xerc20` AS BOOLEAN) AS is_xerc20,
        pa.* EXCEPT (domain)
    FROM combinations AS t
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_chains') }} AS dm ON t.`domain` = dm.`domainid`
    --LEFT JOIN {{ source('github_tokens_parser', 'github_parser_chains') }} AS ddm ON t.`destination_domain` = ddm.`domainid`
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_tokens') }} AS tam ON t.`asset` = tam.`assetid` AND t.`domain` = tam.`domainid`
    --LEFT JOIN {{ source('github_tokens_parser', 'github_parser_tokens') }} AS dtam ON t.`destination_transacting_asset` = dtam.`assetid` AND t.`destination_domain` = dtam.`domainid`
    LEFT JOIN connext_tokens AS cc ON t.asset = cc.token_address
    LEFT JOIN (SELECT DISTINCT * FROM assets_fix) AS pa ON t.`domain` = pa.`domain` AND t.`asset` = pa.`id`
    --LEFT JOIN connext_tokens AS cc_destination ON t.destination_transacting_asset = cc_destination.token_address
    --WHERE tam.`assetid_decimals` is NOT NULL AND tam.`assetid_decimals` != `asset_decimals`
    ORDER BY t.`domain`, t.`asset`
)

select * from mapping --WHERE asset in ('0x68deff5c5c132467316522b0a66436573abba80e', '0xe974b9b31dbff4369b94a1bab5e228f35ed44125', '0x27b58d226fe8f792730a795764945cf146815aa7')


--SELECT domain, asset, count(*) as count FROM mapping group by 1,2 order by (count(*)) desc

--SELECT domain, id, count(*) as co FROM {{ source('Cartographer', 'public_assets') }} group by 1,2 order by (count(*)) desc

--SELECT * FROM {{ source('Cartographer', 'public_assets') }} where id in ('0x68deff5c5c132467316522b0a66436573abba80e', '0xe974b9b31dbff4369b94a1bab5e228f35ed44125', '0x27b58d226fe8f792730a795764945cf146815aa7')

--SELECT * FROM combinations where asset in ('0x68deff5c5c132467316522b0a66436573abba80e', '0xe974b9b31dbff4369b94a1bab5e228f35ed44125', '0x27b58d226fe8f792730a795764945cf146815aa7')

--combinations
--SELECT * FROM {{ source('Cartographer', 'public_assets') }} WHERE `adopted` != id AND `local` != id

--distinct canonical_id, asset_name FROM mapping order by canonical_id
--WHERE `assetid_decimals` is NOT NULL AND CAST(`assetid_decimals` AS Numeric) != `asset_decimals`
--SELECT * FROM {{ source('bq_stage', 'stage_connext_tokens') }} --connext_tokens ORDER BY `token_name`


--WHERE `destination_transacting_asset` is NOT NULL
/*
ttt AS (
    SELECT
    COALESCE(odm.name,t.origin_domain) AS origin_domain_name,
    COALESCE(ddm.name,t.`destination_domain`) AS destination_domain_name,
    COALESCE(otam.`assetid_symbol`, dtam.`assetid_symbol`, cc_origin.token_name, t.`origin_transacting_asset`)  AS origin_asset_name,
    COALESCE(otam.`assetid_decimals`, NULL) AS origin_asset_decimals,
    COALESCE(dtam.`assetid_symbol`, otam.`assetid_symbol`, cc_destination.token_name, t.`destination_transacting_asset`) AS destination_asset_name,
    COALESCE(dtam.`assetid_decimals`, NULL) AS destination_asset_decimals,
    CAST(cc_origin.is_xerc20 AS BOOL) AS is_origin_asset_xerc20,
    CAST(cc_destination.is_xerc20 AS BOOL) AS is_destination_asset_xerc20,
    CASE WHEN LOWER(t.xcall_caller) != LOWER(t.xcall_tx_origin) THEN 'Contract' ELSE 'EOA' END AS caller_type,
    --t.destination_transacting_amount,
    cc.* EXCEPT (xcall_caller, rn),
    t.*
    FROM {{ ref('transfers') }} AS t
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_chains') }} AS odm ON t.`origin_domain` = odm.`domainid`
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_chains') }} AS ddm ON t.`destination_domain` = ddm.`domainid`
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_tokens') }} AS otam ON t.`origin_transacting_asset` = otam.`assetid` AND t.`origin_domain` = otam.`domainid`
    LEFT JOIN {{ source('github_tokens_parser', 'github_parser_tokens') }} AS dtam ON t.`destination_transacting_asset` = dtam.`assetid`AND t.`destination_domain` = dtam.`domainid`
    LEFT JOIN connext_tokens AS cc_origin ON t.origin_transacting_asset = cc_origin.token_address
    LEFT JOIN connext_tokens AS cc_destination ON t.destination_transacting_asset = cc_destination.token_address
*/
