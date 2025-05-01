import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahalattst2/logic/signup_cubits/signup_user_cubits/signup_user_state.dart';
import '../../../auth/Data/repos/user_repos/auth_repo_user.dart';
import '../../../UI/signup_screens/google_signup_complete.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/Domain/entites/user_entity.dart';

class SignUpUserCubit extends Cubit<SignUpUserState> {
  SignUpUserCubit(this.authRepo) : super(SignUpUserInitial());
  final AuthRepoUser authRepo;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createUserWithEmailAndPasswordUser(
      {required String email,
      required String password,
      required String name,
      required String phone,
      required String profileImageUrl,
      required List<String> accountType,
      required String location
   }) async {
    emit(SignUpUserLoading());
    try {
      final result = await authRepo.createUserWithEmailAndPasswordUser(
        email,
        password,
        name,
        phone,
        profileImageUrl,
        accountType,
        location,
      );
      result.fold(
        (failure) => emit(SignUpUserError(failure.message)),
        (user) async {
          await _auth.currentUser?.sendEmailVerification();
          emit(SignUpUserSuccess(user));
        },
      );
    } catch (e) {
      emit(SignUpUserError(e.toString()));
    }
  }

  Future<void> signInWithGoogleUser(BuildContext context) async {
    emit(SignUpUserLoading());
    final result = await authRepo.signInWithGoogleUser();
    result.fold(
      (failure) => emit(SignUpUserError(failure.message)),
      (user) {
        emit(SignUpUserSuccess(user));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleSignupComplete()),
        );
      },
    );
  }


  Future<void> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'name': name,
          'phone': phone,
        });
      }
    } catch (e) {
      throw Exception('فشل في تحديث البيانات: $e');
    }
  }

  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(String) onError,
  ) async {
    emit(SignUpUserLoading());
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await _auth.signInWithCredential(credential);
          final user = userCredential.user;
          if (user != null) {
            final userEntity = UserEntity(
              uid: user.uid,
              email: user.email ?? '',
              name: user.displayName ?? '',
              phone: user.phoneNumber ?? '',
              profileImageUrl: user.photoURL ?? '',
              accountType: ['user'],
              location: '',
            );
            emit(SignUpUserSuccess(userEntity));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          final error = e.message ?? 'حدث خطأ أثناء التحقق من رقم الهاتف';
          onError(error);
          emit(SignUpUserError(error));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
          emit(SignUpUserSuccess(UserEntity(
            uid: '',
            email: '',
            name: '',
            phone: phoneNumber,
            profileImageUrl: '',
            accountType: ['user'],
            location: '',
          )));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          emit(SignUpUserError('انتهت مدة التحقق'));
        },
      );
    } catch (e) {
      final error = e.toString();
      onError(error);
      emit(SignUpUserError(error));
    }
  }

  Future<void> signInWithPhoneNumber(
    String verificationId,
    String smsCode,
    BuildContext context,
  ) async {
    emit(SignUpUserLoading());
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        final userEntity = UserEntity(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          phone: user.phoneNumber ?? '',
          profileImageUrl: user.photoURL ?? '',
          accountType: ['user'],
          location: '',
        );
        emit(SignUpUserSuccess(userEntity));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleSignupComplete()),
        );
      }
    } catch (e) {
      emit(SignUpUserError(e.toString()));
    }
  }

  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      emit(SignUpUserError(e.toString()));
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        emit(SignUpUserSuccess(UserEntity(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          phone: user.phoneNumber ?? '',
          profileImageUrl: user.photoURL ?? '',
          accountType: ['user'],
          location: '',
          emailVerified: user.emailVerified,
        )));
      }
    } catch (e) {
      emit(SignUpUserError('فشل في إعادة إرسال بريد التحقق: ${e.toString()}'));
    }
  }
}
