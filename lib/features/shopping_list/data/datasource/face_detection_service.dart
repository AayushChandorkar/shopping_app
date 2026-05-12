import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  FaceDetectionService()
    : _fastDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      ),
      _accurateDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableLandmarks: true,
          enableClassification: false,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

  final FaceDetector _fastDetector;
  final FaceDetector _accurateDetector;

  Future<bool> hasFace(String imagePath) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final fastFaces = await _fastDetector.processImage(input);
      if (fastFaces.isNotEmpty) {
        debugPrint('[FaceDetection] fast faces found=${fastFaces.length}');
        return true;
      }

      final accurateFaces = await _accurateDetector.processImage(input);
      debugPrint(
        '[FaceDetection] accurate faces found=${accurateFaces.length}',
      );
      return accurateFaces.isNotEmpty;
    } catch (e, st) {
      debugPrint('[FaceDetection] error: $e');
      debugPrint('$st');
      return false;
    }
  }

  Future<void> close() async {
    await _fastDetector.close();
    await _accurateDetector.close();
  }
}
