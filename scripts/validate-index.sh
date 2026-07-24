#!/usr/bin/env bash

set -euo pipefail

index_file="${1:-index.json}"
sources_file="${2:-sources.json}"

jq -e --slurpfile source_document "$sources_file" '
  . as $index
  | $source_document[0].packages as $sources
  | ($sources | map(.name) | sort) as $expected_names
  | ($index.packages | map(.name) | sort) as $actual_names
  | $index.schemaVersion == 2
    and ($index.repositoryName == "logos-3esmit-release")
    and ($actual_names == $expected_names)
    and all($sources[];
      . as $source
      | ($index.packages
         | map(select(.name == $source.name))
         | first) as $package
      | ($package.versions | type == "array" and length > 0)
        and all($package.versions[];
          . as $version
          | (
              $version.url
              == (
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
              )
            )
            and ($version.manifest.name == $source.name)
            and ($version.manifest.version == $source.version)
            and (
              (($version.manifest.dependencies // []) | sort)
              == ($source.dependencies | sort)
            )
            and ($version.sha256 | type == "string" and length == 64)
            and ($version.rootHash | type == "string" and length == 64)
            and ($version.size | type == "number" and . > 0)
            and all($source.requiredVariants[];
              . as $variant
              | ($version.manifest.hashes | has("variants/\($variant)"))
                and ($version.manifest.main | has($variant))
            )
        )
    )
' "$index_file" >/dev/null

echo "Validated source ownership, package closure, and required variants."
