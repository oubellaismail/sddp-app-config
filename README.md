# sddp-app-config

Kubernetes manifests for the sample application, watched by ArgoCD.

Updated only via pull request from `sddp-app`'s CI (never a direct push — ADR-005), after the image has been scanned, signed, and merged. Every deploy is a reviewed Git commit here.

Design docs: see the `pfa` repo (particularly `adr-005-repo-structure.md`, `pipeline-design-spec.md` §3.12).
