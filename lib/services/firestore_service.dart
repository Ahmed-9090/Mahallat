import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../auth/Data/models/user_model.dart';
import '../auth/Domain/entites/user_entity.dart';
import '../core/errors/failures.dart';
import 'database_service.dart';

class FireStoreService implements DatabaseService {
  @override
  final FirebaseFirestore firebaseFirestore;

  FireStoreService({FirebaseFirestore? firestore})
      : firebaseFirestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, void>> addData({
    required String path,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        await firebaseFirestore.collection(path).doc(documentId).set(data);
      } else {
        await firebaseFirestore.collection(path).add(data);
      }
      return right(null);
    } catch (e) {
      return left(ServerFailure('فشل في إضافة البيانات: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserData({
    required String path,
    required String uid,
  }) async {
    try {
      final doc = await firebaseFirestore.collection(path).doc(uid).get();
      if (!doc.exists) {
        return left(NotFoundFailure('User not found'));
      }

      // Convert to Model first then to Entity
      final userModel = UserModel.fromMap(doc.data()!..['uid'] = doc.id);
      return right(userModel.toEntity());
    } on FirebaseException catch (e) {
      return left(ServerFailure(e.message ?? 'Failed to get user data'));
    } catch (e) {
      return left(ServerFailure('Failed to parse user data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateData({
    required String path,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await firebaseFirestore.collection(path).doc(documentId).update(data);
      return right(null);
    } on FirebaseException catch (e) {
      return left(ServerFailure(e.message ?? 'Update operation failed'));
    } catch (e) {
      return left(ServerFailure('Failed to update data: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> documentExists({
    required String path,
    required String documentId,
  }) async {
    try {
      final doc = await firebaseFirestore.collection(path).doc(documentId).get();
      return right(doc.exists);
    } on FirebaseException catch (e) {
      return left(ServerFailure(e.message ?? 'Existence check failed'));
    } catch (e) {
      return left(ServerFailure('Failed to check document existence: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> queryUsers({
    required String path,
    required String field,
    required dynamic value,
  }) async {
    try {
      final query = await firebaseFirestore
          .collection(path)
          .where(field, isEqualTo: value)
          .get();

      final users = query.docs.map((doc) {
        final model = UserModel.fromMap(doc.data()..['uid'] = doc.id);
        return model.toEntity();
      }).toList();

      return right(users);
    } on FirebaseException catch (e) {
      return left(ServerFailure(e.message ?? 'Query operation failed'));
    } catch (e) {
      return left(ServerFailure('Failed to query users: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteData({
    required String path,
    required String documentId,
  }) async {
    try {
      await firebaseFirestore.collection(path).doc(documentId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(ServerFailure(e.message ?? 'Delete operation failed'));
    } catch (e) {
      return left(ServerFailure('Failed to delete data: $e'));
    }
  }
}

class NotFoundFailure extends Failure {
  NotFoundFailure(String message) : super(message);
}