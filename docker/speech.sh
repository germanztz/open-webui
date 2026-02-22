#!/bin/bash

if [ -z "$1" ]; then
  echo "Uso: $0 fichero.txt"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "Error: el fichero '$FILE' no existe"
  exit 1
fi

# TEXT=$(jq -Rs . < "$FILE")

# curl -X POST http://localhost:5050/v1/audio/speech \
#  -H "Authorization: Bearer your_api_key_here" \
#  -H "Content-Type: application/json" \
#  -d "{\"input\": $TEXT}" \
#  | ffplay -autoexit -nodisp -i -

cat "$FILE" | while read CHUNK; do
  curl --no-buffer \
    -X POST http://localhost:5050/v1/audio/speech \
    -H "Authorization: Bearer your_api_key_here" \
    -H "Content-Type: application/json" \
    -d "{\"input\": \"$CHUNK\"}" \
    | ffplay -nodisp -autoexit -i -
done
