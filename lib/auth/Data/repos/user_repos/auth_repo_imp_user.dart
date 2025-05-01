import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../errors/exceptions.dart';
import '../../../../services/database_service.dart';
import '../../../../services/firebase_auth_services/firebase_auth_service_user.dart';
import '../../../../utils/backend_endpoint.dart';
import '../../../Domain/entites/user_entity.dart';
import '../../models/user_model.dart';
import 'auth_repo_user.dart';

class AuthRepoImplementationUser extends AuthRepoUser {
  final DatabaseService dataService;
  final FirebaseAuthServiceUser firebaseAuthService;

  AuthRepoImplementationUser({
    required this.dataService,
    required this.firebaseAuthService,
  });

  @override
  Future<Either<Failure, UserEntity>> createUserWithEmailAndPasswordUser(
      String email,
      String password,
      String name,
      String phone,
      String profileImageUrl,
      List<String> accountType,
      String location,
      ) async {
    try {
      // Validate inputs first
      if (email.isEmpty || password.isEmpty || name.isEmpty || phone.isEmpty) {
        return left(ServerFailure('الرجاء ملء جميع الحقول المطلوبة'));
      }

      // Check email uniqueness
      final emailCheck = await _checkEmailExists(email);
      if (emailCheck.isLeft() || (emailCheck.getOrElse(() => false))) {
        return left(ServerFailure('البريد الإلكتروني مستخدم بالفعل'));
      }

      // Create auth user
      final user = await firebaseAuthService.createUserWithEmailAndPasswordUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
        accountType: accountType,
      );

      // Create user entity
      final userEntity = UserEntity(
        uid: user.uid,
        email: email,
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
        accountType: accountType,
        location: location,
        emailVerified: user.emailVerified,
      );

      // Save to Firestore
      final addResult = await addUserData(user: userEntity);
      return addResult.fold(
            (failure) {
          // Clean up auth user if Firestore fails
          _cleanupFailedUser(user);
          return left(failure);
        },
            (_) => right(userEntity),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
          break;
        case 'invalid-email':
          errorMessage = 'بريد إلكتروني غير صالح';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة، يجب أن تكون 6 أحرف على الأقل';
          break;
        case 'operation-not-allowed':
          errorMessage = 'عملية التسجيل غير مسموح بها';
          break;
        default:
          errorMessage = 'حدث خطأ في إنشاء الحساب: ${e.message}';
      }
      return left(ServerFailure(errorMessage));
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPasswordUser(
      String email,
      String password,
      ) async {
    try {
      final user = await firebaseAuthService.signInWithEmailAndPasswordUser(
        email: email,
        password: password,
      );
      
      // Force refresh the user to get the latest email verification status
      await user.reload();
      final freshUser = FirebaseAuth.instance.currentUser;
      
      if (freshUser == null) {
        return left(ServerFailure('حدث خطأ في تسجيل الدخول'));
      }

      final userData = await getUserData(uid: freshUser.uid);
      return userData.fold(
            (failure) => left(failure),
            (userEntity) => right(userEntity.copyWith(emailVerified: freshUser.emailVerified)),
      );
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('فشل تسجيل الدخول، الرجاء التحقق من البيانات والمحاولة مرة أخرى'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogleUser() async {
    try {
      final authUser = await firebaseAuthService.signInWithGoogle();
      return await _handleSocialSignIn(authUser);
    } on FirebaseAuthException catch (e) {
      return left(ServerFailure('خطأ في المصادقة: ${e.message ?? e.code}'));
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('حدث خطأ غير متوقع أثناء تسجيل الدخول باستخدام جوجل: ${e.toString()}'));
    }
  }



  @override
  Future<Either<Failure, void>> updateAccountType({
    required String uid,
    required dynamic accountType,
  }) async {
    try {
      await dataService.updateData(
        path: BackendEndpoint.usersCollection,
        documentId: uid,
        data: {'accountType': accountType},
      );
      return right(null);
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('فشل تحديث نوع الحساب'));
    }
  }

  @override
  Future<Either<Failure, void>> addUserData({required UserEntity user}) async {
    try {
      await dataService.addData(
        path: BackendEndpoint.usersCollection,
        data: {
          ...user.toMap(),
          'userLocation': user.userLocation != null ? {
            'latitude': user.userLocation!.latitude,
            'longitude': user.userLocation!.longitude,
          } : null,
        },
        documentId: user.uid,
      );
      return right(null);
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('فشل في حفظ بيانات المستخدم'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getUserData({required String uid}) async {
    try {
      final result = await dataService.getUserData(
        path: BackendEndpoint.usersCollection,
        uid: uid,
      );

      return result.fold(
            (failure) => left(failure),
            (userDoc) {
          final userData = userDoc.toMap();
          final userLocation = userData['userLocation'] as Map<String, dynamic>?;
          final userModel = UserModel.fromMap({
            ...userData,
            'userLocation': userLocation != null ? LatLng(userLocation['latitude'], userLocation['longitude']) : null
          });
          return right(userModel.toEntity());
        },
      );
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('فشل في جلب بيانات المستخدم'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserLocation({
    required String uid,
    required LatLng location,
    required String address,
  }) async {
    try {
      await dataService.updateData(
        path: BackendEndpoint.usersCollection,
        documentId: uid,
        data: {
          'userLocation': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'location': address,
        },
      );
      return right(null);
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('فشل تحديث الموقع'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUserLocation({
    required String uid,
  }) async {
    try {
      await dataService.updateData(
        path: BackendEndpoint.usersCollection,
        documentId: uid,
        data: {
          'userLocation': null,
          'location': null,
        },
      );
      return right(null);
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('فشل حذف الموقع'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUserLocation({
    required String uid,
  }) async {
    try {
      final result = await dataService.getUserData(
        path: BackendEndpoint.usersCollection,
        uid: uid,
      );

      return result.fold(
        (failure) => left(failure),
        (userDoc) {
          final userData = userDoc.toMap();
          final userLocation = userData['userLocation'] as Map<String, dynamic>?;
          final location = userData['location'] as String?;
          
          return right({
            'userLocation': userLocation,
            'location': location,
          });
        },
      );
    } on CustomException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('فشل في جلب بيانات الموقع'));
    }
  }

  // Helper methods
  Future<Either<Failure, bool>> _checkEmailExists(String email) async {
    try {
      final result = await dataService.queryUsers(
        path: BackendEndpoint.usersCollection,
        field: 'email',
        value: email,
      );
      return result.fold(
            (failure) => left(failure),
            (users) => right(users.isNotEmpty),
      );
    } catch (e) {
      return left(ServerFailure('فشل التحقق من البريد الإلكتروني'));
    }
  }

  Future<void> _cleanupFailedUser(User user) async {
    try {
      await user.delete();
      await dataService.deleteData(
        path: BackendEndpoint.usersCollection,
        documentId: user.uid,
      );
    } catch (_) {}
  }

  Future<Either<Failure, UserEntity>> _handleSocialSignIn(User authUser) async {
    try {
      final userData = await getUserData(uid: authUser.uid);
      return userData.fold(
            (_) async {
          // Create new user if not exists
          final newUser = UserEntity(
            uid: authUser.uid,
            email: authUser.email ?? '',
            name: authUser.displayName ?? 'مستخدم جديد',
            phone: authUser.phoneNumber ?? '',
            profileImageUrl: authUser.photoURL ?? '',
            accountType: ['user'],
            location: '',
            userLocation: null,
            emailVerified: authUser.emailVerified,
          );

          final addResult = await addUserData(user: newUser);
          return addResult.fold(
                (failure) => left(failure),
                (_) => right(newUser),
          );
        },
            (user) => right(user),
      );
    } catch (e) {
      return left(ServerFailure('فشل في معالجة تسجيل الدخول: ${e.toString()}'));
    }
  }
}