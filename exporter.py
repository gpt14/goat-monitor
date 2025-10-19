import os
import time
import requests
from prometheus_client import start_http_server, Gauge

GOAT_RPC_URL = os.getenv("GOAT_RPC_URL", "https://rpc.ankr.com/goat_mainnet")

# Define Prometheus metrics
block_height_gauge = Gauge("goat_block_height", "Current Goat block height")
chain_id_gauge = Gauge("goat_chain_id", "Goat chain ID")
syncing_status_gauge = Gauge("goat_syncing_status", "Syncing status (1 = syncing, 0 = synced)")

def rpc_call(method):
    """Helper to make JSON-RPC requests"""
    try:
        response = requests.post(GOAT_RPC_URL, json={
            "jsonrpc": "2.0",
            "method": method,
            "params": [],
            "id": 1
        }, timeout=10)
        response.raise_for_status()
        return response.json().get("result")
    except Exception as e:
        print(f"Error calling {method}: {e}")
        return None

def update_metrics():
    """Fetch RPC data and update Prometheus metrics"""
    # Block height
    block_hex = rpc_call("eth_blockNumber")
    if block_hex:
        block_height_gauge.set(int(block_hex, 16))

    # Chain ID
    chain_hex = rpc_call("eth_chainId")
    if chain_hex:
        chain_id_gauge.set(int(chain_hex, 16))

    # Syncing status
    syncing = rpc_call("eth_syncing")
    syncing_status_gauge.set(1 if syncing and syncing != False else 0)

if __name__ == "__main__":
    print(f"Starting Goat RPC exporter. Using RPC: {GOAT_RPC_URL}")
    start_http_server(8000)
    while True:
        update_metrics()
        time.sleep(10)
