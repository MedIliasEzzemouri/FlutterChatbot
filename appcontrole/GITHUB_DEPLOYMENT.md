# GitHub Deployment Guide

This guide will help you deploy your Flutter app to GitHub.

## 📋 Prerequisites

1. **Git** installed on your system
   - Download from: https://git-scm.com/downloads
   - Verify: `git --version`

2. **GitHub Account**
   - Create at: https://github.com

## 🚀 Step-by-Step Deployment

### Step 1: Initialize Git Repository (if not already done)

```bash
cd C:\Users\iezze\Desktop\Flutter\appcontrole
git init
```

### Step 2: Check Current Status

```bash
git status
```

### Step 3: Add All Files (except those in .gitignore)

```bash
git add .
```

### Step 4: Create Initial Commit

```bash
git commit -m "Initial commit: Flutter app with pneumonia and fruits classification"
```

### Step 5: Create GitHub Repository

1. Go to https://github.com/new
2. Create a new repository:
   - **Repository name**: `appcontrole` (or your preferred name)
   - **Description**: "Flutter app for image classification with AI chatbot"
   - **Visibility**: Choose Public or Private
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
3. Click "Create repository"

### Step 6: Connect Local Repository to GitHub

After creating the repository, GitHub will show you commands. Use these:

```bash
# Add remote repository (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/appcontrole.git

# Or if using SSH:
# git remote add origin git@github.com:YOUR_USERNAME/appcontrole.git
```

### Step 7: Push to GitHub

```bash
# Push to main branch
git branch -M main
git push -u origin main
```

If you're using `master` branch:
```bash
git branch -M master
git push -u origin master
```

## 🔒 Important: Sensitive Files

**DO NOT commit these files to GitHub:**

- ✅ Already in `.gitignore`:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
  - `lib/firebase_options.dart`
  - `local.properties`
  - Build files and logs

**Before pushing, verify sensitive files are not tracked:**

```bash
# Check if sensitive files are being tracked
git ls-files | grep -E "(google-services|GoogleService|firebase_options)"
```

If any sensitive files show up, remove them:

```bash
# Remove from tracking (but keep local file)
git rm --cached android/app/google-services.json
git rm --cached lib/firebase_options.dart

# Commit the removal
git commit -m "Remove sensitive Firebase configuration files"
```

## 📝 Setting Up for Other Developers

Create a `SETUP.md` file with instructions for cloning and setting up:

### For New Developers:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/appcontrole.git
   cd appcontrole
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase:**
   - Get `google-services.json` from Firebase Console
   - Place in `android/app/google-services.json`
   - Get `GoogleService-Info.plist` for iOS
   - Place in `ios/Runner/GoogleService-Info.plist`
   - Run `flutterfire configure` to regenerate `firebase_options.dart`

4. **Configure API URL:**
   - Edit `lib/api_service.dart`
   - Update `baseUrl` for your platform

5. **Run the app:**
   ```bash
   flutter run
   ```

## 🔄 Updating the Repository

After making changes:

```bash
# Check what changed
git status

# Add changes
git add .

# Commit with descriptive message
git commit -m "Description of your changes"

# Push to GitHub
git push
```

## 🌿 Branching Strategy (Optional)

For better collaboration:

```bash
# Create a new branch for features
git checkout -b feature/new-feature

# Make changes, then commit
git add .
git commit -m "Add new feature"

# Push branch to GitHub
git push -u origin feature/new-feature

# Create Pull Request on GitHub, then merge to main
```

## 📦 Including lab_pneumonia Backend

If you want to include the backend code:

1. **Option 1: Separate Repository (Recommended)**
   - Create a separate repository for `lab_pneumonia`
   - Keep backend and frontend separate

2. **Option 2: Monorepo**
   - Add `lab_pneumonia` to the same repository
   - Update `.gitignore` if needed
   - Commit backend code:
     ```bash
     cd ..
     git add lab_pneumonia
     git commit -m "Add backend deployment code"
     git push
     ```

## 🛡️ Security Best Practices

1. **Never commit:**
   - API keys
   - Firebase configuration files
   - Passwords or secrets
   - Personal information

2. **Use Environment Variables:**
   - For API keys, use environment variables
   - Create a `.env.example` file as a template

3. **Review Before Committing:**
   ```bash
   git diff  # Review changes before committing
   ```

4. **Use GitHub Secrets:**
   - For CI/CD pipelines
   - Store sensitive data in GitHub Secrets

## 📚 Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com/)
- [Flutter CI/CD](https://docs.flutter.dev/deployment/ci-cd)

## ❓ Troubleshooting

### Problem: Authentication failed
```bash
# Use Personal Access Token instead of password
# Or set up SSH keys
```

### Problem: Large files
```bash
# Use Git LFS for large model files
git lfs install
git lfs track "*.tflite"
git add .gitattributes
```

### Problem: Wrong remote URL
```bash
# Check current remote
git remote -v

# Update remote URL
git remote set-url origin https://github.com/YOUR_USERNAME/appcontrole.git
```

---

**Happy Deploying! 🚀**

