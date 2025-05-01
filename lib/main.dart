import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahalattst2/services/custom_bloc_observer.dart';
import 'package:mahalattst2/services/firebase_service.dart';
import 'package:mahalattst2/services/get_it_service.dart';
import 'package:provider/provider.dart';
import 'UI/splash_screen.dart';
import 'auth/Data/repos/clothes_repos/products_repo_impl.dart';
import 'auth/Data/repos/user_repos/auth_repo_user.dart';
import 'auth/Data/repos/store_repos/store_repo_impl.dart';
import 'auth/services/firebase_auth_services/firebase_auth_service_user.dart';
import 'logic/login_cubits/login_cubiit_users/login_cubit_user.dart';
import 'logic/products_cubits/products_cubit.dart';
import 'logic/stores_cubits/store_cubit.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = CustomBlocObserver();

    // Initialize Firebase using the service
    await FirebaseService.initialize();

    // Continue with app setup even if Firebase initialization had issues
    setupGetIt();

    // Register repositories
    getIt.registerSingleton<StoreRepositoryImpl>(
      StoreRepositoryImpl(FirebaseFirestore.instance),
    );
    getIt.registerSingleton<ProductsRepositoryImpl>(
      ProductsRepositoryImpl(FirebaseFirestore.instance),
    );
    getIt.registerSingleton<FirebaseAuthServiceUser>(
      FirebaseAuthServiceUser(),
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('Error initializing app: $e');
    // Still try to run the app even if there are initialization errors
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MultiBlocProvider(
              providers: [
                BlocProvider(
                    create: (context) => LoginCubitUser(getIt<AuthRepoUser>())),
                BlocProvider(
                    create: (context) =>
                        StoreCubit(getIt<StoreRepositoryImpl>())),
                BlocProvider(
                    create: (context) =>
                        ProductsCubit(getIt<ProductsRepositoryImpl>())),
              ],
              child: MaterialApp(
                title: 'محلات',
                debugShowCheckedModeBanner: false,
                locale: languageProvider.currentLocale,
                builder: (context, child) {
                  return Directionality(
                    textDirection: languageProvider.isRTL
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  );
                },
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                  brightness: themeProvider.isDarkMode
                      ? Brightness.dark
                      : Brightness.light,
                  scaffoldBackgroundColor: themeProvider.isDarkMode
                      ? const Color(0xff1a1a1a)
                      : Colors.white,
                ),
                home: const SplashScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
