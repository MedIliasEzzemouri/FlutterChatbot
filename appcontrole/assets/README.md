# Assets Folder Structure

This folder contains all the assets used in the Flutter application.

## Structure

- `images/` - Contains image files (PNG, JPG, etc.)
  - Place your logo file here (e.g., `logo.png` or `logo.jpg`)

- `model/` - Contains TensorFlow Lite model files
  - Place your `.tflite` model files here (e.g., `fruits_classifier.tflite`, `pneumonia_classifier.tflite`)
  - Place label files here (e.g., `labels.txt`)

## Usage

To use assets in your Flutter code:

```dart
// For images:
Image.asset('assets/images/logo.png')

// For models (using tflite package):
// The model path will be 'assets/model/your_model.tflite'
```

## Note

Make sure to add your assets to the `pubspec.yaml` file (already configured):
```yaml
assets:
  - assets/images/
  - assets/model/
```

