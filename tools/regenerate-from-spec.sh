#!/bin/bash

set -eo pipefail

export GOCACHE=/tmp/hfhub-go-cache

# Check that all prerequisite tools are installed before doing any work.
check_dependencies() {
  local missing=0
  for tool in "$@"; do
    if ! command -v "${tool}" &>/dev/null; then
      echo "ERROR: prerequisite not found on PATH: ${tool}" >&2
      missing=1
    fi
  done
  return "${missing}"
}

check_dependencies curl jq yq go

pushd "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null

curl -sSfl https://huggingface.co/.well-known/openapi.json | jq >huggingface-hub.json

go mod tidy

go tool ogen --target ./ -package hfhub --clean huggingface-hub.json
