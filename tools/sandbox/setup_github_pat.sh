#!/usr/bin/env bash
# Siren HQ — GitHub PAT setup helper
# GitHub does NOT allow minting PATs without YOUR login.
# This tool: opens the create page, stores the token securely, verifies API access.
set -euo pipefail

SECRETS_DIR="${TOOLAID_HOMEBASE:-$HOME/Projects/homebase}/.secrets"
CRED_FILE="$SECRETS_DIR/git-credentials"
OWNER="${GITHUB_OWNER:-xxlowcxx}"
FINE_URL="https://github.com/settings/tokens?type=beta"
CLASSIC_URL="https://github.com/settings/tokens"

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

echo "=============================================="
echo "  SIREN — GitHub PAT setup"
echo "=============================================="
echo
echo "I cannot invent a PAT. Only YOUR GitHub session can create one."
echo "This tool walks you through it and saves it for Siren/git."
echo
echo "Recommended: Fine-grained token"
echo "  Resource owner: $OWNER"
echo "  Repos: burn-box-stage-1, toolaid-hq-catalog (+ others as needed)"
echo "  Permission: Contents = Read and write"
echo
echo "Opening GitHub token page in browser (if available)..."
if command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$FINE_URL" >/dev/null 2>&1 || true
elif command -v firefox >/dev/null 2>&1; then
  firefox "$FINE_URL" >/dev/null 2>&1 &
else
  echo "Open manually: $FINE_URL"
fi
echo
echo "Classic (fallback): $CLASSIC_URL  (scope: repo)"
echo
echo "After Generate, copy the token (github_pat_... or ghp_...)."
echo

# Non-interactive path: TOKEN env or first arg
TOKEN="${1:-${GITHUB_PAT:-${GH_TOKEN:-}}}"
if [[ -z "$TOKEN" ]]; then
  if [[ -t 0 ]]; then
    read -r -s -p "Paste token (input hidden), then Enter: " TOKEN
    echo
  else
    echo "ERROR: No token provided and not a TTY."
    echo "Usage:"
    echo "  $0"
    echo "  $0 'github_pat_...'"
    echo "  GITHUB_PAT='github_pat_...' $0"
    exit 1
  fi
fi

# Strip whitespace / accidental newlines
TOKEN="$(printf '%s' "$TOKEN" | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: empty token"
  exit 1
fi

# Accept full credential URL form
if [[ "$TOKEN" == https://*@github.com* ]]; then
  TOKEN="$(printf '%s' "$TOKEN" | sed -n 's#^https://[^:]*:\([^@]*\)@github.com.*#\1#p')"
fi

if [[ ! "$TOKEN" =~ ^(ghp_|github_pat_|gho_|ghu_|ghs_) ]]; then
  echo "WARNING: token does not look like a GitHub token prefix (ghp_/github_pat_/...)."
  echo "Continuing anyway..."
fi

# Verify with GitHub API
echo "Verifying token with api.github.com/user ..."
HTTP=$(curl -sS -o /tmp/gh-user.json -w "%{http_code}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "User-Agent: siren-hq-pat-setup" \
  https://api.github.com/user || true)

if [[ "$HTTP" != "200" ]]; then
  echo "VERIFY FAILED (HTTP $HTTP). Response:"
  head -c 400 /tmp/gh-user.json 2>/dev/null; echo
  echo "Token not saved."
  exit 2
fi

LOGIN=$(python3 -c "import json; print(json.load(open('/tmp/gh-user.json')).get('login',''))" 2>/dev/null || true)
echo "OK — authenticated as: ${LOGIN:-unknown}"

# Check repo write probe (metadata)
for REPO in burn-box-stage-1 toolaid-hq-catalog; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "User-Agent: siren-hq-pat-setup" \
    "https://api.github.com/repos/${OWNER}/${REPO}" || true)
  echo "  repo $OWNER/$REPO → HTTP $code"
done

# Save credential line for git
LINE="https://${LOGIN:-$OWNER}:${TOKEN}@github.com"
umask 077
printf '%s\n' "$LINE" > "$CRED_FILE"
chmod 600 "$CRED_FILE"
echo
echo "Saved (mode 600): $CRED_FILE"

# Wire git credential helper for this user if not already
git config --global credential.helper "store --file $CRED_FILE" 2>/dev/null || true
echo "git credential.helper → store --file $CRED_FILE"

# Also export path note for Siren
printf '%s\n' "$CRED_FILE" > "$SECRETS_DIR/git-credentials.path"
chmod 600 "$SECRETS_DIR/git-credentials.path"

echo
echo "=============================================="
echo "  PAT setup complete. You can tell Siren: push"
echo "=============================================="
echo "Test push (optional):"
echo "  cd ~/Projects/repos/burn-box-stage-1 && git push origin main"
