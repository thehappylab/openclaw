# openclaw

**Version:** `2026.2.17-8`

Custom Docker image for running [OpenClaw](https://github.com/coollabsio/openclaw) on a [Coolify](https://coolify.io) instance, extended with additional CLI tools.

## What this repo does

This repo builds a custom Docker image based on `coollabsio/openclaw:latest` and adds the following tools:

| Tool | Command | Description |
|------|---------|-------------|
| [Bitwarden CLI](https://bitwarden.com/help/cli/) | `bw` | Secrets and password management |
| [Homebrew](https://brew.sh/) | `brew` | Package manager (Linuxbrew) |
| [GitHub CLI](https://cli.github.com/) | `gh` | Interact with GitHub from the terminal |
| [Vim](https://www.vim.org/) | `vim` | Text editor |
| [Coolify CLI](https://github.com/coollabsio/coolify-cli) | `coolify` | Manage Coolify resources via API |

The image is automatically built and pushed to **GitHub Container Registry** on every push to `main`:

```
ghcr.io/thehappylab/openclaw:latest
ghcr.io/thehappylab/openclaw:2026.2.15-1
ghcr.io/thehappylab/openclaw:<short-sha>
```

## Versioning

Uses CalVer: `YYYY.M.D-N` (date + continuous counter).

```bash
make version   # show current version
make bump      # bump version → updates VERSION, docker-compose, build.yml, README
```

## Repository structure

```
.
├── VERSION                     # Source of truth for the current version
├── Makefile                    # Version bump tooling
├── Dockerfile                  # Extends coollabsio/openclaw with CLI tools
├── docker-compose.coolify.yaml # Coolify service definition (openclaw + browser)
└── .github/workflows/
    └── build.yml               # GitHub Actions: build & push to GHCR
```

## How it works

1. **GitHub Actions** builds the `Dockerfile` on every push to `main` and publishes the image to `ghcr.io/thehappylab/openclaw`.
2. **Coolify** pulls `ghcr.io/thehappylab/openclaw:latest` as defined in `docker-compose.coolify.yaml` to run the service alongside the OpenClaw browser container.

## Manual trigger

You can also trigger a build manually from the [Actions tab](https://github.com/thehappylab/openclaw/actions) using the "Run workflow" button.
