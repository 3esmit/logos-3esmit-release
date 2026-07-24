#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin"

cat >"$tmp_dir/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

endpoint="${2:?missing API endpoint}"
repository="${endpoint#repos/}"
repository="${repository%%/releases/tags/*}"
tag="${endpoint##*/}"

source_row="$(
  jq -c \
    --arg repository "$repository" \
    --arg tag "$tag" '
      .packages[]
      | select(.repository == $repository)
      | select((.name + "-v" + .version) == $tag)
    ' "$TEST_SOURCES"
)"
if [ -z "$source_row" ]; then
  echo "unknown fixture release: ${repository} ${tag}" >&2
  exit 1
fi

name="$(jq -r '.name' <<<"$source_row")"
version="$(jq -r '.version' <<<"$source_row")"
assets="$(
  jq -n \
    --arg name "$name" \
    --arg version "$version" \
    --arg repository "$repository" '
      [
        {
          name: ($name + "-" + $version + ".lgx"),
          browser_download_url: (
            "https://github.com/"
            + $repository
            + "/releases/download/"
            + $name
            + "-v"
            + $version
            + "/"
            + $name
            + "-"
            + $version
            + ".lgx"
          )
        }
      ]
      + (
          if env.OMIT_SIDECAR_FOR == $name
          then []
          else [{name: "sidecar.json", browser_download_url: "sidecar"}]
          end
        )
    '
)"

jq -n \
  --arg tag "$tag" \
  --argjson assets "$assets" \
  '{tag_name: $tag, draft: false, assets: $assets}'
EOF
chmod +x "$tmp_dir/bin/gh"

TEST_SOURCES="$repo_root/sources.json" \
PATH="$tmp_dir/bin:$PATH" \
  "$repo_root/scripts/collect-source-urls.sh" \
  "$repo_root/sources.json" "$tmp_dir/urls.txt"

expected_count="$(jq '.packages | length' "$repo_root/sources.json")"
actual_count="$(wc -l <"$tmp_dir/urls.txt" | tr -d ' ')"
test "$actual_count" -eq "$expected_count"

while IFS=$'\t' read -r name version repository; do
  expected_url="https://github.com/${repository}/releases/download/${name}-v${version}/${name}-${version}.lgx"
  grep -Fqx "$expected_url" "$tmp_dir/urls.txt"
done < <(
  jq -r '.packages[] | [.name, .version, .repository] | @tsv' \
    "$repo_root/sources.json"
)

if TEST_SOURCES="$repo_root/sources.json" \
  OMIT_SIDECAR_FOR="lez_core" \
  PATH="$tmp_dir/bin:$PATH" \
    "$repo_root/scripts/collect-source-urls.sh" \
    "$repo_root/sources.json" "$tmp_dir/rejected.txt" \
    >"$tmp_dir/rejected.stdout" 2>"$tmp_dir/rejected.stderr"; then
  echo "error: source release without sidecar was accepted" >&2
  exit 1
fi
grep -Fq "has no sidecar.json" "$tmp_dir/rejected.stderr"

echo "Source URL collection tests passed."
