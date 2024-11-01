#!/bin/bash
curl --location 'http://$TABBY_API_URL/v1/model' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer $API_KEY' | jq '.'
echo
