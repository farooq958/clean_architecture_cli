
import 'package:file_picker/file_picker.dart';

class PickFile {
   Future<String?> pickImage() async {
    // ImagePicker.platform.getImageFromSource(source: ImageSource.camera);
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      // allowedExtensions: [".jpg",".png",".heic","jpeg"],
      allowMultiple: false,
    );
    if (result == null) return null;
    final images = result.paths.first;
    return images;
  }

}