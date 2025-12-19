# Cleaning Git History to Remove Large Files

## Problem
Even after removing files from the current commit, they remain in Git history, causing push failures.

## Solution: Remove from Entire History

### Option 1: Using git filter-branch (Built-in)

```powershell
cd C:\Users\iezze\Desktop\Flutter

# Remove .venv from entire history
git filter-branch --force --index-filter `
    "git rm -rf --cached --ignore-unmatch lab_pneumonia/.venv/" `
    --prune-empty --tag-name-filter cat -- --all

# Remove exe file from history
git filter-branch --force --index-filter `
    "git rm --cached --ignore-unmatch 'appcontrole/assets/model/Install VALORANT.exe'" `
    --prune-empty --tag-name-filter cat -- --all

# Clean up
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (safe since original push failed)
git push -u origin main --force
```

### Option 2: Start Fresh (Easier if you don't need history)

If you don't need the commit history:

```powershell
cd C:\Users\iezze\Desktop\Flutter

# Remove .git folder
Remove-Item -Recurse -Force .git

# Reinitialize
git init
git add .
git commit -m "Initial commit: Flutter app with pneumonia and fruits classification"

# Add remote
git remote add origin https://github.com/MedIliasEzzemouri/FlutterChatbot

# Push
git branch -M main
git push -u origin main --force
```

### Option 3: Use BFG Repo-Cleaner (Fastest)

1. Download BFG: https://rtyley.github.io/bfg-repo-cleaner/
2. Run:
```powershell
java -jar bfg.jar --delete-folders .venv
java -jar bfg.jar --delete-files "Install VALORANT.exe"
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push -u origin main --force
```

## Recommended: Use the Script

Run the provided script:
```powershell
.\remove_large_files_from_history.ps1
```

Then force push:
```powershell
git push -u origin main --force
```

## Why --force is Safe Here

Since your original push was rejected, no one else has pulled your changes. Using `--force` is safe because:
- The remote repository only has the initial README
- No one else is working on this branch
- You're essentially replacing the failed push attempt

