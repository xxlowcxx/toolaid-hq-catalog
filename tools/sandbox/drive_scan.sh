#!/usr/bin/env bash
# Scan mounted drives for Toolaid workspaces + free space report
set -euo pipefail
echo "=== mounts ==="
df -hT | head -1
df -hT | rg -v 'tmpfs|devtmpfs|overlay|squashfs' || df -h
echo
echo "=== USB / removable ==="
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,LABEL,FSTYPE 2>/dev/null || true
echo
echo "=== toolaid paths ==="
for p in "$HOME/Projects" "$HOME/Projects/homebase" "$HOME/Projects/repos" "$HOME/Projects/archives" /mnt /media; do
  if [[ -e "$p" ]]; then
    echo "-- $p"
    du -sh "$p" 2>/dev/null || true
  fi
done
echo
echo "=== catalog ==="
ls -lh "$HOME/Projects/homebase/catalog/downloads" 2>/dev/null | head -30
