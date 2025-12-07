#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Usage: $0 <wallet-index>"
    exit 1
fi

MANAGER_PEM="$WALLETS_DIR/$1.pem"
if [ ! -f "$MANAGER_PEM" ]; then
    echo "Manager wallet not found"
    exit 1
fi

ADDRESS=$(mxpy wallet convert --infile "$MANAGER_PEM" --in-format pem --out-format address-bech32 | cut -d ':' -f2 | tr -d '[:space:]')
CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address missing. Deploy first."
    exit 1
fi

if [ ! -f "$WALLET_PEM" ]; then
    echo "Owner wallet not found"
    exit 1
fi

echo "Setting manager to wallet #$1 ($ADDRESS)"

mxpy contract call "$CONTRACT_ADDRESS" \
    --function "setFootballFieldManager" \
    --arguments "addr:$ADDRESS" \
    --pem "$WALLET_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send
