import 'package:camera/camera.dart';

class CameraService {
  Future<List<CameraDescription>> loadAvailableCameras() async {
    try {
      return availableCameras();
    } catch (_) {
      return <CameraDescription>[];
    }
  }
}
