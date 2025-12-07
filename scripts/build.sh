#!/bin/bash

cd "$(dirname "$0")/.."

echo "Building smart contract..."
sc-meta all build

if sc-meta all build; then
    echo "Build successful!"
else
    echo "Failed to build contract"
    exit 1
fi
