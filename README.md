# dhi-mirror

Nightly mirror of [Docker Hardened Images](https://www.docker.com/products/hardened-images/) from `dhi.io` to `ghcr.io/fabro-sh/*`.

## Why

DHI requires an authenticated pull against a subscription account. Mirroring to GHCR lets downstream repos (e.g. `fabro-sh/fabro`) pull from a namespace they already have access to, without each workflow needing DHI credentials.

## Mirrored images

| Source (dhi.io) | Destination (ghcr.io) |
| --- | --- |
| `dhi.io/alpine-base:3.23-dev` | `ghcr.io/fabro-sh/dhi-alpine-base:3.23-dev` |
| `dhi.io/alpine-base:3.23` | `ghcr.io/fabro-sh/dhi-alpine-base:3.23` |

Each source tag is mirrored with two destination tags:

- `<tag>` — moves with every nightly run, always points at the latest mirrored digest.
- `<tag>-YYYY-MM-DD` — immutable, dated pin for reproducible builds.

## Consuming

Moving tag (auto-updates on nightly run):

```dockerfile
FROM ghcr.io/fabro-sh/dhi-alpine-base:3.23-dev
```

Dated pin (immutable):

```dockerfile
FROM ghcr.io/fabro-sh/dhi-alpine-base:3.23-dev-2026-04-18
```

For strict reproducibility, pin by digest:

```sh
docker buildx imagetools inspect ghcr.io/fabro-sh/dhi-alpine-base:3.23-dev \
  --format '{{json .Manifest.Digest}}'
```

## Schedule

Runs nightly at 07:00 UTC via [`.github/workflows/mirror.yml`](.github/workflows/mirror.yml). Can also be triggered manually via `workflow_dispatch`.

## Secrets

The workflow needs two secrets configured on this repo:

- `DHI_USERNAME` — Docker Hub username with DHI subscription access
- `DHI_TOKEN` — Docker Hub access token for that account

GHCR push uses `GITHUB_TOKEN` (automatic).

## Adding images

Edit the `matrix.image` list in `.github/workflows/mirror.yml`. Each entry is `{ source, repo, tag }`. Use the `dhi-<family>` naming convention for the destination repo.

## How it works

The workflow uses `docker buildx imagetools create` to copy the multi-arch manifest list from `dhi.io` to `ghcr.io` without pulling layers through the runner — the registries handle the blob transfer directly.
