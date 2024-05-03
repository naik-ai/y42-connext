SELECT
    buyer,
    CASE
        WHEN domain = '6648936' THEN 'Ethereum'
        WHEN domain = '1869640809' THEN 'Optimism'
        WHEN domain = '6450786' THEN 'BNB'
        WHEN domain = '6778479' THEN 'Gnosis'
        WHEN domain = '1886350457' THEN 'Polygon'
        WHEN domain = '1634886255' THEN 'Arbitrum One'
        WHEN domain = '1818848877' THEN 'Linea'
        WHEN domain = '1835365481' THEN 'Metis'
        WHEN domain = '1650553709' THEN 'Base'
        WHEN domain = '1836016741' THEN 'Mode'
        ELSE
            domain
    END
        AS chain_name,
    FORMAT_TIMESTAMP('%Y-%m-%d', TIMESTAMP_SECONDS(timestamp)) AS swap_date,
    SUM(tokens_bought) AS eth_volume,
    COUNT(*) AS count
FROM
    {{ ref('stableswap_exchanges_y42_dedup') }}
WHERE
    (
        domain = '1634886255'
        OR domain = '6450786'
        OR domain = '1818848877'
        OR domain = '1836016741'
    )
    AND timestamp > 1709190000
    AND pool_id = '0x12acadfa38ab02479ae587196a9043ee4d8bf52fcb96b7f8d2ba240f03bcd08a'
    AND bought_id = 1
    AND buyer = '0xf9d64d54d32ee2bdceaabfa60c4c438e224427d0'
GROUP BY
    buyer, chain_name, swap_date
