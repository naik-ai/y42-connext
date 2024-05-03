SELECT
    slippage,
    CAST(amount AS Numeric) / POWER(10, 18) AS amount_eth,
    CASE
        WHEN domain_id = '6648936' THEN 'Ethereum'
        WHEN domain_id = '1869640809' THEN 'Optimism'
        WHEN domain_id = '6450786' THEN 'BNB'
        WHEN domain_id = '6778479' THEN 'Gnosis'
        WHEN domain_id = '1886350457' THEN 'Polygon'
        WHEN domain_id = '1634886255' THEN 'Arbitrum One'
        WHEN domain_id = '1818848877' THEN 'Linea'
        WHEN domain_id = '1835365481' THEN 'Metis'
        WHEN domain_id = '1650553709' THEN 'Base'
        WHEN domain_id = '1836016741' THEN 'Mode'
        ELSE
            domain_id
    END
        AS chain_name,
    FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp) AS timestamp_time
FROM
    {{ ref('slippage_historical') }}
