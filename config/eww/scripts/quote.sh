#!/bin/bash
while true; do
  data=$(curl -s https://dummyjson.com/quotes/random)
  quote=$(echo "$data" | jq -r '.quote')
  if [ ${#quote} -le 70 ]; then
    echo "$data"
    break
  fi
done
