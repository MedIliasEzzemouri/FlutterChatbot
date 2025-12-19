"""
Fruits Classification Endpoint for FastAPI
Uses H5 model (like pneumonia) for better compatibility
"""

from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image, ImageOps
import io
import numpy as np
import os
import sys

# Add parent directory to path to import shared_utils style functions
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Try to import Keras model loader
USE_TF_KERAS = False
try:
    import tensorflow as tf
    from tensorflow.keras.models import load_model
    USE_TF_KERAS = True
except (ImportError, AttributeError):
    try:
        from keras.models import load_model
        USE_TF_KERAS = False
    except ImportError:
        raise ImportError("TensorFlow/Keras is required for fruits classification")

# Create router
router = APIRouter()

# Load fruits model (adjust path as needed)
fruits_model = None
fruits_class_names = ["apple", "banana", "orange"]

def load_fruits_model(model_path=None):
    """
    Load the fruits H5 model (preferred) or TFLite model (fallback)
    """
    global fruits_model  # Declare global at the very top
    
    print(f"[DEBUG] load_fruits_model called. Current fruits_model: {fruits_model}")
    print(f"[DEBUG] Function locals before: {locals().keys()}")
    
    # Try H5 model first (better compatibility)
    if model_path is None:
        h5_path = r"C:\Users\iezze\Downloads\LAB\LAB1\labs\02_cnn_fruits\fruits_classifier.h5"
        tflite_path = r"C:\Users\iezze\Downloads\LAB\LAB1\labs\02_cnn_fruits\model.tflite"
        
        if os.path.exists(h5_path):
            model_path = h5_path
            use_h5 = True
        elif os.path.exists(tflite_path):
            model_path = tflite_path
            use_h5 = False
        else:
            print(f"Warning: Fruits model not found!")
            print(f"  H5 path: {h5_path}")
            print(f"  TFLite path: {tflite_path}")
            print(f"  Current directory: {os.getcwd()}")
            print(f"\nTo create H5 model, run: python C:\\Users\\iezze\\Downloads\\LAB\\LAB1\\labs\\02_cnn_fruits\\save_fruits_model.py")
            fruits_model = None
            return None
    else:
        use_h5 = model_path.endswith('.h5')
    
    try:
        if use_h5:
            # Load H5 model (like pneumonia)
            print(f"\n{'='*60}")
            print(f"Loading fruits H5 model from: {model_path}")
            print(f"Model file exists: {os.path.exists(model_path)}")
            if os.path.exists(model_path):
                print(f"File size: {os.path.getsize(model_path) / (1024*1024):.2f} MB")
            print(f"{'='*60}")
            
            if USE_TF_KERAS:
                print("Using TensorFlow Keras to load model...")
                loaded_model = load_model(model_path, compile=False)
            else:
                print("Using standalone Keras to load model...")
                loaded_model = load_model(model_path, compile=False)
            
            # Explicitly set the global variable
            fruits_model = loaded_model
            
            # Also set it via module reference to be absolutely sure
            import sys
            current_module = sys.modules[__name__]
            current_module.fruits_model = loaded_model
            
            print(f"✓ Fruits H5 model loaded successfully!")
            print(f"Model type: {type(fruits_model)}")
            print(f"Model has 'predict' method: {hasattr(fruits_model, 'predict')}")
            print(f"Global fruits_model variable set: {fruits_model is not None}")
            print(f"[DEBUG] After assignment - fruits_model id: {id(fruits_model)}")
            print(f"[DEBUG] After assignment - fruits_model is None: {fruits_model is None}")
            print(f"[DEBUG] Module's fruits_model via sys.modules: {current_module.fruits_model is not None}")
            print(f"{'='*60}\n")
            
            return fruits_model
        else:
            # Load TFLite model (fallback)
            print(f"Loading fruits TFLite model from: {model_path}")
            interpreter = tf.lite.Interpreter(model_path=model_path)
            interpreter.allocate_tensors()
            
            fruits_model = interpreter
            
            input_details = interpreter.get_input_details()
            output_details = interpreter.get_output_details()
            print(f"Fruits TFLite model loaded successfully!")
            print(f"Input shape: {input_details[0]['shape']}, dtype: {input_details[0]['dtype']}")
            print(f"Output shape: {output_details[0]['shape']}, dtype: {output_details[0]['dtype']}")
            return interpreter
    except Exception as e:
        print(f"ERROR loading fruits model: {e}")
        import traceback
        error_trace = traceback.format_exc()
        print(f"Full error traceback:\n{error_trace}")
        fruits_model = None
        return None

def preprocess_fruits_image(image, target_size=(32, 32)):
    """
    Preprocess image for fruits model.
    The model has Rescaling(1./255) layer, so it expects raw pixel values (0-255).
    """
    # Convert to RGB if needed
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize to 32x32 (fruits model input size)
    image = ImageOps.fit(image, target_size, Image.Resampling.LANCZOS)
    
    # Convert to numpy array (raw pixel values 0-255)
    # The model's Rescaling layer will normalize it
    image_array = np.asarray(image, dtype=np.float32)
    
    # Reshape for model input: [1, 32, 32, 3]
    data = np.expand_dims(image_array, axis=0)
    
    return data

