import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../errors/exceptions.dart';

class FirebaseAuthServiceUser {
  Future deleteUser() async {
    await FirebaseAuth.instance.currentUser!.delete();
  }

  Future<User> createUserWithEmailAndPasswordUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String profileImageUrl,
    required List<String> accountType,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw CustomException(message: ' كلمة المرور ضعيفة');
      } else if (e.code == 'email-already-in-use') {
        throw CustomException(
          message: 'لقد تم استخدام هذا البريد الإلكتروني من قبل',
        );
      } else {
        throw CustomException(
          message: 'حدث خطأ في إنشاء الحساب الرجاء المحاولة مرة أخرى',
        );
      }
    } catch (e) {
      throw CustomException(
        message: 'حدث خطأ في إنشاء الحساب الرجاء المحاولة مرة أخرى',
      );
    }
  }

  Future<User> signInWithEmailAndPasswordUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw CustomException(
          message: 'الرقم السري او البريد الإلكتروني غير صحيح',
        );
      } else if (e.code == 'wrong-password') {
        throw CustomException(
          message: 'الرقم السري او البريد الإلكتروني غير صحيح',
        );
      } else {
        throw CustomException(
          message: 'حدث خطأ في تسجيل الدخول الرجاء المحاولة مرة أخرى',
        );
      }
    } catch (e) {
      throw CustomException(
        message: 'حدث خطأ في تسجيل الدخول الرجاء المحاولة مرة أخرى',
      );
    }
  }

  Future<User> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user!;
    } catch (e) {
      throw CustomException(message: 'فشل في تسجيل الدخول باستخدام جوجل: ${e.toString()}');
    }
  }
}
