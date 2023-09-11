#!/bin/bash

set -eu

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

MOUNTSRARITY_RESPONSE=$(get "https://www.dataforazeroth.com${MOUNTSRARITY_PATH}")
echo "Downloaded $(echo "$MOUNTSRARITY_RESPONSE" | jq '.mounts | length') mounts."
echo "$MOUNTSRARITY_RESPONSE" | jq > mounts.json
