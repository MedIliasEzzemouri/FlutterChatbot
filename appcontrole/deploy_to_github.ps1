# GitHub Deployment Script for Windows PowerShell
# Run this script to deploy your Flutter app to GitHub

Write-Host "🚀 GitHub Deployment Script" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Check if git is installed
try {
    $gitVersion = git --version
    Write-Host "✓ Git found: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Git is not installed. Please install Git first." -ForegroundColor Red
    Write-Host "Download from: https://git-scm.com/downloads" -ForegroundColor Yellow
    exit 1
}

# Navigate to project directory
$projectDir = $PSScriptRoot
Set-Location $projectDir
Write-Host "📁 Project directory: $projectDir" -ForegroundColor Cyan
Write-Host ""

# Check if .git exists
if (Test-Path ".git") {
    Write-Host "✓ Git repository already initialized" -ForegroundColor Green
} else {
    Write-Host "📦 Initializing Git repository..." -ForegroundColor Yellow
    git init
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Git repository initialized" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to initialize Git repository" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "📋 Checking for sensitive files..." -ForegroundColor Yellow

# Check for sensitive files
$sensitiveFiles = @(
    "android\app\google-services.json",
    "ios\Runner\GoogleService-Info.plist",
    "lib\firebase_options.dart"
)

$foundSensitive = $false
foreach ($file in $sensitiveFiles) {
    if (Test-Path $file) {
        Write-Host "⚠️  Found: $file" -ForegroundColor Yellow
        Write-Host "   This file should be in .gitignore" -ForegroundColor Yellow
        $foundSensitive = $true
    }
}

if ($foundSensitive) {
    Write-Host ""
    Write-Host "⚠️  WARNING: Sensitive files detected!" -ForegroundColor Red
    Write-Host "Please verify these files are in .gitignore before proceeding." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "📝 Checking git status..." -ForegroundColor Yellow
git status --short

Write-Host ""
Write-Host "📦 Adding files to staging..." -ForegroundColor Yellow
git add .

Write-Host ""
Write-Host "💾 Creating commit..." -ForegroundColor Yellow
$commitMessage = Read-Host "Enter commit message (or press Enter for default)"
if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "Initial commit: Flutter app with pneumonia and fruits classification"
}

git commit -m $commitMessage

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  No changes to commit or commit failed" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🔗 Setting up remote repository..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Please create a repository on GitHub first:" -ForegroundColor Cyan
Write-Host "1. Go to https://github.com/new" -ForegroundColor Cyan
Write-Host "2. Create a new repository" -ForegroundColor Cyan
Write-Host "3. Copy the repository URL" -ForegroundColor Cyan
Write-Host ""

$repoUrl = Read-Host "Enter your GitHub repository URL (e.g., https://github.com/username/appcontrole.git)"

if ([string]::IsNullOrWhiteSpace($repoUrl)) {
    Write-Host "⚠️  No repository URL provided. Skipping remote setup." -ForegroundColor Yellow
    Write-Host "You can add it later with: git remote add origin <URL>" -ForegroundColor Yellow
} else {
    # Check if remote already exists
    $remoteExists = git remote get-url origin 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "⚠️  Remote 'origin' already exists: $remoteExists" -ForegroundColor Yellow
        $update = Read-Host "Update it? (y/N)"
        if ($update -eq "y" -or $update -eq "Y") {
            git remote set-url origin $repoUrl
            Write-Host "✓ Remote updated" -ForegroundColor Green
        }
    } else {
        git remote add origin $repoUrl
        Write-Host "✓ Remote added" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📤 Pushing to GitHub..." -ForegroundColor Yellow
    
    # Check current branch
    $branch = git branch --show-current
    if ([string]::IsNullOrWhiteSpace($branch)) {
        $branch = "main"
        git branch -M main
    }
    
    Write-Host "Pushing to branch: $branch" -ForegroundColor Cyan
    git push -u origin $branch
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Successfully deployed to GitHub!" -ForegroundColor Green
        Write-Host "Repository: $repoUrl" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "⚠️  Push failed. You may need to:" -ForegroundColor Yellow
        Write-Host "1. Set up authentication (Personal Access Token or SSH)" -ForegroundColor Yellow
        Write-Host "2. Check your repository URL" -ForegroundColor Yellow
        Write-Host "3. Try: git push -u origin $branch" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✨ Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Verify your repository on GitHub" -ForegroundColor White
Write-Host "2. Check that sensitive files are not committed" -ForegroundColor White
Write-Host "3. Update README if needed" -ForegroundColor White
Write-Host ""

