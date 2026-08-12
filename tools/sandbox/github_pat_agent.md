# GitHub PAT agent (what it can / cannot do)

## Cannot (GitHub policy + security)

- Create a PAT **without you logged into GitHub**
- Steal or invent your password
- Use device-flow for you if you never complete the browser step

## Can (this tool)

1. Open the fine-grained token page
2. Accept the token you paste (or `GITHUB_PAT=...`)
3. Verify with `api.github.com/user`
4. Save to `~/Projects/homebase/.secrets/git-credentials` (chmod 600)
5. Point git `credential.helper` at that file

## Run

```bash
~/Projects/homebase/tools/sandbox/setup_github_pat.sh
# or
GITHUB_PAT='github_pat_xxx' ~/Projects/homebase/tools/sandbox/setup_github_pat.sh
```

## After setup

Tell Siren: **push** or **finish burn box**
