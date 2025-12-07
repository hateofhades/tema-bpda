#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

COST=${1:-"10000000000000000"} # Default to 0.01 EGLD in wei
CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract not deployed!"
    exit 1
fi

echo "Setting football court cost to: $COST wei"
echo "Contract: $CONTRACT_ADDRESS"

if mxpy contract call "$CONTRACT_ADDRESS" \
    --function "setFootballCourtCost" \
    --arguments $COST \
    --pem "$WALLET_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send; then
    echo "Football court cost set successfully!"
else
    echo "Failed to set football court cost"
    exit 1
fi
