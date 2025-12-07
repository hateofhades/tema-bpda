#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ ! -f "$WALLET_PEM" ]; then
    echo "Wallet not found at $WALLET_PEM"
    exit 1
fi

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address not found!"
    exit 1
fi

echo "Canceling football slot on contract: $CONTRACT_ADDRESS"

if mxpy contract call "$CONTRACT_ADDRESS" \
    --function "cancelFootballSlot" \
    --pem "$WALLET_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send; then
    echo "Slot canceled and refunds initiated."
else
    echo "Failed to cancel slot"
    exit 1
fi
