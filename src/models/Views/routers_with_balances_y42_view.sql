WITH MaxTimestamp AS (
    SELECT
        Canonical_Id,
        MAX(Timestamp) AS Max_Timestamp
    FROM {{ source('Cartographer', 'public_asset_prices') }}
    GROUP BY Canonical_Id
)

SELECT
    Routers.Address,
    Asset_Balances.Asset_Canonical_Id,
    Asset_Balances.Asset_Domain,
    Asset_Balances.Router_Address,
    Asset_Balances.Balance,
    Assets.Local,
    Assets.Adopted,
    Assets.Canonical_Id,
    Assets.Canonical_Domain,
    Assets.Domain,
    Assets.Key,
    Assets.Id,
    Asset_Balances.Fees_Earned,
    Asset_Balances.Locked,
    Asset_Balances.Supplied,
    Asset_Balances.Removed,
    Assets.`decimal`,
    Assets.Adopted_Decimal,
    COALESCE(Asset_Prices.Price, 0) AS Asset_Usd_Price,
    Asset_Prices.Price * (Asset_Balances.Balance / POW(10, Assets.`decimal`)) AS Balance_Usd,
    Asset_Prices.Price * (Asset_Balances.Fees_Earned / POW(10, Assets.`decimal`)) AS Fee_Earned_Usd,
    Asset_Prices.Price * (Asset_Balances.Locked / POW(10, Assets.`decimal`)) AS Locked_Usd,
    Asset_Prices.Price * (Asset_Balances.Supplied / POW(10, Assets.`decimal`)) AS Supplied_Usd,
    Asset_Prices.Price * (Asset_Balances.Removed / POW(10, Assets.`decimal`)) AS Removed_Usd
FROM {{ source('Cartographer', 'public_routers') }} AS Routers
LEFT JOIN
    {{ source('Cartographer', 'public_asset_balances') }} AS Asset_Balances
    ON Routers.Address = Asset_Balances.Router_Address
LEFT JOIN
    {{ source('Cartographer', 'public_assets') }} AS Assets
    ON Asset_Balances.Asset_Canonical_Id = Assets.Canonical_Id AND Asset_Balances.Asset_Domain = Assets.Domain
LEFT JOIN MaxTimestamp ON Assets.Canonical_Id = MaxTimestamp.Canonical_Id
LEFT JOIN
    {{ source('Cartographer', 'public_asset_prices') }} AS Asset_Prices
    ON Assets.Canonical_Id = Asset_Prices.Canonical_Id AND MaxTimestamp.Max_Timestamp = Asset_Prices.Timestamp
