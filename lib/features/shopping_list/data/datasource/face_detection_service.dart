import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  FaceDetectionService()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

  final FaceDetector _detector;

  Future<bool> hasFace(String imagePath) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final faces = await _detector.processImage(input);
      debugPrint('[FaceDetection] faces found=${faces.length}');
      return faces.isNotEmpty;
    } catch (e, st) {
      debugPrint('[FaceDetection] error: $e');
      debugPrint('$st');
      return false;
    }
  }

  Future<void> close() => _detector.close();
}
