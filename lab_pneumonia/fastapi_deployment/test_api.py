"""
Test script for FastAPI deployment
Example usage of the API endpoints
"""

import requests
import json

# Base URL
BASE_URL = "http://localhost:8000"

def test_health():
    """Test health check endpoint."""
    print("Testing health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print()

def test_root():
    """Test root endpoint."""
    print("Testing root endpoint...")
    response = requests.get(f"{BASE_URL}/")
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    print()

def test_predict(image_path):
    """Test prediction endpoint."""
    print(f"Testing predict endpoint with {image_path}...")
    
    try:
        with open(image_path, "rb") as f:
            files = {"file": f}
            response = requests.post(f"{BASE_URL}/predict", files=files)
        
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        print()
        return response.json()
    except FileNotFoundError:
        print(f"Error: File {image_path} not found")
        print()
        return None
    except Exception as e:
        print(f"Error: {e}")
        print()
        return None

if __name__ == "__main__":
    print("=" * 50)
    print("FastAPI Deployment - Test Script")
    print("=" * 50)
    print()
    
    # Test health check
    test_health()
    
    # Test root
    test_root()
    
    # Test prediction (replace with actual image path)
    # test_predict("path/to/xray.jpg")
    
    print("=" * 50)
    print("Tests completed!")
    print("=" * 50)

