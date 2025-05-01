import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mahalattst2/services/storage_services/storage_service.dart';
import 'package:path/path.dart' as b;

class FireStorage implements StorageService {
  final storageRef = FirebaseStorage.instance.ref();

  @override
  Future<String> uploadImage(File file, String path)async {
    String fileName = b.basename(file.path);
    String extensionName = b.extension(file.path);
    var fileReference = storageRef.child('$path/$fileName.$extensionName');
    fileReference.putFile(file);
    await fileReference.putFile(file);
    var fileUrl= fileReference.getDownloadURL();
    return fileUrl;
  }
}
