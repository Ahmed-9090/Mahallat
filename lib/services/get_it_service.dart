import 'package:get_it/get_it.dart';
import 'package:mahalattst2/services/storage_services/fire_storage.dart';
import '../auth/Data/repos/images repo/images_repo.dart';
import '../auth/Data/repos/images repo/images_repo_implementation.dart';
import '../auth/Data/repos/user_repos/auth_repo_imp_user.dart';
import '../auth/Data/repos/user_repos/auth_repo_user.dart';
import 'database_service.dart';
import 'firebase_auth_services/firebase_auth_service_user.dart';
import 'firestore_service.dart';
import 'storage_services/storage_service.dart';


final getIt = GetIt.instance;

void setupGetIt() {
  getIt.registerLazySingleton<FirebaseAuthServiceUser>(() => FirebaseAuthServiceUser());



  getIt.registerLazySingleton<DatabaseService>(() => FireStoreService());



  getIt.registerLazySingleton<AuthRepoUser>(() => AuthRepoImplementationUser(
    firebaseAuthService: getIt<FirebaseAuthServiceUser>(),
    dataService: getIt<DatabaseService>(),
  ));
  getIt.registerSingleton<StorageService>(FireStorage());
  getIt.registerSingleton<ImagesRepo>(ImagesRepoImplementation(
    dataService: getIt<DatabaseService>(),
  ));


}
