# Script to Remove Large Files from Git History
Write-Host "🔧 Removing Large Files from Git History" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  WARNING: This will rewrite Git history!" -ForegroundColor Red
Write-Host "This is safe if you haven't pushed successfully yet." -ForegroundColor Yellow
Write-Host ""

cd "C:\Users\iezze\Desktop\Flutter"

# Check if git-filter-repo is available (better tool)
$hasFilterRepo = Get-Command git-filter-repo -ErrorAction SilentlyContinue

if (-not $hasFilterRepo) {
    Write-Host "📋 Using git filter-branch to remove large files..." -ForegroundColor Yellow
    Write-Host ""
    
    # Remove .venv from entire history
    Write-Host "Removing lab_pneumonia/.venv/ from history..." -ForegroundColor Cyan
    git filter-branch --force --index-filter `
        "git rm -rf --cached --ignore-unmatch lab_pneumonia/.venv/" `
        --prune-empty --tag-name-filter cat -- --all 2>&1 | Out-Null
    
    # Remove exe file from history
    Write-Host "Removing Install VALORANT.exe from history..." -ForegroundColor Cyan
    git filter-branch --force --index-filter `
        "git rm --cached --ignore-unmatch 'appcontrole/assets/model/Install VALORANT.exe'" `
        --prune-empty --tag-name-filter cat -- --all 2>&1 | Out-Null
    
    Write-Host ""
    Write-Host "✓ History rewritten" -ForegroundColor Green
} else {
    Write-Host "📋 Using git-filter-repo (recommended)..." -ForegroundColor Yellow
    git filter-repo --path lab_pneumonia/.venv --invert-paths
    git filter-repo --path "appcontrole/assets/model/Install VALORANT.exe" --invert-paths
}

Write-Host ""
Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow

# Clean up refs
git for-each-ref --format="delete %(refname)" refs/original | git update-ref --stdin 2>&1 | Out-Null

# Expire reflog and garbage collect
git reflog expire --expire=now --all 2>&1 | Out-Null
git gc --prune=now --aggressive 2>&1 | Out-Null

Write-Host "✓ Cleanup complete" -ForegroundColor Green

Write-Host ""
Write-Host "📤 Ready to push. Run:" -ForegroundColor Cyan
Write-Host "git push -u origin main --force" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Note: Using --force is safe here since the push hasn't succeeded yet" -ForegroundColor Yellow

