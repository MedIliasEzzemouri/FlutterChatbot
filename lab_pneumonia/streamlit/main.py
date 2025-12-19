# https://www.kaggle.com/datasets/paultimothymooney/chest-xray-pneumonia
import streamlit as st
from PIL import Image
import sys
import os

# Add parent directory to path to import shared_utils
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.insert(0, parent_dir)
from shared_utils import load_pneumonia_model, load_class_names, classify_image
from util import set_background


set_background('./bgs/bg5.png')

# set title
st.title('Pneumonia classification')

# set header
st.header('Please upload a chest X-ray image')

# upload file
file = st.file_uploader('', type=['jpeg', 'jpg', 'png'])

# load classifier and class names using shared utilities (cached for performance)
@st.cache_resource
def load_model():
    return load_pneumonia_model()

@st.cache_resource
def load_labels():
    return load_class_names()

model = load_model()
class_names = load_labels()

# display image
if file is not None:
    image = Image.open(file).convert('RGB')
    st.image(image, use_column_width=True)

    # classify image
    class_name, conf_score = classify_image(image, model, class_names)

    # write classification
    st.write("## {}".format(class_name))
    st.write("### score: {}%".format(int(conf_score * 1000) / 10))
