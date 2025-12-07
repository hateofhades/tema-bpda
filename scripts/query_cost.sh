#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

CONTRACT_ADDRESS=$(get_contract_address)
if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract not deployed!"
    exit 1
fi

echo "Querying football court cost..."
echo "Contract: $CONTRACT_ADDRESS"

COST=$(mxpy contract query "$CONTRACT_ADDRESS" \
    --function "getFootballCourtCost" \
    --proxy "$PROXY" | jq -r '.[0]')

# Transform the output from hex to decimal
echo "Football court cost: $((16#$COST)) wei"
echo "Football court cost: $(bc <<< "scale=18; $((16#$COST)) / 1000000000000000000") EGLD"
