#!/usr/bin/env bash
set -euo pipefail
source_ref="${1:?exact source image is required}"
root="$(cd "$(dirname "$0")/.." && pwd)"
scratch=$(mktemp -d)
container=""
cleanup() {
  if [[ -n "$container" ]]; then docker rm "$container" >/dev/null; fi
  rm -rf "$scratch"
}
trap cleanup EXIT
# Extract files without executing the image, including foreign architectures.
platforms=$(docker buildx imagetools inspect "$source_ref" --raw | jq -er '
  .manifests[] | select(.platform.os == "linux") |
  "linux/" + .platform.architecture + (if .platform.variant then "/" + .platform.variant else "" end)
')
test -n "$platforms"
while IFS= read -r platform; do
  container=$(docker create --platform "$platform" --entrypoint /__trust_inspection_only "$source_ref")
  bundle="$scratch/ca-certificates.crt"
  if ! docker cp -L "$container:/etc/ssl/certs/ca-certificates.crt" "$bundle" 2>/dev/null; then
    docker cp -L "$container:/etc/ssl/cert.pem" "$bundle"
  fi
  "$root/tests/verify-tls.sh" "$bundle"
  docker rm "$container" >/dev/null
  container=""
done <<<"$platforms"
