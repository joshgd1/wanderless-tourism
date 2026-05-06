# DISCOVERY: `.renderignore` With `*.py` Silently Blocked Backend Deployment

## Problem

After pushing a fix to `backend/main.py` (route ordering fix, commit `218f469`), Render rebuilt but the fix was not applied. The `/api/guides/open-requests` endpoint still returned "Guide not found".

## Root Cause

The `.renderignore` file contained `*.py`, which caused **all Python files** — including `backend/main.py` — to be excluded from the Render deployment artifact upload. The fix was committed and pushed, but the fixed code was never uploaded to Render.

```bash
# What Render saw during deployment:
backend/
  main.py   ← EXCLUDED by *.py pattern
  models.py  ← EXCLUDED
  ...

# What Render deployed (old code from last successful upload):
backend/    ← directory exists but main.py is stale
  main.py   ← old version without the fix
```

## The `.renderignore` Pattern

Render uses `.renderignore` to exclude files from the deployment upload (similar to `.dockerignore`). The pattern `*.py` matches all Python files recursively.

**Original `.renderignore`:**

```
requirements.txt
conftest.py
*.py          ← BLOCKED ALL PYTHON FILES
.pytest_cache
__pycache__
.venv
venv/
```

## Fix

Remove `*.py` from `.renderignore` and explicitly list what should be ignored:

```bash
# Corrected .renderignore:
# Backend files ARE deployed — do NOT ignore backend/
requirements.txt
conftest.py
.pytest_cache
__pycache__
.venv
venv/
# Flutter (these ARE excluded)
app/
node_modules/
docs/
.github/
```

Key change: removing `*.py` allows `backend/main.py` and other Python files to be uploaded. The comment `# Backend files ARE deployed — do NOT ignore backend/` documents intent.

## Why It Looked Like It Was Deploying

Render showed "Build successful" after each push. The build succeeded — but the **upload** was silently skipping the Python files. Render's build log did not clearly indicate which files were excluded.

Detection: We had to monitor the endpoint response over time (polling) to realize the fix wasn't live, and then trace through the `.renderignore` to find the cause.

## Two-Layer Bug

This was a **two-layer deployment failure**:

1. **Code bug**: Route ordering in FastAPI (`218f469`)
2. **Deployment bug**: `.renderignore` excluded the fixed code (`02296b9`)

Both had to be fixed together for the endpoint to work.

## Pattern: Platform Ignore Files Can Silence Deployment

Platform-specific ignore files (`.renderignore`, `.dockerignore`, `.gitignore`) can silently prevent deployment of critical files. The symptoms (code doesn't update) are non-obvious because:

- CI shows "success"
- The file exists locally and in git
- The platform's build log doesn't clearly call out exclusions

**Prevention**: When pushing a code fix that doesn't appear in production after a successful deploy, check `.renderignore` / `.dockerignore` / platform-specific upload exclusion files first.

## Render Deployment Stack

- **Backend**: FastAPI on Render, `web: cd backend && PYTHONPATH=.. uvicorn main:app --host 0.0.0.0 --port $PORT`
- **Frontend**: Flutter web, served separately
- **Database**: Render-managed PostgreSQL (persistent)
- **Auto-deploy**: On every `git push` to `main`

## Files Changed

- `.renderignore` — removed `*.py`, added clarifying comment

## Commits

- `02296b9` — `.renderignore` fix (deploy layer)
- `218f469` — route ordering fix (code layer)
