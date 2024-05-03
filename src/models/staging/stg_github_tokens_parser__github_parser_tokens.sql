WITH

source AS (
	SELECT * FROM {{ source('github_tokens_parser', 'github_parser_tokens') }}
),

renamed AS (
	SELECT
		name,
		chainid,
		domainid,
		confirmations,
		shortname,
		nativecurrency,
		type,
		rpc,
		subgraphs,
		subgraph,
		analyticssubgraph,
		faucets,
		gasstations,
		explorers,
		gasestimates,
		watchtower,
		network,
		networkid,
		infourl,
		chain,
		nativecurrency_name,
		nativecurrency_symbol,
		nativecurrency_decimals,
		assetid_symbol,
		assetid_mainnetequivalent,
		assetid_decimals,
		assetid_coingeckoid,
		assetid,
		assetid_name,
		assetid_issingleminter
	FROM source
)

SELECT * FROM renamed
