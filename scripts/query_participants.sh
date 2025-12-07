#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract not deployed!"
    exit 1
fi

echo "Querying participants..."
echo "Contract: $CONTRACT_ADDRESS"

mxpy contract query "$CONTRACT_ADDRESS" \
    --function "getParticipants" \
    --proxy "$PROXY"
