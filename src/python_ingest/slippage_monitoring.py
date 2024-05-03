from y42.v1.decorators import data_loader
import requests
import pandas as pd
import logging
import json
import re
import asyncio
from datetime import timezone, datetime

# use the @data_loader decorator to materialize an asset
# make sure you have a corresponding .yml table definition matching the function's name
# for more information check out our docs: https://docs.y42.dev/docs/sources/ingest-data-using-python

async def post_slipppage(domain, tokenAddress, endpoint, tokenIndexFrom, tokenIndexTo, amount):
    url = "https://sdk-server.mainnet.connext.ninja/calculateSwap"

    data = {
        "domainId": str(domain),
        "tokenAddress": str(tokenAddress),
        "tokenIndexFrom": str(tokenIndexFrom),
        "tokenIndexTo": str(tokenIndexTo),
        "amount": str(amount),
        "options": {
            "originProviderUrl": str(endpoint)
            }
    }

    # Convert the dictionary to a JSON string
    data_json = json.dumps(data)

    # Set the appropriate headers for JSON data
    headers = {'Content-Type': 'application/json'}

    # Sending the POST request
    #response = requests.post(url, data=data_json, headers=headers)

    # Checking the response

    try:
        response = await asyncio.to_thread(requests.post, url, headers=headers, data=data_json)
        response.raise_for_status()  # Raise an exception for HTTP errors (e.g., 404, 500)
        #data = response.json()
        data = response

        if response.status_code == 200:
            print("Success:", response.text)
            # Step 2: Parse the string as JSON
            data = json.loads(response.text)
            print(data['hex'])

            # Step 3: Extract the hexadecimal value
            hex_value = data['hex']

            # Step 4: Convert the hexadecimal value to an integer
            int_value = int(hex_value, 16)

            print(int_value)

            slippage = (1-int_value/amount)*100
            print(slippage)

            return slippage

        else:
            print("Error:", response.status_code, response.text)
    except requests.exceptions.RequestException as e:
            # Handle request-related errors (e.g., network issues, timeout)
        print(f"Error: {e}")
        return None

@data_loader
async def slippage_monitoring(context) -> pd.DataFrame:
    #httpx==0.26.0
    # Reference secrets if needed
    #all_secrets = context.secrets.all() # get all secrets saved within this space

    df = pd.DataFrame()

    assets = {
        "1634886255": #arb
        {
            "local": "0x2983bf5c334743Aa6657AD70A55041d720d225dB",
            "adopted": "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
            "endpoint": "https://arbitrum-mainnet.infura.io/v3/7e94bd49053945d7bdc52884c58d9fe5"
        },
        "6450786": #bnb
        {
            "local": "0xA9CB51C666D2AF451d87442Be50747B31BB7d805",
            "adopted": "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
            "endpoint": "https://bsc-mainnet.blastapi.io/46b64ddd-127f-4145-b72d-3770f3927c96"
        },
        "1818848877": #linea
        {
            "local": "0x0573ad07ca4f74757e5b2417bf225bebebcf66d9",
            "adopted": "0xe5d7c2a44fffdf6b295a15c148167daaaf5cf34f",
            "endpoint": "https://linea-mainnet.infura.io/v3/7e94bd49053945d7bdc52884c58d9fe5"
        },
        "1836016741": #mode
        {
            "local": "0x609aefb9fb2ee8f2fdad5dc48efb8fa4ee0e80fb",
            "adopted": "0x4200000000000000000000000000000000000006",
            "endpoint": "https://mode-mainnet.blastapi.io/46b64ddd-127f-4145-b72d-3770f3927c96"
        },
        "1650553709": #base
        {
            "local": "0xE08D4907b2C7aa5458aC86596b6D17B1feA03F7E",
            "adopted": "0x4200000000000000000000000000000000000006",
            "endpoint": "https://base-mainnet.blastapi.io/46b64ddd-127f-4145-b72d-3770f3927c96"
        }

    }
    timestamp = datetime.now(timezone.utc)
    amount_array = [10**17, 3*10**17, 10**18, 3*10**18, 10**19, 3*10**19, 10**20, 3*10**20, 10**21, 3*10**21]
    for amount in amount_array:

        #amount = 3*10**i

        for asset in assets:
            print(asset)
            print(assets[asset]['adopted'])
            print(amount)
            response = await post_slipppage(asset, assets[asset]['adopted'], assets[asset]['endpoint'], 1, 0, amount)
            combined_data = {
                "domain_id": asset,
                "asset": assets[asset]['adopted'],
                "amount": amount,
                "slippage": response,
                "timestamp": timestamp
            }
            temp_df = pd.DataFrame([combined_data])
            logging.info(combined_data)
            df = pd.concat([df, temp_df])

    print(df)
    df

    logging.info("Data fetched and DataFrame created successfully.")
    for column in df.columns:
        #df_expanded[column] = df_expanded[column].astype(str)
        if df[column].dtype == 'object':
            df[column]= df[column].fillna('')
            df[column] = df[column].astype(str)
    
    # to learn how to set up incremental updates and more
    # please visit https://docs.y42.dev/docs/sources/ingest-data-using-python
    return df

