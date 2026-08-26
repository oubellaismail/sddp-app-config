# Onboarding — delivery-manifest templates

Parameterized templates + a generator for wiring a new paved-road service into
the `sddp-app` namespace. These files are **tooling** — they live outside
`manifests/`, so ArgoCD (which recurses `manifests/`) never tries to apply them.

## Use

From the repo root, once the service's first release has signed + promoted an
image (grab the digest from its release run summary):

```bash
./onboarding/onboard.sh widget --digest sha256:<64hex> --host widget.project-demo.tech
```

That stamps `manifests/widget/{deployment,service,cnp,ingress}.yaml` from
`service-template/`, substituting the service name, port, host, and digest.
ArgoCD auto-discovers `manifests/widget/` on merge.

## What the generator does NOT do (manual by design)

- **The POL-01 signer entry** — a reviewed trust decision, added by hand in
  `sddp-platform-config` (see its `onboarding/`).
- **The config-bump merge** — a human merges the PR; that is the deploy gate.

Both are deliberately human steps: automating them would defeat the controls.

## Templates

| File | Purpose | Params |
|------|---------|--------|
| `service-template/deployment.yaml` | non-root, small-tier Deployment on the signed digest | svc, port, digest |
| `service-template/service.yaml` | ClusterIP | svc, port |
| `service-template/cnp.yaml` | least-privilege network rules (ingress-reachable; egress example) | svc, port |
| `service-template/ingress.yaml` | TLS + rate-limited public route (only with `--host`) | svc, port, host |

The full step-by-step onboarding runbook lives in the platform docs.
