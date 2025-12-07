#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

WALLET_PATH="$WALLET_PEM"

if [ -n "$1" ]; then
    if ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Wallet index must be a non-negative integer"
        exit 1
    fi
    WALLET_PATH="$WALLETS_DIR/$1.pem"
fi

if [ ! -f "$WALLET_PATH" ]; then
    echo "Wallet not found: $WALLET_PATH"
    exit 1
fi

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address missing. Deploy first."
    exit 1
fi

echo "Using wallet: $WALLET_PATH"
echo "Paying court fees on contract $CONTRACT_ADDRESS"

if mxpy contract call "$CONTRACT_ADDRESS" \
    --function "payCourt" \
    --pem "$WALLET_PATH" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send; then
    echo "Court fees paid and participants cleared."
else
    echo "Failed to pay for court"
    exit 1
fi
