# Smart App - AppControle

A Flutter application for image classification (Pneumonia and Fruits) with an AI-powered chatbot. This app connects to a FastAPI backend deployment for model inference.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Running the Application](#running-the-application)
- [Configuration](#configuration)
- [API Endpoints](#api-endpoints)
- [Troubleshooting](#troubleshooting)

## ✨ Features

- **Pneumonia Classification**: Classify chest X-ray images for pneumonia detection
- **Fruits Classification**: Classify fruit images using TensorFlow Lite models
- **EMSI ChatBot**: AI-powered chatbot with RAG (Retrieval-Augmented Generation) and web search capabilities
- **Firebase Authentication**: User login and registration
- **Cross-Platform**: Supports Android, iOS, Web, Windows, macOS, and Linux

## 📦 Prerequisites

Before running this project, make sure you have the following installed:

### Required Software

1. **Flutter SDK** (3.9.2 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter doctor`

2. **Python 3.8+** (for backend deployment)
   - Download from: https://www.python.org/downloads/

3. **Firebase Account** (for authentication)
   - Create a project at: https://console.firebase.google.com/

4. **IDE** (optional but recommended)
   - Android Studio / IntelliJ IDEA
   - VS Code with Flutter extensions

### Backend Dependencies

The backend requires Python packages (automatically installed via requirements.txt):
- FastAPI
- Uvicorn
- TensorFlow/Keras
- Pillow
- NumPy

## 📁 Project Structure

```
Flutter/
├── appcontrole/              # Flutter application
│   ├── lib/
│   │   ├── main.dart         # App entry point with routes
│   │   ├── api_service.dart  # API client for backend
│   │   ├── home_page.dart    # Main home screen
│   │   ├── login_page.dart   # Login screen
│   │   ├── register_page.dart # Registration screen
│   │   ├── pneumonia_classifier_page.dart
│   │   ├── fruits_classifier_page.dart
│   │   ├── chatbot_page.dart
│   │   └── services/        # AI services (LLM, RAG, etc.)
│   ├── assets/
│   │   ├── images/           # App images and logos
│   │   └── model/            # TensorFlow Lite models
│   └── pubspec.yaml          # Flutter dependencies
│
└── lab_pneumonia/             # Backend deployment code
    └── fastapi_deployment/    # FastAPI server
        ├── main.py           # FastAPI app and endpoints
        ├── fruits_endpoint.py # Fruits classification endpoint
        ├── requirements.txt # Python dependencies
        └── shared_utils.py  # Shared utilities
```

## 🚀 Setup Instructions

### Step 1: Clone or Download the Project

```bash
cd C:\Users\iezze\Desktop\Flutter
```

### Step 2: Set Up Flutter Dependencies

1. Navigate to the Flutter app directory:
   ```bash
   cd appcontrole
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

### Step 3: Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Enable **Authentication** → **Email/Password** sign-in method
4. Download `google-services.json` for Android:
   - Project Settings → Your apps → Android app
   - Place it in `appcontrole/android/app/google-services.json`
5. For iOS, download `GoogleService-Info.plist` and add it to `ios/Runner/`

### Step 4: Set Up Backend (lab_pneumonia)

1. Navigate to the backend directory:
   ```bash
   cd ../lab_pneumonia/fastapi_deployment
   ```

2. Create a virtual environment (recommended):
   ```bash
   python -m venv venv
   
   # On Windows:
   venv\Scripts\activate
   
   # On macOS/Linux:
   source venv/bin/activate
   ```

3. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Ensure model files are in the correct location:
   - The pneumonia model should be accessible via `shared_utils.py`
   - Check the model path in `shared_utils.py` if needed

### Step 5: Configure API URL

Edit `appcontrole/lib/api_service.dart` and update the `baseUrl` based on your platform:

```dart
static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
// For iOS simulator: 'http://localhost:8000'
// For physical device: 'http://YOUR_COMPUTER_IP:8000'
// For web: 'http://localhost:8000'
```

**To find your computer's IP address:**
- Windows: `ipconfig` (look for IPv4 Address)
- macOS/Linux: `ifconfig` or `ip addr`

## 🏃 Running the Application

### Start the Backend Server

1. Navigate to the backend directory:
   ```bash
   cd lab_pneumonia/fastapi_deployment
   ```

2. Activate virtual environment (if using one):
   ```bash
   # Windows:
   venv\Scripts\activate
   
   # macOS/Linux:
   source venv/bin/activate
   ```

3. Start the FastAPI server:
   ```bash
   uvicorn main:app --reload
   ```

   The server will start at `http://localhost:8000`
   - API docs available at: `http://localhost:8000/docs`
   - Health check: `http://localhost:8000/health`

### Run the Flutter App

1. Navigate to the Flutter app directory:
   ```bash
   cd appcontrole
   ```

2. Check available devices:
   ```bash
   flutter devices
   ```

3. Run the app:
   ```bash
   # For Android:
   flutter run
   
   # For iOS:
   flutter run -d ios
   
   # For Web:
   flutter run -d chrome
   
   # For a specific device:
   flutter run -d <device-id>
   ```

## ⚙️ Configuration

### API Service Configuration

The API service is configured in `lib/api_service.dart`. The app connects to:
- **Health Check**: `GET /health`
- **Pneumonia Prediction**: `POST /predict`
- **Fruits Prediction**: `POST /fruits/predict`

### Firebase Configuration

Firebase is configured in:
- `lib/firebase_options.dart` (auto-generated)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### Routes

The app uses named routes defined in `lib/main.dart`:
- `/login` - Login page
- `/register` - Registration page
- `/home` - Home page
- `/pneumonia` - Pneumonia classifier
- `/fruits` - Fruits classifier
- `/chatbot` - AI chatbot

## 🔌 API Endpoints

The FastAPI backend provides the following endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API information |
| `/health` | GET | Health check |
| `/predict` | POST | Pneumonia classification |
| `/fruits/predict` | POST | Fruits classification |
| `/docs` | GET | Interactive API documentation |

## 🐛 Troubleshooting

### Backend Issues

**Problem**: API server not responding
- **Solution**: Make sure the FastAPI server is running on port 8000
- Check: `http://localhost:8000/health`

**Problem**: Model not loading
- **Solution**: Verify model files exist and paths are correct in `shared_utils.py`
- Check Python dependencies: `pip install -r requirements.txt`

**Problem**: CORS errors
- **Solution**: The FastAPI app already has CORS enabled. If issues persist, check the CORS middleware configuration in `main.py`

### Flutter App Issues

**Problem**: Cannot connect to API
- **Solution**: 
  - Verify the `baseUrl` in `api_service.dart` matches your setup
  - For physical devices, ensure your phone and computer are on the same network
  - Check firewall settings

**Problem**: Firebase authentication not working
- **Solution**:
  - Verify `google-services.json` is in the correct location
  - Check Firebase project settings
  - Ensure Email/Password authentication is enabled

**Problem**: Models not found
- **Solution**: 
  - Verify model files exist in `assets/model/`
  - Check `pubspec.yaml` includes the assets folder
  - Run `flutter pub get` and rebuild

**Problem**: Build errors
- **Solution**:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

### Platform-Specific Issues

**Android Emulator**:
- Use `http://10.0.2.2:8000` (default)
- This is the special IP that maps to `localhost` on the host machine

**iOS Simulator**:
- Use `http://localhost:8000`

**Physical Device**:
- Use your computer's IP address (e.g., `http://192.168.1.100:8000`)
- Ensure device and computer are on the same Wi-Fi network

**Web**:
- Use `http://localhost:8000`
- May need to configure CORS for web requests

## 🚀 GitHub Deployment

To deploy this project to GitHub, see the detailed guide in [GITHUB_DEPLOYMENT.md](GITHUB_DEPLOYMENT.md).

**Quick Start:**
```bash
# Initialize git (if not already done)
git init

# Add files
git add .

# Commit
git commit -m "Initial commit"

# Add remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/appcontrole.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**⚠️ Important:** Make sure sensitive files (Firebase config, API keys) are in `.gitignore` before pushing!

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [GitHub Deployment Guide](GITHUB_DEPLOYMENT.md)

## 📝 Notes

- The pneumonia classifier is for **educational purposes only** and should not be used for actual medical diagnosis
- Make sure to start the backend server before running the Flutter app
- For production deployment, configure proper security settings and API keys
- The chatbot uses MistralAI API - ensure you have valid API keys if using that feature

## 🤝 Contributing

If you encounter any issues or have suggestions, please check the project structure and ensure all dependencies are properly installed.

---

**Happy Coding! 🚀**
