#!/usr/bin/env bash

set -euo pipefail

command_name="${1:-}"

usage() {
  cat <<'EOF'
Usage: ./scripts/catalog.sh <command> [run-id]

Commands:
  rebuild        Rebuild index.json from source-owned GitHub releases
  status         Show recent catalog workflow runs
  watch [run-id] Watch one run, or the newest run when omitted
EOF
}

case "$command_name" in
  rebuild)
    gh workflow run "Rebuild source release index"
    ;;
  status)
    gh run list --limit 15
    ;;
  watch)
    run_id="${2:-}"
    if [ -z "$run_id" ]; then
      run_id="$(
        gh run list --limit 1 --json databaseId \
          --jq '.[0].databaseId // empty'
      )"
    fi
    if [ -z "$run_id" ]; then
      echo "error: no workflow run found" >&2
      exit 1
    fi
    gh run watch "$run_id"
    ;;
  -h|--help|"")
    usage
    ;;
  *)
    echo "error: unknown command: $command_name" >&2
    usage >&2
    exit 2
    ;;
esac
