#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

# Arguments: start_timestamp end_timestamp payment_in_wei
START_TIME=${1:-$(date -v+1d +%s)}  # Default: tomorrow
END_TIME=${2:-$(date -v+1d -v+2H +%s)}  # Default: tomorrow + 2 hours
PAYMENT=${3:-"10000000000000000"}  # Default: 0.01 EGLD

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract not deployed!"
    exit 1
fi

echo "Creating football slot..."
echo "  Contract: $CONTRACT_ADDRESS"
echo "  Start time: $START_TIME ($(date -r $START_TIME 2>/dev/null || date -d @$START_TIME 2>/dev/null))"
echo "  End time: $END_TIME ($(date -r $END_TIME 2>/dev/null || date -d @$END_TIME 2>/dev/null))"
echo "  Payment: $PAYMENT wei ($(bc <<< "scale=18; $PAYMENT / 1000000000000000000") EGLD)"

if mxpy contract call "$CONTRACT_ADDRESS" \
    --function "createFootballSlot" \
    --arguments $START_TIME $END_TIME \
    --value $PAYMENT \
    --pem "$WALLET_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send; then
    echo "Football slot created successfully!"
else
    echo "Failed to create football slot"
    exit 1
fi
