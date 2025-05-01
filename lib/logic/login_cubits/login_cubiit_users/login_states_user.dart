
import '../../../auth/Domain/entites/user_entity.dart';

class LoginStateUser{}
 class LoginLoadingUserState extends LoginStateUser{}
 class LoginInitialUserState extends LoginStateUser{}

 class LoginSuccessUserState extends LoginStateUser{
   final UserEntity userEntity;

  LoginSuccessUserState({required this.userEntity});
   @override
   List<Object> get props => [userEntity];
 }



 class LoginErrorUserState extends LoginStateUser{
   final String error;

  LoginErrorUserState({required this.error});
 }