@data_loader
def router_monitoring(context) -> pd.DataFrame:
    # Reference secrets if needed
    #all_secrets = context.secrets.all() # get all secrets saved within this space
    #one_secret = context.secrets.get('<SECRET_NAME>') # get the value of a specific secret saved within this space

    # Your code goes here
    routers = ['0x7ce49752ffa7055622f444df3c69598748cb2e5f',
    '0xc4ae07f276768a3b74ae8c47bc108a2af0e40eba',
    '0x6273c0965a1db4f8a6277d490b4fd48715a42b96',
    '0x49a9e7ec76bc8fdf658d09557305170d9f01d2fa',
    '0x22831e4f21ce65b33ef45df0e212b5bebf130e5a',
    '0x5d527765252003acee6545416f6a9c8d15ae8402',
    '0x6892d4d1f73a65b03063b7d78174dc6350fcc406',
    '0x96d38b113b1bc6a21d1137676f2f05dfcace24e8',
    '0x6fd84ba95525c4ccd218f2f16f646a08b4b0a598',
    '0x975574980a5da77f5c90bc92431835d91b73669e',
    '0x8cb19ce8eedf740389d428879a876a3b030b9170',
    '0xf26c772c0ff3a6036bddabdaba22cf65eca9f97c',
    '0x048a5ecc705c280b2248aeff88fd581abbeb8587',
    '0xbe7bc00382a50a711d037eaecad799bb8805dfa8',
    '0xfaab88015477493cfaa5dfaa533099c590876f21',
    '0x58507fed0cb11723dfb6848c92c59cf0bbeb9927',
    '0x33b2ad85f7dba818e719fb52095dc768e0ed93ec',
    '0x0e62f9fa1f9b3e49759dc94494f5bc37a83d1fad',
    '0x63cda9c42db542bb91a7175e38673cfb00d402b0',
    '0x88f02a786e33823b1217341fa8345136a05948bb',
    '0xeca085906cb531bdf1f87efa85c5be46aa5c9d2c',
    '0x97b9dcb1aa34fe5f12b728d9166ae353d1e7f5c4',
    '0x32d63da9f776891843c90787cec54ada23abd4c2',
    '0xba11aa59645a56031fedbccf60d4f111534f2502',
    '0x9584eb0356a380b25d7ed2c14c54de58a25f2581',
    '0xc770ec66052fe77ff2ef9edf9558236e2d1c41ef',
    '0x76cf58ce587bc928fcc5ad895555fd040e06c61a',
    '0x5f4e31f4f402e368743bf29954f80f7c4655ea68',
    '0xc82c7d826b1ed0b2a4e9a2be72b445416f901fd1',
    '0xb7318647071eb12164d251b07815154761967a8f']

    url = "https://sequencer.mainnet.connext.ninja/router-status/"

    # Preparing lists for DataFrame
    data_for_df = []

    for router in routers:
        #logging.info(router)
        router_url = url+router
        #logging.info(router_url)
        response = requests.get(router_url)
        #logging.info(response)
        data = json.loads(response.content)
        #logging.info(data)
        lastactive = data['lastActiveTimestamp']
        #logging.info(lastactive)
        lastbid = data['lastBidTimestamp']
        #logging.info(lastbid)

        # Iterate through the dictionary
        for key, value in lastbid.items():
            # Splitting the key into its parts
            part1, part2, address = key.split(':')
            # Append the split parts and the value as a new row in the list
            data_for_df.append([part1, part2, address, value, lastactive, router])


    #test_url = "https://sequencer.mainnet.connext.ninja/router-status/0x7ce49752ffa7055622f444df3c69598748cb2e5f"

    # Convert the list into a DataFrame
    df = pd.DataFrame(data_for_df, columns=['origin_domain', 'destination_domain', 'token_address', 'last_bid', 'last_active', 'router_address'])

    logging.info(df)
    
    logging.info("Data fetched and DataFrame created successfully.")

    return df

