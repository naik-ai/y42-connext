SELECT
    *,
    CASE
        WHEN origin_domain = '6648936' THEN 'Ethereum'
        WHEN origin_domain = '1869640809' THEN 'Optimism'
        WHEN origin_domain = '6450786' THEN 'BNB'
        WHEN origin_domain = '6778479' THEN 'Gnosis'
        WHEN origin_domain = '1886350457' THEN 'Polygon'
        WHEN origin_domain = '1634886255' THEN 'Arbitrum One'
        WHEN origin_domain = '1818848877' THEN 'Linea'
        WHEN origin_domain = '1835365481' THEN 'Metis'
        WHEN origin_domain = '1650553709' THEN 'Base'
        WHEN origin_domain = '1836016741' THEN 'Mode'
        ELSE origin_domain
    END AS origin_chain_name,
    CASE
        WHEN destination_domain = '6648936' THEN 'Ethereum'
        WHEN destination_domain = '1869640809' THEN 'Optimism'
        WHEN destination_domain = '6450786' THEN 'BNB'
        WHEN destination_domain = '6778479' THEN 'Gnosis'
        WHEN destination_domain = '1886350457' THEN 'Polygon'
        WHEN destination_domain = '1634886255' THEN 'Arbitrum One'
        WHEN destination_domain = '1818848877' THEN 'Linea'
        WHEN destination_domain = '1835365481' THEN 'Metis'
        WHEN destination_domain = '1650553709' THEN 'Base'
        WHEN destination_domain = '1836016741' THEN 'Mode'
        ELSE destination_domain
    END AS dest_chain_name,
    CASE
        WHEN destination_transacting_asset = '0xfe67a4450907459c3e1fff623aa927dd4e28c67a' THEN 'NEXT'
        WHEN destination_transacting_asset = '0x58b9cb810a68a7f3e1e4f8cb45d1b9b3c79705e8' THEN 'NEXT'
        WHEN destination_transacting_asset = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' THEN 'USDC'
        WHEN destination_transacting_asset = '0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d' THEN 'USDC'
        WHEN destination_transacting_asset = '0x2791bca1f2de4661ed88a30c99a7a9449aa84174' THEN 'USDC'
        WHEN destination_transacting_asset = '0x7f5c764cbc14f9669b88837ca1490cca17c31607' THEN 'USDC'
        WHEN destination_transacting_asset = '0xff970a61a04b1ca14834a43f5de4533ebddb5cc8' THEN 'USDC'
        WHEN destination_transacting_asset = '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' THEN 'USDC'
        WHEN destination_transacting_asset = '0x176211869ca2b568f2a7d4ee941e073a821ee1ff' THEN 'USDC'
        WHEN destination_transacting_asset = 'x833589fcd6edb6e08f4c7c32d4f71b54bda02913' THEN 'USDC'
        WHEN destination_transacting_asset = '0xdac17f958d2ee523a2206206994597c13d831ec7' THEN 'USDT'
        WHEN destination_transacting_asset = '0x55d398326f99059ff775485246999027b3197955' THEN 'USDT'
        WHEN destination_transacting_asset = '0xc2132d05d31c914a87c6611c10748aeb04b58e8f' THEN 'USDT'
        WHEN destination_transacting_asset = '0x94b008aa00579c1307b0ef2c499ad98a8ce58e58' THEN 'USDT'
        WHEN destination_transacting_asset = '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9' THEN 'USDT'
        WHEN destination_transacting_asset = '0x4ecaba5870353805a9f068101a40e0f32ed605c6' THEN 'USDT'
        WHEN destination_transacting_asset = '0xa219439258ca9da29e9cc4ce5596924745e12b93' THEN 'USDT'
        WHEN destination_transacting_asset = '0x6b175474e89094c44da98b954eedeac495271d0f' THEN 'DAI'
        WHEN destination_transacting_asset = '0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3' THEN 'DAI'
        WHEN destination_transacting_asset = '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063' THEN 'DAI'
        WHEN destination_transacting_asset = '0xda10009cbd5d07dd0cecc66161fc93d7c9000da1' THEN 'DAI'
        WHEN destination_transacting_asset = '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d' THEN 'DAI'
        WHEN destination_transacting_asset = '0x4af15ec2a0bd43db75dd04e62faa3b8ef36b00d5' THEN 'DAI'
        WHEN destination_transacting_asset = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2' THEN 'ETH'
        WHEN destination_transacting_asset = '0x2170ed0880ac9a755fd29b2688956bd959f933f8' THEN 'ETH'
        WHEN destination_transacting_asset = '0x7ceb23fd6bc0add59e62ac25578270cff1b9f619' THEN 'ETH'
        WHEN destination_transacting_asset = '0x4200000000000000000000000000000000000006' THEN 'ETH'
        WHEN destination_transacting_asset = '0x82af49447d8a07e3bd95bd0d56f35241523fbab1' THEN 'ETH'
        WHEN destination_transacting_asset = '0x6a023ccd1ff6f2045c3309768ead9e68f978f6e1' THEN 'ETH'
        WHEN destination_transacting_asset = '0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f' THEN 'ETH'

        WHEN destination_transacting_asset = '0x420000000000000000000000000000000000000a' THEN 'ETH'
        WHEN destination_transacting_asset = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' THEN 'USDC'
        WHEN destination_transacting_asset = '0xbd18f9be5675a9658335e6b7e79d9d9b394ac043' THEN 'ALCX'
        WHEN destination_transacting_asset = '0xbb06dca3ae6887fabf931640f67cab3e3a16f4dc' THEN 'USDT'
        WHEN destination_transacting_asset = '0xea32a96608495e54156ae48931a7c20f0dcc1a21' THEN 'USDC'

        WHEN destination_transacting_asset = '0x44709a920fccf795fbc57baa433cc3dd53c44dbe' THEN 'RADAR'
        WHEN destination_transacting_asset = '0x489580eb70a50515296ef31e8179ff3e77e24965' THEN 'RADAR'
        WHEN destination_transacting_asset = '0xdcb72ae4d5dc6ae274461d57e65db8d50d0a33ad' THEN 'RADAR'
        WHEN destination_transacting_asset = '0xdbdb4d16eda451d0503b854cf79d55697f90c8df' THEN 'ALCX'
        WHEN destination_transacting_asset = '0x27b58d226fe8f792730a795764945cf146815aa7' THEN 'ALCX'
        WHEN destination_transacting_asset = '0xe974b9b31dbff4369b94a1bab5e228f35ed44125' THEN 'ALCX'
        WHEN destination_transacting_asset = '0xbc6da0fe9ad5f3b0d58160288917aa56653660e9' THEN 'alUSD'
        WHEN destination_transacting_asset = '0xcb8fa9a76b8e203d8c3797bf438d8fb81ea3326a' THEN 'alUSD'
        WHEN destination_transacting_asset = '0x0100546f2cd4c9d97f798ffc9755e47865ff7ee6' THEN 'alETH'
        WHEN destination_transacting_asset = '0x3e29d3a9316dab217754d13b28646b76607c5f04' THEN 'alETH'

        WHEN destination_transacting_asset = '0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44' THEN 'KP3R'
        WHEN destination_transacting_asset = '0xb3de3929c3be8a1fa446f27d1b549dd9d5c313e0' THEN 'KP3R'
        WHEN destination_transacting_asset = '0x725db429f0ff5a3df5f41fca8676cf9dd1c6b3f0' THEN 'KP3R'
        WHEN destination_transacting_asset = '0xa83ad51c99bb40995f9292c9a436046ab7578caf' THEN 'KP3R'
        WHEN destination_transacting_asset = '0xa83ad51c99bb40995f9292c9a436046ab7578caf' THEN 'KP3R'
        WHEN destination_transacting_asset = '0x3f6740b5898c5d3650ec6eace9a649ac791e44d7' THEN 'KLP'
        WHEN destination_transacting_asset = '0xf813835326f1c606892a36f96b6cdd18d6d87de9' THEN 'KLP'
        WHEN destination_transacting_asset = '0x381bc51bb203c5940a398622be918c876cb0f035' THEN 'KLP'
        WHEN destination_transacting_asset = '0x87a93a942d10b6cc061a952c3a1213d52044be97' THEN 'KLP'
        WHEN destination_transacting_asset = '0xa411c9aa00e020e4f88bc19996d29c5b7adb4acf' THEN 'XOC'
        WHEN destination_transacting_asset = '0x772fce4b8e88bd19e86dc92428d242704ac480a0' THEN 'P8'
        WHEN destination_transacting_asset = '0x2bf2ba13735160624a0feae98f6ac8f70885ea61' THEN 'FRACTION'
        WHEN destination_transacting_asset = '0xbd80cfa9d93a87d1bb895f810ea348e496611cd4' THEN 'FRACTION'
        WHEN destination_transacting_asset = '0xd8e2d95c8614f28169757cd6445a71c291dec5bf' THEN 'GRUMPYCAT'
        WHEN destination_transacting_asset = '0x3b350f202473932411772c8cb76db7975f42397e' THEN 'GRUMPYCAT'
        WHEN destination_transacting_asset = '0xe06bd4f5aac8d0aa337d13ec88db6defc6eaeefe' THEN 'IXT'
        WHEN destination_transacting_asset = '0x8b04bf3358b88e3630aa64c1c76ff3b6c699c6a7' THEN 'IXT'
        WHEN destination_transacting_asset = '0xc6dddb5bc6e61e0841c54f3e723ae1f3a807260b' THEN 'URUS'
        WHEN destination_transacting_asset = '0x9e1170c12fddd3b00fec42ddf4c942565d9be577' THEN 'SPACE'
        WHEN destination_transacting_asset = '0x1d1498166ddceee616a6d99868e1e0677300056f' THEN 'SPACE'
        WHEN destination_transacting_asset = '0x627fee87d0d9d2c55098a06ac805db8f98b158aa' THEN 'oLIT'
        WHEN destination_transacting_asset = '0x24f21b1864d4747a5c99045c96da11dbfda378f7' THEN 'oLIT'
        WHEN destination_transacting_asset = '0x0d505c03d30e65f6e9b4ef88855a47a89e4b7676' THEN 'ZOOMER'
        WHEN destination_transacting_asset = '0xb962150760f9a3bb00e3e9cf48297ee20ada4a33' THEN 'ZOOMER'
        WHEN destination_transacting_asset = '0x68deff5c5c132467316522b0a66436573abba80e' THEN 'ZOOMER'
        WHEN destination_transacting_asset = '0x2416092f143378750bb29b79ed961ab195cceea5' THEN 'ezETH'
        ELSE destination_transacting_asset
    END AS destination_symbol,

    CASE
        WHEN origin_transacting_asset = '0xfe67a4450907459c3e1fff623aa927dd4e28c67a' THEN 'NEXT'
        WHEN origin_transacting_asset = '0x58b9cb810a68a7f3e1e4f8cb45d1b9b3c79705e8' THEN 'NEXT'
        WHEN origin_transacting_asset = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' THEN 'USDC'
        WHEN origin_transacting_asset = '0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d' THEN 'USDC'
        WHEN origin_transacting_asset = '0x2791bca1f2de4661ed88a30c99a7a9449aa84174' THEN 'USDC'
        WHEN origin_transacting_asset = '0x7f5c764cbc14f9669b88837ca1490cca17c31607' THEN 'USDC'
        WHEN origin_transacting_asset = '0xff970a61a04b1ca14834a43f5de4533ebddb5cc8' THEN 'USDC'
        WHEN origin_transacting_asset = '0xddafbb505ad214d7b80b1f830fccc89b60fb7a83' THEN 'USDC'
        WHEN origin_transacting_asset = '0x176211869ca2b568f2a7d4ee941e073a821ee1ff' THEN 'USDC'
        WHEN origin_transacting_asset = '0xdac17f958d2ee523a2206206994597c13d831ec7' THEN 'USDT'
        WHEN origin_transacting_asset = '0x55d398326f99059ff775485246999027b3197955' THEN 'USDT'
        WHEN origin_transacting_asset = '0xc2132d05d31c914a87c6611c10748aeb04b58e8f' THEN 'USDT'
        WHEN origin_transacting_asset = '0x94b008aa00579c1307b0ef2c499ad98a8ce58e58' THEN 'USDT'
        WHEN origin_transacting_asset = '0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9' THEN 'USDT'
        WHEN origin_transacting_asset = '0x4ecaba5870353805a9f068101a40e0f32ed605c6' THEN 'USDT'
        WHEN origin_transacting_asset = '0xa219439258ca9da29e9cc4ce5596924745e12b93' THEN 'USDT'
        WHEN origin_transacting_asset = '0x2fd7e61033b3904c65aa9a9b83dcd344fa19ffd2' THEN 'USDT'


        WHEN origin_transacting_asset = '0x6b175474e89094c44da98b954eedeac495271d0f' THEN 'DAI'
        WHEN origin_transacting_asset = '0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3' THEN 'DAI'
        WHEN origin_transacting_asset = '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063' THEN 'DAI'
        WHEN origin_transacting_asset = '0xda10009cbd5d07dd0cecc66161fc93d7c9000da1' THEN 'DAI'
        WHEN origin_transacting_asset = '0xe91d153e0b41518a2ce8dd3d7944fa863463a97d' THEN 'DAI'
        WHEN origin_transacting_asset = '0x4af15ec2a0bd43db75dd04e62faa3b8ef36b00d5' THEN 'DAI'
        WHEN origin_transacting_asset = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2' THEN 'ETH'
        WHEN origin_transacting_asset = '0x2170ed0880ac9a755fd29b2688956bd959f933f8' THEN 'ETH'
        WHEN origin_transacting_asset = '0x7ceb23fd6bc0add59e62ac25578270cff1b9f619' THEN 'ETH'
        WHEN origin_transacting_asset = '0x4200000000000000000000000000000000000006' THEN 'ETH'
        WHEN origin_transacting_asset = '0x82af49447d8a07e3bd95bd0d56f35241523fbab1' THEN 'ETH'
        WHEN origin_transacting_asset = '0x6a023ccd1ff6f2045c3309768ead9e68f978f6e1' THEN 'ETH'
        WHEN origin_transacting_asset = '0xe5d7c2a44ffddf6b295a15c148167daaaf5cf34f' THEN 'ETH'
        WHEN origin_transacting_asset = '0x2983bf5c334743aa6657ad70a55041d720d225db' THEN 'ETH'

        WHEN origin_transacting_asset = '0x420000000000000000000000000000000000000a' THEN 'ETH'
        WHEN origin_transacting_asset = '0x4cbb28fa12264cd8e87c62f4e1d9f5955ce67d20' THEN 'USDT'
        WHEN origin_transacting_asset = '0xbb06dca3ae6887fabf931640f67cab3e3a16f4dc' THEN 'USDT'
        WHEN origin_transacting_asset = '0x538e2ddbfdf476d24ccb1477a518a82c9ea81326' THEN 'ETH'
        WHEN origin_transacting_asset = '0x420000000000000000000000000000000000000a' THEN 'ETH'
        WHEN origin_transacting_asset = '0x5e7d83da751f4c9694b13af351b30ac108f32c38' THEN 'USDC'
        WHEN origin_transacting_asset = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913' THEN 'USDC'


        WHEN origin_transacting_asset = '0x86a343bcf17d79c475d300eed35f0145f137d0c9' THEN 'DAI'
        WHEN origin_transacting_asset = '0xa9cb51c666d2af451d87442be50747b31bb7d805' THEN 'ETH'
        WHEN origin_transacting_asset = '0xbad5b3c68f855eaece68203312fd88ad3d365e50' THEN 'ETH'
        WHEN origin_transacting_asset = '0x2983bf5c334743aa6657ad70a55041d720d225db' THEN 'ETH'

        WHEN origin_transacting_asset = '0xd64bd028b560bbfc732ea18f282c64b86f3468e0' THEN 'DAI'
        WHEN origin_transacting_asset = '0xe221c5a2a8348f12dcb2b0e88693522ebad2690f' THEN 'USDT'
        WHEN origin_transacting_asset = '0xea32a96608495e54156ae48931a7c20f0dcc1a21' THEN 'USDC'
        WHEN origin_transacting_asset = '0xfde99b3b3fbb69553d7dae105ef34ba4fe971190' THEN 'DAI'



        WHEN origin_transacting_asset = '0x44709a920fccf795fbc57baa433cc3dd53c44dbe' THEN 'RADAR'
        WHEN origin_transacting_asset = '0x489580eb70a50515296ef31e8179ff3e77e24965' THEN 'RADAR'
        WHEN origin_transacting_asset = '0xdcb72ae4d5dc6ae274461d57e65db8d50d0a33ad' THEN 'RADAR'
        WHEN origin_transacting_asset = '0xdbdb4d16eda451d0503b854cf79d55697f90c8df' THEN 'ALCX'
        WHEN origin_transacting_asset = '0x27b58d226fe8f792730a795764945cf146815aa7' THEN 'ALCX'
        WHEN origin_transacting_asset = '0xe974b9b31dbff4369b94a1bab5e228f35ed44125' THEN 'ALCX'
        WHEN origin_transacting_asset = '0xbc6da0fe9ad5f3b0d58160288917aa56653660e9' THEN 'alUSD'
        WHEN origin_transacting_asset = '0xcb8fa9a76b8e203d8c3797bf438d8fb81ea3326a' THEN 'alUSD'
        WHEN origin_transacting_asset = '0x0100546f2cd4c9d97f798ffc9755e47865ff7ee6' THEN 'alETH'
        WHEN origin_transacting_asset = '0x3e29d3a9316dab217754d13b28646b76607c5f04' THEN 'alETH'

        WHEN origin_transacting_asset = '0x303241e2b3b4aed0bb0f8623e7442368fed8faf3' THEN 'alETH'
        WHEN origin_transacting_asset = '0x49000f5e208349d2fa678263418e21365208e498' THEN 'alUSD'


        WHEN origin_transacting_asset = '0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44' THEN 'KP3R'
        WHEN origin_transacting_asset = '0xb3de3929c3be8a1fa446f27d1b549dd9d5c313e0' THEN 'KP3R'
        WHEN origin_transacting_asset = '0x725db429f0ff5a3df5f41fca8676cf9dd1c6b3f0' THEN 'KP3R'
        WHEN origin_transacting_asset = '0xa83ad51c99bb40995f9292c9a436046ab7578caf' THEN 'KP3R'
        WHEN origin_transacting_asset = '0xa83ad51c99bb40995f9292c9a436046ab7578caf' THEN 'KP3R'
        WHEN origin_transacting_asset = '0x3f6740b5898c5d3650ec6eace9a649ac791e44d7' THEN 'KLP'
        WHEN origin_transacting_asset = '0xf813835326f1c606892a36f96b6cdd18d6d87de9' THEN 'KLP'
        WHEN origin_transacting_asset = '0x381bc51bb203c5940a398622be918c876cb0f035' THEN 'KLP'
        WHEN origin_transacting_asset = '0x87a93a942d10b6cc061a952c3a1213d52044be97' THEN 'KLP'
        WHEN origin_transacting_asset = '0xa411c9aa00e020e4f88bc19996d29c5b7adb4acf' THEN 'XOC'
        WHEN origin_transacting_asset = '0x772fce4b8e88bd19e86dc92428d242704ac480a0' THEN 'P8'
        WHEN origin_transacting_asset = '0x2bf2ba13735160624a0feae98f6ac8f70885ea61' THEN 'FRACTION'
        WHEN origin_transacting_asset = '0xbd80cfa9d93a87d1bb895f810ea348e496611cd4' THEN 'FRACTION'
        WHEN origin_transacting_asset = '0xd8e2d95c8614f28169757cd6445a71c291dec5bf' THEN 'GRUMPYCAT'
        WHEN origin_transacting_asset = '0x3b350f202473932411772c8cb76db7975f42397e' THEN 'GRUMPYCAT'
        WHEN origin_transacting_asset = '0xe06bd4f5aac8d0aa337d13ec88db6defc6eaeefe' THEN 'IXT'
        WHEN origin_transacting_asset = '0x8b04bf3358b88e3630aa64c1c76ff3b6c699c6a7' THEN 'IXT'
        WHEN origin_transacting_asset = '0xc6dddb5bc6e61e0841c54f3e723ae1f3a807260b' THEN 'URUS'
        WHEN origin_transacting_asset = '0x9e1170c12fddd3b00fec42ddf4c942565d9be577' THEN 'SPACE'
        WHEN origin_transacting_asset = '0x1d1498166ddceee616a6d99868e1e0677300056f' THEN 'SPACE'
        WHEN origin_transacting_asset = '0x627fee87d0d9d2c55098a06ac805db8f98b158aa' THEN 'oLIT'
        WHEN origin_transacting_asset = '0x24f21b1864d4747a5c99045c96da11dbfda378f7' THEN 'oLIT'
        WHEN origin_transacting_asset = '0x0d505c03d30e65f6e9b4ef88855a47a89e4b7676' THEN 'ZOOMER'
        WHEN origin_transacting_asset = '0xb962150760f9a3bb00e3e9cf48297ee20ada4a33' THEN 'ZOOMER'
        WHEN origin_transacting_asset = '0x68deff5c5c132467316522b0a66436573abba80e' THEN 'ZOOMER'

        WHEN origin_transacting_asset = '0x2416092f143378750bb29b79ed961ab195cceea5' THEN 'ezETH'
        ELSE origin_transacting_asset
    END AS origin_symbol


FROM {{ ref('latency') }}
