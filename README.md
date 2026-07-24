# Logos Inspector Package Catalog

Package index for the maintained Logos Inspector release set.

Each program owns its build, tags, changelog, checksums, sidecar metadata, and
GitHub Release assets in its source repository. This repository does not build,
copy, or rehost `.lgx` files. It publishes only the rolling `index.json` used by
Logos package clients.

Add this repository URL to Basecamp or another Logos package client:

```text
https://raw.githubusercontent.com/3esmit/logos-3esmit-release/main/logos-repo.json
```

The catalog exposes `Logos Inspector` through `logos_inspector_ui`. Its
dependency closure is restricted to packages from maintained source forks:

```text
logos_inspector_ui
└── logos_inspector
    ├── blockchain_module
    ├── storage_module
    ├── delivery_module
    └── lez_core
```

The same index also exposes the independently installable Accounts and
Execution Zone Wallet applications:

```text
accounts_ui                 lez_wallet_ui
└── accounts_module         └── lez_core
```

## Source ownership

[`sources.json`](sources.json) maps each package name to its only accepted
source repository, current release version, and exact package dependencies.
Every indexed release must provide:

- one source-owned `.lgx` GitHub Release asset;
- `sidecar.json` in the same source release;
- `linux-amd64` and `darwin-arm64` variants;
- manifest dependencies matching `sources.json`;
- asset URLs under the mapped source repository.

An upstream or same-name package from another repository fails validation.

## Rebuild the index

Run the **Rebuild source release index** workflow, or:

```bash
./scripts/catalog.sh rebuild
```

The workflow:

1. collects `.lgx` URLs from mapped source repositories;
2. rejects source releases without sidecar metadata;
3. builds `index.json` with the canonical Logos release tool;
4. validates ownership, variants, and complete Inspector dependency closure;
5. replaces only `index.json` on this repository's rolling `index` release.

It also runs every six hours to pick up new source releases.

## Local validation

```bash
bash -n scripts/*.sh
./scripts/test-collect-source-urls.sh
./scripts/test-index-contract.sh
```

The contract tests reject cross-repository substitution, missing Apple silicon
or Linux variants, and incomplete Inspector dependencies.

## Release channel

Current channel: **alpha**. Package versions remain owned by their source
repositories. Catalog changes are recorded in [CHANGELOG.md](CHANGELOG.md).
