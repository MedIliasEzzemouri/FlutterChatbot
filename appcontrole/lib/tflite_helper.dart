// Export the TFLiteHelper from the appropriate implementation
// On web: uses tflite_web implementation
// On mobile: uses tflite_flutter implementation
export 'tflite_helper_web.dart' if (dart.library.io) 'tflite_helper_mobile.dart';


