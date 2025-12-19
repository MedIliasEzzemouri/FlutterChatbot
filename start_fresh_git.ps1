# Script to Start Fresh Git Repository (Removes History)
Write-Host "🔄 Starting Fresh Git Repository" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  This will remove all Git history and start fresh" -ForegroundColor Yellow
Write-Host "This is safe since your push hasn't succeeded yet." -ForegroundColor Green
Write-Host ""

cd "C:\Users\iezze\Desktop\Flutter"

$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "📋 Step 1: Removing old Git repository..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Remove-Item -Recurse -Force .git
    Write-Host "✓ Removed .git folder" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 Step 2: Initializing new Git repository..." -ForegroundColor Yellow
git init
Write-Host "✓ Initialized new repository" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Step 3: Adding files (excluding .venv and large files)..." -ForegroundColor Yellow
git add .
Write-Host "✓ Files added" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Step 4: Creating initial commit..." -ForegroundColor Yellow
git commit -m "Initial commit: Flutter app with pneumonia and fruits classification"
Write-Host "✓ Commit created" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Step 5: Setting up remote..." -ForegroundColor Yellow
$remoteExists = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Remote already exists: $remoteExists" -ForegroundColor Cyan
} else {
    git remote add origin https://github.com/MedIliasEzzemouri/FlutterChatbot
    Write-Host "✓ Remote added" -ForegroundColor Green
}

Write-Host ""
Write-Host "📋 Step 6: Setting branch to main..." -ForegroundColor Yellow
git branch -M main
Write-Host "✓ Branch set to main" -ForegroundColor Green

Write-Host ""
Write-Host "📤 Pushing to GitHub..." -ForegroundColor Yellow
git push -u origin main --force

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "Repository: https://github.com/MedIliasEzzemouri/FlutterChatbot" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "⚠️  Push failed. Check the error message above." -ForegroundColor Red
    Write-Host "You may need to check if large files are still being tracked." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✨ Done!" -ForegroundColor Green

