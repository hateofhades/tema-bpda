#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

# Wallet selection (default owner)
WALLET_PATH="$WALLET_PEM"
if [[ "$1" == "-w" || "$1" == "--wallet" ]]; then
    shift
    WALLET_INDEX="$1"
    if [ -z "$WALLET_INDEX" ]; then
        echo "Missing wallet index after -w/--wallet"
        exit 1
    fi
    if [[ ! "$WALLET_INDEX" =~ ^[0-9]+$ ]]; then
        echo "Wallet index must be a non-negative integer"
        exit 1
    fi
    WALLET_PATH="$WALLETS_DIR/$WALLET_INDEX.pem"
fi

if [ ! -f "$WALLET_PATH" ]; then
    echo "Wallet not found: $WALLET_PATH"
    exit 1
fi

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address not found!"
    exit 1
fi

echo "Canceling football slot on contract: $CONTRACT_ADDRESS"
echo "  Wallet: $WALLET_PATH"

if mxpy contract call "$CONTRACT_ADDRESS" \
    --function "cancelFootballSlot" \
    --pem "$WALLET_PATH" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send; then
    echo "Slot canceled and refunds initiated."
else
    echo "Failed to cancel slot"
    exit 1
fi
