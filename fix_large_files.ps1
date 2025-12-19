# Script to Fix Large Files Issue for GitHub
Write-Host "🔧 Fixing Large Files Issue" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

cd "C:\Users\iezze\Desktop\Flutter"

Write-Host "📋 Step 1: Removing virtual environment from Git tracking..." -ForegroundColor Yellow
git rm -r --cached lab_pneumonia/.venv/ 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Removed .venv from tracking" -ForegroundColor Green
} else {
    Write-Host "⚠️  .venv may not be tracked or already removed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Step 2: Removing large exe file from tracking..." -ForegroundColor Yellow
$exeFile = "appcontrole/assets/model/Install VALORANT.exe"
if (Test-Path $exeFile) {
    git rm --cached $exeFile 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Removed exe file from tracking" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Exe file may not be tracked" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Exe file not found (may already be removed)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Step 3: Adding .gitignore..." -ForegroundColor Yellow
git add .gitignore
Write-Host "✓ Added .gitignore" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Step 4: Checking status..." -ForegroundColor Yellow
$status = git status --short
if ($status) {
    Write-Host "Files to be committed:" -ForegroundColor Cyan
    $status | Select-Object -First 10
    if (($status | Measure-Object).Count -gt 10) {
        Write-Host "... and more files" -ForegroundColor Gray
    }
} else {
    Write-Host "No changes to commit" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💾 Ready to commit. Run these commands:" -ForegroundColor Cyan
Write-Host ""
Write-Host "git commit -m 'Remove virtual environment and large files from tracking'" -ForegroundColor White
Write-Host "git push -u origin main" -ForegroundColor White
Write-Host ""
Write-Host "Or press Enter to commit automatically..." -ForegroundColor Yellow
$response = Read-Host

if ([string]::IsNullOrWhiteSpace($response)) {
    Write-Host ""
    Write-Host "📝 Committing changes..." -ForegroundColor Yellow
    git commit -m "Remove virtual environment and large files from tracking"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Changes committed" -ForegroundColor Green
        Write-Host ""
        Write-Host "📤 Pushing to GitHub..." -ForegroundColor Yellow
        git push -u origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "⚠️  Push failed. Check the error message above." -ForegroundColor Red
        }
    } else {
        Write-Host "⚠️  Commit failed. Check the error message above." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✨ Done!" -ForegroundColor Green

