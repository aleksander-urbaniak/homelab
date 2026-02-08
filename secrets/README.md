# 🔐 Secrets Management ✨

This repo does not store real secrets. Use a password manager and keep encrypted
values out of Git.

## 🧭 Current Approach

- **Password manager**: Vaultwarden (unofficial Bitwarden) is used for storing
  passwords, API keys, and recovery codes.
- **Docker**: `.env` files are the local credentials/token handler for Docker
  Compose apps. Real `.env` files are excluded from Git; only `.env.example`
  templates with placeholders are committed.
- **Kubernetes**: K8s Secrets contain the same values as the Docker `.env`
  files (same keys, same sources), but are applied as Kubernetes resources.

## ✅ Minimum Standards

- Never commit secrets, tokens, or private keys to Git (even in examples).
- Use unique credentials per app and per environment (lab/dev/prod).
- Rotate on compromise, access change, or vendor breach.
- Prefer short-lived tokens where possible.
- Use least privilege for service accounts and API keys.

## 🛡️ Good Security Practices

- **Use strong secrets**: 24+ char random passwords or long passphrases.
- **Template everything**: keep `.env.example` with `REPLACE_ME` placeholders.
- **Access control**: restrict Vaultwarden access and enable 2FA.
- **Backups**: back up Vaultwarden (database + attachments) and test restores.
- **Audit**: review who has access to the password manager and revoke stale
  accounts.
- **K8s note**: Kubernetes Secrets are base64-encoded, not encrypted. Use
  cluster-level encryption-at-rest if available and restrict RBAC.
- **Filesystem hygiene**: store real `.env` files outside the repo or in an
  ignored directory, and lock down permissions.
- **Secret scanning**: use pre-commit hooks or CI scanning to catch leaks.
