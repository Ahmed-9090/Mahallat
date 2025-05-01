
import '../../../auth/Data/models/user_model.dart';
import '../../../auth/Domain/entites/user_entity.dart';

abstract class SignUpUserState {}

class SignUpUserInitial extends SignUpUserState {}

class SignUpUserLoading extends SignUpUserState {}

class SignUpUserSuccess extends SignUpUserState {
  final UserEntity user;
  SignUpUserSuccess(this.user);
}

class SignUpUserError extends SignUpUserState {
  final String error;
  SignUpUserError(this.error);
} 