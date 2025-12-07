#!/bin/bash

source "$(dirname "$0")/config.sh"

echo "Creating new wallet..."
if mxpy wallet new --format pem --outfile "$WALLET_PEM"; then
    # Get the address from the PEM file
    ADDRESS=$(mxpy wallet convert --infile "$WALLET_PEM" --in-format pem --out-format address-bech32)
    echo "Address: $ADDRESS"
else
    echo "Failed to create wallet"
    exit 1
fi
