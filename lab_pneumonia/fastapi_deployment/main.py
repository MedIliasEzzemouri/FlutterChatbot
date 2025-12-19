"""
FastAPI Deployment for Pneumonia Classification
Provides REST API endpoints for image classification
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import io
import sys
import os

# Add parent directory to path to import shared_utils
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from shared_utils import load_pneumonia_model, load_class_names, classify_image

# Import fruits endpoint
try:
    import fruits_endpoint
    from fruits_endpoint import router as fruits_router, load_fruits_model
    FRUITS_AVAILABLE = True
    print("✓ Fruits endpoint module imported successfully")
except ImportError as e:
    print(f"Warning: Fruits endpoint not available. Error: {e}")
    print("Install fruits_endpoint.py to enable fruits classification.")
    FRUITS_AVAILABLE = False
    fruits_endpoint = None

# Initialize FastAPI app
app = FastAPI(
    title="Image Classification API",
    description="API for classifying images: Pneumonia (chest X-rays) and Fruits",
    version="1.0.0"
)

# Include fruits router if available
if FRUITS_AVAILABLE:
    app.include_router(fruits_router)
    print("✓ Fruits endpoint enabled at /fruits/predict")
    print(f"[DEBUG] fruits_endpoint module: {fruits_endpoint}")
    print(f"[DEBUG] fruits_endpoint.fruits_model before startup: {fruits_endpoint.fruits_model if hasattr(fruits_endpoint, 'fruits_model') else 'NOT FOUND'}")
else:
    print("✗ Fruits endpoint NOT available")

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model and class names at startup
model = None
class_names = None

@app.on_event("startup")
async def load_model():
    """Load the models and class names when the application starts."""
    global model, class_names
    try:
        # Load pneumonia model
        model = load_pneumonia_model()
        class_names = load_class_names()
        print("Pneumonia model loaded successfully!")
        
        # Load fruits model if available
        if FRUITS_AVAILABLE and fruits_endpoint is not None:
            try:
                print("\n" + "="*60)
                print("="*60)
                print("LOADING FRUITS MODEL IN STARTUP EVENT")
                print("="*60)
                print(f"[DEBUG] FRUITS_AVAILABLE: {FRUITS_AVAILABLE}")
                print(f"[DEBUG] fruits_endpoint module exists: {fruits_endpoint is not None}")
                print(f"[DEBUG] load_fruits_model function: {load_fruits_model}")
                print("="*60)
                
                result = load_fruits_model()
                
                # Also check the module's global variable directly
                print(f"\n[DEBUG] After load_fruits_model() call:")
                print(f"  - Result is None: {result is None}")
                print(f"  - Result type: {type(result)}")
                print(f"  - fruits_endpoint.fruits_model is None: {fruits_endpoint.fruits_model is None}")
                print(f"  - fruits_endpoint.fruits_model type: {type(fruits_endpoint.fruits_model)}")
                
                if result is None:
                    print("="*60)
                    print("⚠️  WARNING: Fruits model failed to load!")
                    print("Check error messages above for details.")
                    print("="*60)
                else:
                    print("="*60)
                    print("✅ Fruits model loaded successfully in startup event!")
                    print(f"Model type: {type(result)}")
                    print(f"Module's fruits_model variable: {fruits_endpoint.fruits_model is not None}")
                    print("="*60)
            except Exception as e:
                print("="*60)
                print(f"❌ ERROR: Failed to load fruits model in startup!")
                print(f"Error: {e}")
                print("="*60)
                import traceback
                traceback.print_exc()
                print("="*60)
        else:
            print("\n" + "="*60)
            print("⚠️  Fruits model NOT being loaded:")
            print(f"  FRUITS_AVAILABLE: {FRUITS_AVAILABLE}")
            print(f"  fruits_endpoint is None: {fruits_endpoint is None}")
            print("="*60 + "\n")
    except Exception as e:
        print(f"Error loading model: {e}")
        raise


@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Pneumonia Classification API",
        "version": "1.0.0",
        "endpoints": {
            "/": "API information",
            "/health": "Health check",
            "/predict": "Classify chest X-ray image (POST)",
            "/fruits/predict": "Classify fruit image (POST)" if FRUITS_AVAILABLE else "Not available",
            "/docs": "Interactive API documentation"
        }
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": model is not None
    }


@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Predict pneumonia from chest X-ray image.
    
    Parameters:
        file: Uploaded image file (JPEG, PNG, etc.)
    
    Returns:
        JSON response with prediction results
    """
    if model is None or class_names is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Read image file
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Classify image
        class_name, confidence_score = classify_image(image, model, class_names)
        
        # Return results
        return JSONResponse({
            "success": True,
            "prediction": class_name,
            "confidence": round(confidence_score, 4),
            "confidence_percentage": round(confidence_score * 100, 2),
            "filename": file.filename
        })
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing image: {str(e)}")


@app.post("/predict/batch")
async def predict_batch(files: list[UploadFile] = File(...)):
    """
    Predict pneumonia from multiple chest X-ray images.
    
    Parameters:
        files: List of uploaded image files
    
    Returns:
        JSON response with predictions for all images
    """
    if model is None or class_names is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    results = []
    
    for file in files:
        if not file.content_type.startswith('image/'):
            results.append({
                "filename": file.filename,
                "success": False,
                "error": "File must be an image"
            })
            continue
        
        try:
            contents = await file.read()
            image = Image.open(io.BytesIO(contents))
            class_name, confidence_score = classify_image(image, model, class_names)
            
            results.append({
                "filename": file.filename,
                "success": True,
                "prediction": class_name,
                "confidence": round(confidence_score, 4),
                "confidence_percentage": round(confidence_score * 100, 2)
            })
        except Exception as e:
            results.append({
                "filename": file.filename,
                "success": False,
                "error": str(e)
            })
    
    return JSONResponse({
        "success": True,
        "total_files": len(files),
        "results": results
    })


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

