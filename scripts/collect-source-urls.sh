#!/usr/bin/env bash

set -euo pipefail

sources_file="${1:-sources.json}"
output_file="${2:-urls.txt}"

command -v gh >/dev/null 2>&1 || {
  echo "error: gh is required" >&2
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 1
}

jq -e '
  .schemaVersion == 1
  and (.packages | type == "array" and length > 0)
  and ((.packages | map(.name) | unique | length) == (.packages | length))
  and all(.packages[];
    (.name | type == "string" and length > 0)
    and (.repository | type == "string"
         and test("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$"))
    and (.version | type == "string" and length > 0)
  )
' "$sources_file" >/dev/null

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

while IFS=$'\t' read -r name version repository; do
  tag="${name}-v${version}"
  asset_name="${name}-${version}.lgx"
  release="$(gh api "repos/${repository}/releases/tags/${tag}")"

  if [ "$(jq -r '.draft' <<<"$release")" = "true" ]; then
    echo "error: ${repository} release ${tag} is still a draft" >&2
    exit 1
  fi
  if ! jq -e 'any(.assets[]?; .name == "sidecar.json")' \
    <<<"$release" >/dev/null; then
    echo "error: ${repository} release ${tag} has no sidecar.json" >&2
    exit 1
  fi

  mapfile -t lgx_urls < <(
    jq -r --arg asset_name "$asset_name" '
      .assets[]?
      | select(.name == $asset_name)
      | .browser_download_url
    ' <<<"$release"
  )
  if [ "${#lgx_urls[@]}" -ne 1 ]; then
    echo "error: ${repository} release ${tag} must contain exactly one ${asset_name}" >&2
    exit 1
  fi
  printf '%s\n' "${lgx_urls[0]}" >>"$tmp_file"
done < <(
  jq -r '
    .packages[]
    | [.name, .version, .repository]
    | @tsv
  ' "$sources_file"
)

sort -u "$tmp_file" >"$output_file"
if [ ! -s "$output_file" ]; then
  echo "error: no source-owned .lgx release assets found" >&2
  exit 1
fi

expected_count="$(jq '.packages | length' "$sources_file")"
actual_count="$(wc -l <"$output_file" | tr -d ' ')"
if [ "$actual_count" -ne "$expected_count" ]; then
  echo "error: collected ${actual_count} assets for ${expected_count} packages" >&2
  exit 1
fi

echo "Collected ${actual_count} source-owned package URL(s)."
