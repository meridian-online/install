# install.meridian.online

Thin Cloudflare Pages site that serves install scripts for Meridian tools.

## How it works

```
FineType release CI (tag push)
  └── repository_dispatch → this repo
        └── writes finetype/index.html → Cloudflare Pages deploys
```

Each tool gets its own path:

| Path | Source repo | Script |
|------|------------|--------|
| `/finetype` | [meridian-online/finetype](https://github.com/meridian-online/finetype) | `scripts/install.sh` |

## Usage

```bash
# Install latest FineType
curl -fsSL https://install.meridian.online/finetype | bash

# Install specific version
curl -fsSL https://install.meridian.online/finetype | bash -s -- v0.6.11
```

## Deployment

Deployed to Cloudflare Pages at `install.meridian.online`. Rebuilds automatically on push to `main`.

## Adding a new tool

1. Create `<tool>/index.html` in this repo (placeholder)
2. Add a `repository_dispatch` step to the tool's release workflow
3. Add the `update-install-script` handler to `.github/workflows/update.yml`
