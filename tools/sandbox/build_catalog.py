#!/usr/bin/env python3
"""Rebuild Toolaid catalog packs. Safe on low disk: excludes node_modules/venv/media."""
import os, json, zipfile
from pathlib import Path
from datetime import datetime, timezone
from collections import Counter

CAT = Path.home() / "Projects/homebase/catalog"
DOWNLOADS = CAT / "downloads"
DOWNLOADS.mkdir(parents=True, exist_ok=True)
REPOS = Path.home() / "Projects/repos"
EXCLUDE = {".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build",
           "catalog/downloads", ".secrets", "token.txt", "github_token.enc"}

def skip(p: Path) -> bool:
    return bool(set(p.parts) & EXCLUDE) or p.name in EXCLUDE

def pack_tree(root: Path, zpath: Path, skip_catalog_dl=False) -> dict:
    n = 0
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in root.rglob("*"):
            if not f.is_file() or skip(f):
                continue
            if skip_catalog_dl and "catalog/downloads" in str(f):
                continue
            try:
                if f.stat().st_size > 25_000_000:
                    continue
            except OSError:
                continue
            zf.write(f, arcname=str(f.relative_to(root)))
            n += 1
    return {"project": root.name, "zip": str(zpath), "files_packed": n, "bytes": zpath.stat().st_size}

packs = []
for proj in sorted(REPOS.iterdir()):
    if proj.is_dir() and not proj.name.startswith("."):
        packs.append(pack_tree(proj, DOWNLOADS / f"{proj.name}-source.zip"))
hb = Path.home() / "Projects/homebase"
packs.append(pack_tree(hb, DOWNLOADS / "homebase-source.zip", skip_catalog_dl=True))
(DOWNLOADS / "PACK_INDEX.json").write_text(json.dumps(packs, indent=2))
print(json.dumps(packs, indent=2))
print("OK", datetime.now(timezone.utc).isoformat())
