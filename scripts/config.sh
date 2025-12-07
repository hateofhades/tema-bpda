#!/bin/bash

# Network configuration
PROXY="https://devnet-gateway.multiversx.com"
CHAIN_ID="D"

# Wallet configuration
WALLET_PEM="./wallet.pem"
WALLETS_DIR="./wallets"

# Contract configuration
WASM_PATH="../output/tema-1.wasm"
CONTRACT_ADDRESS_FILE="./contract_address.txt"

# Gas limits
DEPLOY_GAS_LIMIT=100000000
CALL_GAS_LIMIT=10000000

# Helper function to get contract address
get_contract_address() {
    if [ -f "$CONTRACT_ADDRESS_FILE" ]; then
        cat "$CONTRACT_ADDRESS_FILE"
    else
        echo ""
    fi
}

# Helper function to save contract address
save_contract_address() {
    echo "$1" > "$CONTRACT_ADDRESS_FILE"
}
