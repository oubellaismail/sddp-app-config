#!/usr/bin/env bash
# Onboard a paved-road service into the sddp-app namespace: stamp the delivery
# manifests from onboarding/service-template/ into manifests/<svc>/, which the
# ArgoCD Application picks up automatically (it recurses manifests/).
#
# Run from the repo root:
#
#   ./onboarding/onboard.sh <svc> --digest <sha256:...> [--port <n>] [--host <fqdn>]
#
# <svc>       service slug, e.g. `widget` (image is sddp-<svc>, dir is manifests/<svc>/)
# --digest    the first SIGNED digest from the service's release run (required)
# --port      container/service port (default 3000)
# --host      public FQDN → also generates an Ingress (TLS + WAF + rate-limit)
#
# What stays MANUAL by design (a reviewed trust act, never scripted):
#   * adding the service's signer entry to POL-01 in sddp-platform-config
#     (see ../sddp-platform-config/onboarding/), and
#   * the human merge of the resulting PR (the deploy gate).
set -euo pipefail

SVC="${1:-}"; shift || true
PORT=3000; HOST=""; DIGEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --port)   PORT="${2:-}"; shift 2;;
    --host)   HOST="${2:-}"; shift 2;;
    --digest) DIGEST="${2:-}"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

usage() { echo "usage: onboard.sh <svc> --digest <sha256:...> [--port n] [--host fqdn]" >&2; exit 2; }
[ -n "$SVC" ] || usage
[ -n "$DIGEST" ] || { echo "error: --digest is required (the first signed digest from the service's release run)" >&2; usage; }
case "$DIGEST" in
  sha256:[0-9a-f]*) : ;;
  *) echo "error: --digest must look like sha256:<64 hex>" >&2; exit 2;;
esac

TPL="$(cd "$(dirname "$0")/service-template" && pwd)"
OUT="manifests/${SVC}"
[ -d "$OUT" ] && { echo "error: ${OUT} already exists — is ${SVC} already onboarded?" >&2; exit 1; }
mkdir -p "$OUT"

stamp() { # <src> <dst>
  sed -e "s/__SVC__/${SVC}/g" \
      -e "s/__PORT__/${PORT}/g" \
      -e "s/__HOST__/${HOST}/g" \
      -e "s#__DIGEST__#${DIGEST}#g" \
      "$1" > "$2"
}

stamp "$TPL/deployment.yaml" "$OUT/deployment.yaml"
stamp "$TPL/service.yaml"    "$OUT/service.yaml"
stamp "$TPL/cnp.yaml"        "$OUT/cnp.yaml"
if [ -n "$HOST" ]; then
  stamp "$TPL/ingress.yaml"  "$OUT/ingress.yaml"
else
  echo "note: no --host → no Ingress (service stays in-cluster only)."
fi

echo "Wrote ${OUT}/:"
ls -1 "$OUT"
cat <<EOF

Next:
  1. Review + open a PR with ${OUT}/ — a human merge is the deploy gate.
  2. Add the signer entry to POL-01 in sddp-platform-config (reviewed trust act):
     see ../sddp-platform-config/onboarding/pol-01-signer-entry.snippet.yaml
EOF
[ -n "$HOST" ] && echo "  3. Create a DNS A record for ${HOST} -> the ingress LoadBalancer IP."
