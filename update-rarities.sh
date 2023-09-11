#!/bin/bash

set -eu

MOUNTS_FILE="Mounts.lua"

function get() {
    curl "$1" \
        -X 'GET' \
        -H 'Accept: text/json; charset=iso-8859-1' \
        -H 'Origin: https://www.dataforazeroth.com' \
        -H 'User-Agent: RandomRareMount'
}

VERSION_RESPONSE=$(get 'https://api.dataforazeroth.com/version')
#echo "$VERSION_RESPONSE" | jq .mountsrarity

MOUNTSRARITY_PATH=$(echo "$VERSION_RESPONSE" | jq .mountsrarity | tr -d '"')
#echo "https://api.dataforazeroth.com${MOUNTSRARITY_PATH}"

MOUNTSRARITY_SOURCE="https://www.dataforazeroth.com${MOUNTSRARITY_PATH}"
MOUNTSRARITY_RESPONSE=$(get "$MOUNTSRARITY_SOURCE")
MOUNTSRARITY=$(echo "$MOUNTSRARITY_RESPONSE" | jq '.mounts | to_entries')
echo "Downloaded $(echo "$MOUNTSRARITY" | jq 'length') mounts."
#echo "$MOUNTSRARITY" | jq > mounts.json

# Writing file header
echo "-- AUTOMATICALLY GENERATED. MODIFICATION WILL BE OVERWRITTEN" > $MOUNTS_FILE
# Writing file contents brackets
{
    echo "-- Source: ${MOUNTSRARITY_SOURCE}"
    echo ""
    echo "RandomRareMountAddon.MountsRarity = {"
    echo "  mounts = {"
    echo "$MOUNTSRARITY" | jq -r '.[] | "    [\"" + .key + "\"] = " + ( .value | tostring ) + ","' >> $MOUNTS_FILE
    echo "  }"
    echo "}"
} >> $MOUNTS_FILE

echo "$MOUNTS_FILE written."
