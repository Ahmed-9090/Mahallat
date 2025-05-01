import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../UI/seller_pages/seller_home_page.dart';
import '../../../auth/Data/repos/user_repos/auth_repo_user.dart';
import '../../../auth/Domain/entites/user_entity.dart';
import '../../../UI/auth/email_verification_page.dart';
import 'login_states_user.dart';
import '../../../UI/signup_screens/google_signup_complete.dart';
import '../../../UI/home_screens/home_page.dart';

class LoginCubitUser extends Cubit<LoginStateUser> {
  LoginCubitUser(this.authRepo) : super(LoginInitialUserState());
  final AuthRepoUser authRepo;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signUpWithEmailAndPasswordUser(
    String email,
    String password,
    String name,
    String phone,
    String profileImageUrl,
    List<String> accountType,
    String location,
    BuildContext context,
  ) async {
    emit(LoginLoadingUserState());
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
        (failure) => emit(LoginErrorUserState(error: failure.message)),
        (userEntity) async {
          // Send email verification
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await user.sendEmailVerification();
            // Sign out the user immediately after signup
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              // Navigate to email verification page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
              );
            }
          }
          emit(LoginSuccessUserState(userEntity: userEntity));
        },
      );
    } catch (e) {
      emit(LoginErrorUserState(error: e.toString()));
    }
  }

  Future<void> signInWithEmailAndPasswordUser(
      String email,
      String password,
      BuildContext context,
      ) async {
    emit(LoginLoadingUserState());
    try {
      final result = await authRepo.signInWithEmailAndPasswordUser(email, password);
      
      result.fold(
        (failure) => emit(LoginErrorUserState(error: failure.message)),
        (userEntity) async {
          emit(LoginSuccessUserState(userEntity: userEntity));
          await _handlePostLoginNavigation(userEntity, context);
        },
      );
    } catch (e) {
      emit(LoginErrorUserState(error: e.toString()));
    }
  }

  Future<void> signInWithGoogleUser(BuildContext context) async {
    emit(LoginLoadingUserState());
    final result = await authRepo.signInWithGoogleUser();

    result.fold(
          (failure) => emit(LoginErrorUserState(error: failure.message)),
          (userEntity) async {
        emit(LoginSuccessUserState(userEntity: userEntity));
        await _handlePostLoginNavigation(userEntity, context);
      },
    );
  }

  Future<void> _handlePostLoginNavigation(UserEntity userEntity, BuildContext context) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userEntity.uid).get();

      if (!userDoc.exists) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GoogleSignupComplete()),
          );
        }
        return;
      }

      final accountType = userDoc.data()?['accountType'] as List<dynamic>?;
      if (context.mounted) {
        if (accountType != null && accountType.isNotEmpty) {
          if (accountType.first == 'user') {
            // Check email verification only for users
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null && !user.emailVerified) {
              await user.sendEmailVerification();
              // Sign out the user if email is not verified
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const EmailVerificationPage()),
              );
              return;
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else {
            // For non-user account types, don't check email verification
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SellerHomePage(
                  sellerId: userEntity.uid,
                ),
              ),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ في تحديد نوع الحساب',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> verifyPhoneNumber(
      String phoneNumber,
      Function(String) onCodeSent,
      Function(String) onError,
      ) async {
    emit(LoginLoadingUserState());
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
            emit(LoginSuccessUserState(userEntity: userEntity));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          final error = e.message ?? 'حدث خطأ أثناء التحقق من رقم الهاتف';
          onError(error);
          emit(LoginErrorUserState(error: error));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
          emit(LoginSuccessUserState(userEntity: UserEntity(
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
          emit(LoginErrorUserState(error: 'انتهت مدة التحقق'));
        },
      );
    } catch (e) {
      final error = e.toString();
      onError(error);
      emit(LoginErrorUserState(error: error));
    }
  }

  Future<void> signInWithPhoneNumber(
      String verificationId,
      String smsCode,
      BuildContext context,
      ) async {
    emit(LoginLoadingUserState());
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
        emit(LoginSuccessUserState(userEntity: userEntity));
        await _handlePostLoginNavigation(userEntity, context);
      }
    } catch (e) {
      emit(LoginErrorUserState(error: e.toString()));
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
      emit(LoginErrorUserState(error: e.toString()));
    }
  }
}