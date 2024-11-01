#!/bin/bash
curl --location 'http://$TABBY_API_URL/v1/template/switch' \
    --header 'Content-Type: application/json' \
    --header 'Authorization: Bearer $API_KEY' \
    --data '{
    "name": "chatml"

}'
echo
