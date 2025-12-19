"""
Enhanced Flask Deployment for Pneumonia Classification
Features: Avatar, improved UI/UX, modern styling, animations
"""

from flask import Flask, render_template, request, jsonify
from PIL import Image
import os
import sys
import io
import base64
from datetime import datetime

# Add parent directory to path to import shared_utils
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from shared_utils import load_pneumonia_model, load_class_names, classify_image

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
app.config['SECRET_KEY'] = 'pneumonia-classification-enhanced'

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'bmp'}

# Load model and class names
model = None
class_names = None

def allowed_file(filename):
    """Check if file extension is allowed."""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def init_model():
    """Initialize the model and class names."""
    global model, class_names
    try:
        model = load_pneumonia_model()
        class_names = load_class_names()
        print("Model loaded successfully!")
    except Exception as e:
        print(f"Error loading model: {e}")
        raise


init_model()


@app.route('/')
def index():
    """Render the enhanced main page."""
    return render_template('index.html')


@app.route('/predict', methods=['POST'])
def predict():
    """Handle image prediction request."""
    if model is None or class_names is None:
        return jsonify({'error': 'Model not loaded'}), 503
    
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    if not allowed_file(file.filename):
        return jsonify({'error': 'Invalid file type. Please upload an image (PNG, JPG, JPEG, GIF, BMP)'}), 400
    
    try:
        image = Image.open(io.BytesIO(file.read()))
        class_name, confidence_score = classify_image(image, model, class_names)
        
        # Convert image to base64 for display
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG')
        img_str = base64.b64encode(img_buffer.getvalue()).decode()
        
        # Get additional metadata
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        return jsonify({
            'success': True,
            'prediction': class_name,
            'confidence': round(confidence_score, 4),
            'confidence_percentage': round(confidence_score * 100, 2),
            'image': img_str,
            'timestamp': timestamp,
            'filename': file.filename
        })
    
    except Exception as e:
        return jsonify({'error': f'Error processing image: {str(e)}'}), 500


@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None,
        'version': '2.0.0-enhanced'
    })


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)

