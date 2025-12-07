#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract not deployed!"
    exit 1
fi

if [ ! -f "$WASM_PATH" ]; then
    echo "WASM file not found at $WASM_PATH"
    exit 1
fi

echo "Querying manager..."
echo "Contract: $CONTRACT_ADDRESS"

mxpy contract query "$CONTRACT_ADDRESS" \
    --function "getFootballFieldManager" \
    --abi ../output/tema-1.abi.json \
    --proxy "$PROXY"
