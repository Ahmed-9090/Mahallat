import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../Domain/entites/user_entity.dart';
import 'package:firebase_auth/firebase_auth.dart';


abstract class AuthRepoUser {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Either<Failure, UserEntity>> createUserWithEmailAndPasswordUser(
      String email,
      String password,
      String name,
      String phone,
      String profileImageUrl,
      List<String> accountType,
      String location,
      );

  Future<Either<Failure, UserEntity>> signInWithEmailAndPasswordUser(
      String email,
      String password,
      );

  Future<Either<Failure, UserEntity>> signInWithGoogleUser();

  Future addUserData({required UserEntity user});

  Future getUserData({required String uid});

  Future<Either<Failure, void>> updateAccountType({required String uid, required dynamic accountType});

  Future<Either<Failure, void>> updateUserLocation({
    required String uid,
    required LatLng location,
    required String address,
  });

  Future<Either<Failure, void>> deleteUserLocation({
    required String uid,
  });

  Future<Either<Failure, Map<String, dynamic>>> getUserLocation({
    required String uid,
  });
}
