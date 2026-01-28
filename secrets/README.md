# Secrets Management

Do not store secrets in Git. Use an encrypted secret store and rotate credentials regularly.

## Current Approach

- TODO: Document your chosen secret store (SOPS/age, Vault, 1Password, Bitwarden, etc.).
- TODO: Document how to decrypt and apply secrets during deploys.

## Minimum Standards

- Encrypt at rest and in transit.
- Separate secrets per environment (prod/dev/lab).
- Rotate on compromise or access change.

## Quick Start (SOPS Example)

- Store encrypted YAML under secrets/ using age keys.
- Keep age private keys out of the repo.
