"""
Shared utility functions for pneumonia classification model.
Can be used by Streamlit, FastAPI, Flask, and other deployments.
"""

from PIL import ImageOps, Image
import numpy as np
import os

# Import Keras model loader - prefer TensorFlow Keras for better compatibility
USE_TF_KERAS = False
try:
    import tensorflow as tf
    # Verify TensorFlow is actually working
    _ = tf.__version__
    from tensorflow.keras.models import load_model
    USE_TF_KERAS = True
except (ImportError, AttributeError):
    try:
        from keras.models import load_model
        USE_TF_KERAS = False
    except ImportError:
        raise ImportError(
            "TensorFlow is not working correctly. Try:\n"
            "1. pip uninstall tensorflow tensorflow-intel\n"
            "2. pip install tensorflow==2.12.0 --no-cache-dir\n"
            "3. Restart Python/terminal"
        )


def load_pneumonia_model(model_path=None):
    """
    Load the pneumonia classification model.
    
    Parameters:
        model_path (str): Path to the model file. If None, uses default path.
    
    Returns:
        model: Loaded Keras model
    """
    if model_path is None:
        # Default path relative to this file
        base_dir = os.path.dirname(os.path.abspath(__file__))
        model_path = os.path.join(base_dir, 'streamlit', 'model', 'pneumonia_classifier.h5')
        
        # If path doesn't exist, try alternative paths
        if not os.path.exists(model_path):
            # Try relative to current working directory
            alt_path = os.path.join('streamlit', 'model', 'pneumonia_classifier.h5')
            if os.path.exists(alt_path):
                model_path = alt_path
            else:
                # Try from streamlit directory
                alt_path = os.path.join(os.path.dirname(base_dir), 'streamlit', 'model', 'pneumonia_classifier.h5')
                if os.path.exists(alt_path):
                    model_path = alt_path
    
    # Handle model loading with compatibility for older models
    try:
        # Try loading with TensorFlow Keras (handles compatibility better)
        if USE_TF_KERAS:
            # Suppress the 'groups' parameter warning by using custom_objects
            try:
                return load_model(model_path, compile=False)
            except Exception:
                # If that fails, try with safe_mode disabled (for Keras 3.x)
                try:
                    return load_model(model_path, compile=False, safe_mode=False)
                except Exception:
                    # Last resort: try with custom object handling
                    return load_model(model_path, compile=False)
        else:
            return load_model(model_path, compile=False)
    except Exception as e:
        # If loading fails, provide helpful error message
        raise ValueError(f"Failed to load model from {model_path}. "
                        f"This model may require TensorFlow 2.12.0/Keras 2.12.0. "
                        f"Error: {str(e)}")


def load_class_names(labels_path=None):
    """
    Load class names from labels file.
    
    Parameters:
        labels_path (str): Path to labels file. If None, uses default path.
    
    Returns:
        list: List of class names
    """
    if labels_path is None:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        labels_path = os.path.join(base_dir, 'streamlit', 'model', 'labels.txt')
        
        # If path doesn't exist, try alternative paths
        if not os.path.exists(labels_path):
            # Try relative to current working directory
            alt_path = os.path.join('streamlit', 'model', 'labels.txt')
            if os.path.exists(alt_path):
                labels_path = alt_path
            else:
                # Try from streamlit directory
                alt_path = os.path.join(os.path.dirname(base_dir), 'streamlit', 'model', 'labels.txt')
                if os.path.exists(alt_path):
                    labels_path = alt_path
    
    with open(labels_path, 'r') as f:
        class_names = [a[:-1].split(' ')[1] for a in f.readlines()]
    return class_names


def preprocess_image(image, target_size=(224, 224)):
    """
    Preprocess an image for model prediction.
    
    Parameters:
        image (PIL.Image.Image): Input image
        target_size (tuple): Target size for resizing (width, height)
    
    Returns:
        numpy.ndarray: Preprocessed image array ready for model input
    """
    # Convert image to RGB if needed
    if image.mode != 'RGB':
        image = image.convert('RGB')
    
    # Resize image to target size
    image = ImageOps.fit(image, target_size, Image.Resampling.LANCZOS)
    
    # Convert to numpy array
    image_array = np.asarray(image)
    
    # Normalize image (values between -1 and 1)
    normalized_image_array = (image_array.astype(np.float32) / 127.5) - 1
    
    # Reshape for model input
    data = np.ndarray(shape=(1, target_size[1], target_size[0], 3), dtype=np.float32)
    data[0] = normalized_image_array
    
    return data


def classify_image(image, model, class_names):
    """
    Classify an image using the pneumonia model.
    
    Parameters:
        image (PIL.Image.Image): Image to classify
        model: Trained Keras model
        class_names (list): List of class names
    
    Returns:
        tuple: (class_name, confidence_score)
    """
    # Preprocess image
    data = preprocess_image(image)
    
    # Make prediction
    prediction = model.predict(data, verbose=0)
    
    # Determine class (threshold-based for binary classification)
    index = 0 if prediction[0][0] > 0.95 else 1
    class_name = class_names[index]
    confidence_score = float(prediction[0][index])
    
    return class_name, confidence_score
