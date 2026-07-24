#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

valid_index="$tmp_dir/index.json"

jq '
  {
    schemaVersion: 2,
    repositoryName: "logos-3esmit-release",
    generatedAt: "2026-01-01T00:00:00Z",
    packages: [
      .packages[] as $source
      | {
          name: $source.name,
          versions: [
            {
              releasedAt: "2026-01-01T00:00:00Z",
              publisherRef: ($source.name + "-v" + $source.version),
              url: (
                "https://github.com/"
                + $source.repository
                + "/releases/download/"
                + $source.name
                + "-v"
                + $source.version
                + "/"
                + $source.name
                + "-"
                + $source.version
                + ".lgx"
              ),
              size: 1,
              sha256: ("a" * 64),
              rootHash: ("b" * 64),
              manifest: {
                name: $source.name,
                version: $source.version,
                dependencies: $source.dependencies,
                hashes: {
                  "variants/linux-amd64": "linux",
                  "variants/darwin-arm64": "darwin"
                },
                main: {
                  "linux-amd64": "module.so",
                  "darwin-arm64": "module.dylib"
                }
              }
            }
          ]
        }
    ]
  }
' "$repo_root/sources.json" >"$valid_index"

"$repo_root/scripts/validate-index.sh" \
  "$valid_index" "$repo_root/sources.json"

jq '
  (.packages[] | select(.name == "logos_inspector") | .versions[0].url)
    = "https://github.com/logos-co/logos-inspector/releases/download/logos_inspector-v1.0.0/logos_inspector-1.0.0.lgx"
' "$valid_index" >"$tmp_dir/wrong-owner.json"
if "$repo_root/scripts/validate-index.sh" \
  "$tmp_dir/wrong-owner.json" "$repo_root/sources.json"; then
  echo "error: wrong source owner was accepted" >&2
  exit 1
fi

jq '
  del(
    .packages[]
    | select(.name == "logos_inspector")
    | .versions[0].manifest.main["darwin-arm64"]
  )
' "$valid_index" >"$tmp_dir/missing-variant.json"
if "$repo_root/scripts/validate-index.sh" \
  "$tmp_dir/missing-variant.json" "$repo_root/sources.json"; then
  echo "error: incomplete platform package was accepted" >&2
  exit 1
fi

jq '
  (
    .packages[]
    | select(.name == "logos_inspector")
    | .versions[0].manifest.dependencies
  ) = ["blockchain_module"]
' "$valid_index" >"$tmp_dir/incomplete-closure.json"
if "$repo_root/scripts/validate-index.sh" \
  "$tmp_dir/incomplete-closure.json" "$repo_root/sources.json"; then
  echo "error: incomplete Inspector dependency closure was accepted" >&2
  exit 1
fi

echo "Index contract tests passed."
