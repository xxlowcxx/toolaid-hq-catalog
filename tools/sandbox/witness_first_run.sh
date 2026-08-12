#!/usr/bin/env bash
# FIRST LEGIT USE — run with LowC watching. Non-destructive.
set -euo pipefail
echo "=============================================="
echo "  SIREN HQ — WITNESS FIRST RUN"
echo "  $(date -Is)"
echo "=============================================="
echo
echo "[1/5] Disk / free space"
df -h /home / 2>/dev/null | head -5
echo
echo "[2/5] Catalog packs"
ls -lh "$HOME/Projects/homebase/catalog/downloads" | head -20
echo
echo "[3/5] Project scoreboard"
for d in "$HOME/Projects/repos"/*; do
  [[ -d "$d" ]] || continue
  printf '  - %s\n' "$(basename "$d")"
done
echo
echo "[4/5] Burn Box limits API (if vault running on :5000)"
if curl -sf --max-time 2 http://127.0.0.1:5000/api/limits >/tmp/bb-limits.json 2>/dev/null; then
  cat /tmp/bb-limits.json
  echo
else
  echo "  (vault not running — start with: cd ~/Projects/repos/burn-box-stage-1 && npm run dev)"
fi
echo
echo "[5/5] Sandbox tools present"
ls -la "$HOME/Projects/homebase/tools/sandbox"
echo
echo "=============================================="
echo "  WITNESS COMPLETE — no files were destroyed."
echo "  Catalog: ~/Projects/homebase/catalog/"
echo "  Desktop: toolaid-catalog.desktop"
echo "=============================================="
