import 'dart:io';

abstract class StorageService{

  Future<String> uploadImage(File file, String path);
}