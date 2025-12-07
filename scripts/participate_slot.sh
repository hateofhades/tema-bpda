#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Usage: $0 <wallet-index> [payment_wei]"
    exit 1
fi

WALLET_FILE="$WALLETS_DIR/$1.pem"
if [ ! -f "$WALLET_FILE" ]; then
    echo "Wallet not found: $WALLET_FILE"
    exit 1
fi

CONTRACT_ADDRESS=$(get_contract_address)
if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract not deployed!"
    exit 1
fi

slot_json=$(mxpy contract query "$CONTRACT_ADDRESS" \
    --function "getReservedSlot" \
    --abi ../output/tema-1.abi.json \
    --proxy "$PROXY" | jq -r '.[0]')

if [[ "$slot_json" == "null" || -z "$slot_json" ]]; then
    echo "No reserved slot to participate in."
    exit 1
fi

slot_amount=$(echo "$slot_json" | jq -r '.amount')
if [[ "$slot_amount" == "null" || -z "$slot_amount" ]]; then
    echo "Unable to determine slot amount"
    exit 1
fi

PAYMENT=${2:-$slot_amount}

echo "Participating with wallet #$1 ($WALLET_FILE)"
echo "Slot amount: $slot_amount wei ($(bc <<< "scale=18; $slot_amount / 1000000000000000000") EGLD)"
echo "Payment: $PAYMENT wei ($(bc <<< "scale=18; $PAYMENT / 1000000000000000000") EGLD)"
echo "Contract: $CONTRACT_ADDRESS"

mxpy contract call "$CONTRACT_ADDRESS" \
    --function "participateToFootballSlot" \
    --value $PAYMENT \
    --pem "$WALLET_FILE" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send

if [ $? -eq 0 ]; then
    echo "Participation submitted."
else
    echo "Failed to participate"
    exit 1
fi
