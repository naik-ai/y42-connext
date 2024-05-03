from y42.v1.decorators import data_loader
import requests
import pandas as pd
import logging
import json
import re

# use the @data_loader decorator to materialize an asset
# make sure you have a corresponding .yml table definition matching the function's name
# for more information check out our docs: https://docs.y42.dev/docs/sources/ingest-data-using-python

@data_loader
def github_parser_chains(context) -> pd.DataFrame:
    # Reference secrets if needed
    all_secrets = context.secrets.all() # get all secrets saved within this space

    url = "https://raw.githubusercontent.com/connext/chaindata/edfe887235b6206aaf59e0f751bd5035506eecf9/crossChain.json"

    response = requests.get(url)
    logging.info(response)

    logging.info(response.content)

    data = json.loads(response.content)
    logging.info(data)
    """
    data_clean = data['payload']['blob']['rawLines']
    combined_json_str = "".join(data_clean)
    #logging.info(combined_json_str)
    # Reconstructing JSON from individual lines
    combined_json_str = re.sub(r'\s+', ' ', combined_json_str)
    error_text = '''18, }, "0x2416092f143378750bb29b79eD961ab195CcEea5": { "name": "Renzo Restaked ETH", "symbol": "ezETH", "decimals": 18 }'''
    fixed_text = '''18 }, "0x2416092f143378750bb29b79eD961ab195CcEea5": { "name": "Renzo Restaked ETH", "symbol": "ezETH", "decimals": 18 }'''

    combined_json_str = combined_json_str.replace(error_text,fixed_text)

    parsed_json = json.loads(combined_json_str)
    data_clean = parsed_json
    """
    data_clean = data
    #logging.info(data_clean)

    # Return a DataFrame which will be materialized within your data warehouse
    df = pd.DataFrame(data_clean)
    #logging.info(df)
    df_native_currency = pd.json_normalize(df['nativeCurrency'])
    # Renaming columns for clarity, if desired
    df_native_currency.columns = ['nativeCurrency.' + col for col in df_native_currency.columns]
    # Concatenating the expanded 'nativeCurrency' DataFrame with the original DataFrame
    df_expanded = pd.concat([df, df_native_currency], axis=1)

    for column in df_expanded.columns:
        #df_expanded[column] = df_expanded[column].astype(str)
        if df_expanded[column].dtype == 'object':
            df_expanded[column]= df_expanded[column].fillna('')
            df_expanded[column] = df_expanded[column].astype(str)
            #df_expanded[column]= df_expanded[column].fillna('')
    
    #df_expanded = df_expanded.fillna('')

    
    #logging.info(df_expanded)
    #logging.info("Data fetched and DataFrame created successfully.")
    # to learn how to set up incremental updates and more
    # please visit https://docs.y42.dev/docs/sources/ingest-data-using-python
    return df_expanded

@data_loader
def github_parser_tokens(context) -> pd.DataFrame:
    # Reference secrets if needed
    all_secrets = context.secrets.all() # get all secrets saved within this space


    # Your code goes here
    url = "https://raw.githubusercontent.com/connext/chaindata/edfe887235b6206aaf59e0f751bd5035506eecf9/crossChain.json"

    response = requests.get(url)
    logging.info(response)
    data = json.loads(response.content)

    """
    data_clean = data['payload']['blob']['rawLines']
    combined_json_str = "".join(data_clean)

    combined_json_str = re.sub(r'\s+', ' ', combined_json_str)
    error_text = '''18, }, "0x2416092f143378750bb29b79eD961ab195CcEea5": { "name": "Renzo Restaked ETH", "symbol": "ezETH", "decimals": 18 }'''
    fixed_text = '''18 }, "0x2416092f143378750bb29b79eD961ab195CcEea5": { "name": "Renzo Restaked ETH", "symbol": "ezETH", "decimals": 18 }'''

    combined_json_str = combined_json_str.replace(error_text,fixed_text)
    # Reconstructing JSON from individual lines
    parsed_json = json.loads(combined_json_str)
    data_clean = parsed_json
    """
    data_clean = data
    logging.info(data_clean)

    # Return a DataFrame which will be materialized within your data warehouse
    df = pd.DataFrame(data_clean)
    logging.info(df)
    df_native_currency = pd.json_normalize(df['nativeCurrency'])
    # Renaming columns for clarity, if desired
    df_native_currency.columns = ['nativeCurrency.' + col for col in df_native_currency.columns]
    # Concatenating the expanded 'nativeCurrency' DataFrame with the original DataFrame
    df_expanded = pd.concat([df, df_native_currency], axis=1)

    # Correcting the code to dynamically append assetId information based on df_expanded as starting point and fixing lint errors
    expanded_rows = []
    for index, row in df_expanded.iterrows():
        asset_ids = row['assetId']
        for asset_id, asset_info in asset_ids.items():
            # Clone the original row to preserve all other information
            expanded_record = row.to_dict()
            # Remove the original 'assetId' dictionary to avoid duplication
            del expanded_record['assetId']
            # Add asset-specific information as new columns
            for key, value in asset_info.items():
                expanded_record[f'assetId.{key}'] = value
            # Add the assetId itself as a column
            expanded_record['assetId'] = asset_id
            expanded_rows.append(expanded_record)

    # Convert the list of dictionaries to a DataFrame
    df_assets_expanded = pd.DataFrame(expanded_rows)
    
    for column in df_assets_expanded.columns:
        #df_assets_expanded[column] = df_assets_expanded[column].astype(str)
        if df_assets_expanded[column].dtype == 'object' or df_assets_expanded[column].dtype == 'float':
            df_assets_expanded[column] = df_assets_expanded[column].fillna('')
            df_assets_expanded[column] = df_assets_expanded[column].astype(str)
            df_assets_expanded[column] = df_assets_expanded[column].str.lower()

    df_assets_expanded = df_assets_expanded.fillna('')

    logging.info(df_assets_expanded)
    logging.info("Data fetched and DataFrame created successfully.")
    # to learn how to set up incremental updates and more
    # please visit https://docs.y42.dev/docs/sources/ingest-data-using-python
    return df_assets_expanded
