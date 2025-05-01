import 'package:dartz/dartz.dart';
import '../auth/Domain/entites/user_entity.dart';
import '../core/errors/failures.dart';

abstract class DatabaseService {
  Future<Either<Failure, void>> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  });

  Future<Either<Failure, UserEntity>> getUserData({
    required String path,
    required String uid,
  });

  Future<Either<Failure, void>> updateData({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  });

  Future<Either<Failure, bool>> documentExists({
    required String path,
    required String documentId,
  });

  Future<Either<Failure, List<UserEntity>>> queryUsers({
    required String path,
    required String field,
    required dynamic value,
  });

  Future<Either<Failure, void>> deleteData({
    required String path,
    required String documentId,
  });
}