def classify_fruits_image(image):
    """
    Classify fruits image using H5 model (preferred) or TFLite model
    """
    if fruits_model is None:
        raise ValueError("Fruits model not loaded")
    
    # Preprocess image
    data = preprocess_fruits_image(image)
    
    # Check if it's H5 model or TFLite
    if hasattr(fruits_model, 'predict'):
        # H5 Keras model
        prediction = fruits_model.predict(data, verbose=0)
        # Model outputs logits, apply softmax
        exp_predictions = np.exp(prediction[0] - np.max(prediction[0]))
        probabilities = exp_predictions / np.sum(exp_predictions)
        
        # Get top prediction
        top_index = np.argmax(probabilities)
        class_name = fruits_class_names[top_index]
        confidence = float(probabilities[top_index])
        
        print(f"Fruits prediction: {class_name} ({confidence*100:.2f}%)")
        return class_name, confidence
    else:
        # TFLite model
        input_details = fruits_model.get_input_details()
        output_details = fruits_model.get_output_details()
        
        # Set input tensor
        fruits_model.set_tensor(input_details[0]['index'], data)
        
        # Run inference
        fruits_model.invoke()
        
        # Get output
        output_data = fruits_model.get_tensor(output_details[0]['index'])
        predictions = output_data[0] if len(output_data.shape) > 1 else output_data
        
        # Apply softmax to get probabilities
        exp_predictions = np.exp(predictions - np.max(predictions))
        probabilities = exp_predictions / np.sum(exp_predictions)
        
        # Get top prediction
        top_index = np.argmax(probabilities)
        class_name = fruits_class_names[top_index]
        confidence = float(probabilities[top_index])
        
        print(f"Fruits prediction: {class_name} ({confidence*100:.2f}%)")
        return class_name, confidence

@router.get("/fruits/status")
async def fruits_status():
    """Check fruits model status"""
    global fruits_model  # Make sure we're reading the global variable
    h5_path = r"C:\Users\iezze\Downloads\LAB\LAB1\labs\02_cnn_fruits\fruits_classifier.h5"
    tflite_path = r"C:\Users\iezze\Downloads\LAB\LAB1\labs\02_cnn_fruits\model.tflite"
    
    # Debug: Print current state
    print(f"\n[DEBUG] Status check - fruits_model is None: {fruits_model is None}")
    print(f"[DEBUG] fruits_model type: {type(fruits_model)}")
    print(f"[DEBUG] fruits_model value: {fruits_model}")
    
    # Determine model type
    model_type = None
    if fruits_model is not None:
        if hasattr(fruits_model, 'predict'):
            model_type = "H5"
        else:
            model_type = "TFLite"
    
    return {
        "model_loaded": fruits_model is not None,
        "model_type": model_type,
        "class_names": fruits_class_names,
        "h5_path": h5_path,
        "h5_exists": os.path.exists(h5_path),
        "tflite_path": tflite_path,
        "tflite_exists": os.path.exists(tflite_path),
        "model_object": str(type(fruits_model)) if fruits_model is not None else None,
        "debug_fruits_model_is_none": fruits_model is None,
        "debug_fruits_model_type": str(type(fruits_model)),
        "note": "Check server console for loading errors if model_loaded is false"
    }

@router.post("/fruits/predict")
async def predict_fruits(file: UploadFile = File(...)):
    """
    Predict fruit type from image.
    
    Parameters:
        file: Uploaded image file (JPEG, PNG, etc.)
    
    Returns:
        JSON response with prediction results
    """
    global fruits_model
    
    # Also check via module reference
    import sys
    current_module = sys.modules[__name__]
    module_fruits_model = getattr(current_module, 'fruits_model', None)
    
    # Use module reference if global is None
    if fruits_model is None and module_fruits_model is not None:
        print("[DEBUG] Global fruits_model is None, but module has it. Using module reference.")
        fruits_model = module_fruits_model
    
    if fruits_model is None:
        raise HTTPException(
            status_code=503, 
            detail="Fruits model not loaded. Check /fruits/status for details. Model loading may have failed - check server console."
        )
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Read image file
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        print(f"Image size: {image.size}, mode: {image.mode}")
        
        # Classify image
        class_name, confidence_score = classify_fruits_image(image)
        
        # Return results
        return JSONResponse({
            "success": True,
            "prediction": class_name,
            "confidence": round(confidence_score, 4),
            "confidence_percentage": round(confidence_score * 100, 2),
            "filename": file.filename
        })
    
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"Error in fruits prediction: {error_details}")
        raise HTTPException(
            status_code=500, 
            detail=f"Error processing image: {str(e)}\n\nDetails: {error_details}"
        )

# Don't load model at import - let startup event handle it
# This prevents errors during import and allows better error handling
# load_fruits_model()  # Commented out - will be called in startup event

