import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/database_service.dart';
import '../../../../utils/backend_endpoint.dart';
import 'images_repo.dart';

class ImagesRepoImplementation extends ImagesRepo {
  final DatabaseService dataService;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ImagesRepoImplementation({required this.dataService});

  @override
  Future<Either<Failure, String>> uploadImage(File image) async {
    try {
      final ref = _storage.ref().child(BackendEndpoint.images);
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return right(downloadUrl);
    } catch (e) {
      return left(ServerFailure('فشل في رفع الصورة: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteImage({
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      return right(null);
    } catch (e) {
      return left(ServerFailure('فشل في حذف الصورة: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateImage({
    required String path,
    required String imagePath,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      final uploadTask = await ref.putFile(imagePath as File);
      await uploadTask.ref.getDownloadURL();
      return right(null);
    } catch (e) {
      return left(ServerFailure('فشل في تحديث الصورة: ${e.toString()}'));
    }
  }
}
