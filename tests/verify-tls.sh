#!/usr/bin/env bash
set -euo pipefail

# Public certificate fixtures from https://emudhra.we-have-a-problem.com/chains.zip.
# Check the native trust store without sending traffic or credentials.
fixtures="$(cd "$(dirname "$0")" && pwd)/tls-chains"
bundle="${1:-/etc/ssl/certs/ca-certificates.crt}"
test -s "$bundle"
for chain in "$fixtures"/*.pem; do
  host="$(basename "$chain" .pem)"
  if output=$(openssl verify -no-CApath -no-CAstore -purpose sslserver \
    -verify_hostname "$host" -CAfile "$bundle" -untrusted "$chain" "$chain" 2>&1); then
    echo "Unsafe trust store: accepted $host" >&2
    exit 1
  fi
  if ! grep -Eq 'unable to get local issuer certificate|certificate signature failure|certificate revoked|certificate rejected' <<<"$output"; then
    echo "Inconclusive certificate check: $output" >&2
    exit 1
  fi
done
echo 'System trust rejects all 12 affected chains.'
