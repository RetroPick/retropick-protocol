# Upstream Provenance

## Git Metadata (Extracted from nested .git)

```
[core]
    repositoryformatversion = 1
    filemode = true
    bare = false
    logallrefupdates = true
[remote "origin"]
    url = git@github.com:ponsdotdev/pons-labs.git
    fetch = +refs/heads/main:refs/remotes/origin/main
    promisor = true
    partialclonefilter = blob:none
[branch "main"]
    remote = origin
    merge = refs/heads/main
```

## Commit Identity

**HEAD:** `162310fbd1217717e2f5e4cde794d6a11322b469`  
**refs/heads/main:** `162310fbd1217717e2f5e4cde794d6a11322b469`  
**refs/remotes/origin/main:** `162310fbd1217717e2f5e4cde794d6a11322b469`  

## Clone Record

```
0000000000000000000000000000000000000000 162310fbd1217717e2f5e4cde794d6a11322b469 ubuntu <ubuntu@Ubuntu-VPS-Clone.localdomain> 1789712824 +0700	clone: from github.com:ponsdotdev/pons-labs.git
```

**Clone timestamp:** 2025-01-18 06:27:04 +0700  
**Original source:** github.com:ponsdotdev/pons-labs.git  

## Verification Status

- ✓ Commit SHA verified across HEAD, main branch, and origin/main
- ⚠️  Partial clone prevents full tree verification against upstream  
- ⚠️  No build metadata or dependency version locks available upstream
- ⚠️  Missing LICENSE files despite SPDX headers in source code

## Authority

This migration pins content by SHA-256 hash of retained files rather than by git tree identity due to the partial clone limitation. The commit SHA `162310fb...` serves as supplemental provenance evidence only.