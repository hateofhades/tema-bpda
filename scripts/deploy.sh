#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

echo "Deploying smart contract to devnet..."
if [ ! -f "$WALLET_PEM" ]; then
    echo "Wallet not found at $WALLET_PEM"
    exit 1
fi

# Check if WASM exists
if [ ! -f "$WASM_PATH" ]; then
    echo "WASM file not found at $WASM_PATH"
    exit 1
fi

# Deploy the contract
RESULT=$(mxpy contract deploy \
    --bytecode "$WASM_PATH" \
    --pem "$WALLET_PEM" \
    --gas-limit $DEPLOY_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send 2>&1)

echo "$RESULT"

# Extract contract address from result
CONTRACT_ADDRESS=$(echo "$RESULT" | grep -oE "erd1[a-z0-9]{58}" | tail -1)

if [ -n "$CONTRACT_ADDRESS" ]; then
    save_contract_address "$CONTRACT_ADDRESS"
    echo "Contract address: $CONTRACT_ADDRESS"
    echo "Explorer: https://devnet-explorer.multiversx.com/accounts/$CONTRACT_ADDRESS"
else
    echo "Failed to deploy contract or extract address"
    exit 1
fi
