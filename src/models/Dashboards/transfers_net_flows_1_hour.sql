-- models/transfers_net_flows_1_hour.sql
{{ config(materialized = 'table') }}

{{ generate_transfers_net_flows(1) }}
