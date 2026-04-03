import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService(this._picker);

  final ImagePicker _picker;

  Future<List<XFile>> pickMultipleFromGallery() async {
    return _picker.pickMultiImage(imageQuality: 88, maxWidth: 2048);
  }

  Future<XFile?> pickSingleFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2048,
    );
  }
}
