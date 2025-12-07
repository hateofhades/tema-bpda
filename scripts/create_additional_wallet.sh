#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

mkdir -p "$WALLETS_DIR"

INDEX="$1"

if [ -z "$INDEX" ] || ! [[ "$INDEX" =~ ^[0-9]+$ ]]; then
    echo "Invalid wallet index '$INDEX'."
    exit 1
fi

if [ -f "$WALLETS_DIR/$INDEX.pem" ]; then
    echo "Wallet for index $INDEX already exists"
    exit 1
fi

OUT_PATH="$WALLETS_DIR/$INDEX.pem"

echo "Creating wallet $INDEX at $OUT_PATH..."
if mxpy wallet new --format pem --outfile "$OUT_PATH"; then
    ADDRESS=$(mxpy wallet convert --infile "$OUT_PATH" --in-format pem --out-format address-bech32)
    echo "Wallet created"
    echo "Address: $ADDRESS"
else
    echo "Failed to create wallet $INDEX"
    exit 1
fi
