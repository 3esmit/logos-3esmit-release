# Changelog

## Unreleased

- Move every package build and release asset to its source repository.
- Replace catalog-owned module releases with an index of source-owned assets.
- Require the complete Logos Inspector dependency closure on Linux x86_64 and
  Apple silicon macOS.
- Add source-owned Accounts Core/UI and Execution Zone Wallet UI packages.

All notable catalog changes are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and module versions
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Release policy

- The catalog starts in the **alpha** channel while direct-host lifecycle and
  event end-to-end coverage is still being completed.
- A module release must have an entry under `Unreleased` before its version is
  bumped in that module's repository. The entry moves into a dated release
  section when the catalog release is published.
- Patch releases contain compatible fixes; minor releases add compatible user
  capabilities; major releases require an explicit migration note.
- Promote the catalog to **beta** only after the supported Linux and Apple
  silicon artifacts pass their release checks and the documented Inspector
  end-to-end stories are green.
