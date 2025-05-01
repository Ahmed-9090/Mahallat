import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import '../../auth/Data/repos/user_repos/auth_repo_user.dart';
import '../../logic/login_cubits/login_cubiit_users/login_cubit_user.dart';
import '../../logic/signup_cubits/signup_user_cubits/signup_user_cubit.dart';
import '../../logic/signup_cubits/signup_user_cubits/signup_user_state.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/get_it_service.dart';
import '../home_screens/home_page.dart';
import '../login_page.dart';

class UserSignupScreen extends StatefulWidget {
  const UserSignupScreen({super.key});

  @override
  State<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends State<UserSignupScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AutovalidateMode autoValidateMode = AutovalidateMode.disabled;
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final cityController = TextEditingController();
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool isLoading = false;
  late AnimationController _controller;
  String? _verificationId;
  bool isPhoneVerification = false;
  String? _smsCode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    setState(() {
      isLoading = true;
    });

    try {
      await context.read<SignUpUserCubit>().verifyPhoneNumber(
        phoneNumberController.text,
        (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            isPhoneVerification = true;
            isLoading = false;
          });
        },
        (String error) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطأ في التحقق من رقم الهاتف: $error',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء التحقق من رقم الهاتف',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signInWithPhoneNumber() async {
    if (_verificationId == null || _smsCode == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      await context.read<SignUpUserCubit>().signInWithPhoneNumber(
        _verificationId!,
        _smsCode!,
        context,
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في التحقق من الكود',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) => SignUpUserCubit(getIt<AuthRepoUser>()),
      child: Theme(
        data: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
        child: Scaffold(
          backgroundColor: themeProvider.isDarkMode ? const Color(0xff2d2d2d) : Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: themeProvider.isDarkMode
                ? const Color(0xff0d0d0d)
                : const Color(0xffF1E4CF),
            elevation: 0,
            // actions: [
            //   IconButton(
            //     icon: Icon(
            //       themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            //       color: themeProvider.isDarkMode
            //           ? Colors.yellow
            //           : const Color(0xff503636),
            //     ),
            //     onPressed: () {
            //       themeProvider.toggleTheme();
            //     },
            //   ),
            // ],
          ),
          body: Builder(
            builder: (context) {
              return BlocConsumer<SignUpUserCubit, SignUpUserState>(
                listener: (context, state) {
                  if (state is SignUpUserSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          languageProvider.translate('signup.success'),
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: languageProvider.translate('signup.resendVerification'),
                          textColor: Colors.white,
                          onPressed: () {
                            context.read<SignUpUserCubit>().resendVerificationEmail();
                          },
                        ),
                      ),
                    );
                  } else if (state is SignUpUserError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.error,
                          style: GoogleFonts.cairo(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return ModalProgressHUD(
                    inAsyncCall: state is SignUpUserLoading,
                    child: SafeArea(
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: themeProvider.isDarkMode
                                ? [
                              const Color(0xff0d0d0d),
                              const Color(0xff1a1a1a),
                              const Color(0xff2d2d2d),
                            ]
                                : [
                              const Color(0xffF1E4CF),
                              const Color(0xfffaf1e6),
                              const Color(0xffF7F7F7),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: SingleChildScrollView(
                            child: Form(
                              key: formKey,
                              autovalidateMode: autoValidateMode,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: Center(
                                        child: Image.asset(
                                          'assets/mahallat_logoo1.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.03),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: _buildTextField(
                                        controller: fullNameController,
                                        hint: languageProvider.translate('signup.fullNameHint'),
                                        icon: Icons.person_2_outlined,
                                        width: width,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.028),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: _buildTextField(
                                        controller: emailController,
                                        hint: languageProvider.translate('signup.emailHint'),
                                        icon: Icons.email_outlined,
                                        width: width,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.028),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: _buildTextField(
                                        controller: passwordController,
                                        hint: languageProvider.translate('signup.passwordHint'),
                                        icon: Icons.lock_outline,
                                        width: width,
                                        isPassword: true,
                                        validator: validatePasswords,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.028),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: _buildTextField(
                                        controller: confirmPasswordController,
                                        hint: languageProvider.translate('signup.confirmPasswordHint'),
                                        icon: Icons.lock_outline,
                                        width: width,
                                        isPassword: true,
                                        isConfirmPassword: true,
                                        validator: validateConfirmPassword,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.028),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: _buildTextField(
                                        controller: phoneNumberController,
                                        hint: languageProvider.translate('signup.phoneHint'),
                                        icon: Icons.phone_android_rounded,
                                        width: width,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: height * 0.028),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: _buildTextField(
                                        controller: cityController,
                                        hint: languageProvider.translate('signup.cityHint'),
                                        icon: Icons.location_city_outlined,
                                        width: width,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: Center(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (formKey.currentState?.validate() ?? false) {
                                              setState(() => isLoading = true);
                                              try {
                                                await context.read<SignUpUserCubit>().createUserWithEmailAndPasswordUser(
                                                  email: emailController.text,
                                                  password: passwordController.text,
                                                  name: fullNameController.text,
                                                  phone: phoneNumberController.text,
                                                  profileImageUrl: '',
                                                  accountType: ['user'],
                                                  location: cityController.text,
                                                );

                                                await context.read<SignUpUserCubit>().sendEmailVerification();
                                                
                                                if (mounted) {
                                                  setState(() => isLoading = false);
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                                  );
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        languageProvider.translate('signup.success'),
                                                        style: GoogleFonts.cairo(),
                                                      ),
                                                      backgroundColor: Colors.green,
                                                      duration: const Duration(seconds: 5),
                                                      action: SnackBarAction(
                                                        label: languageProvider.translate('signup.resendVerification'),
                                                        textColor: Colors.white,
                                                        onPressed: () {
                                                          context.read<SignUpUserCubit>().resendVerificationEmail();
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                }

                                              } catch (e) {
                                                if (mounted) {
                                                  setState(() => isLoading = false);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          languageProvider.translate('signup.errors.createAccount'),
                                                          style: GoogleFonts.cairo()),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            } else {
                                              setState(() => autoValidateMode = AutovalidateMode.always);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: themeProvider.isDarkMode
                                                ? Colors.white
                                                : const Color(0xff503636),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.28,
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            elevation: 5,
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                              : Text(
                                            languageProvider.translate('signup.createAccount'),
                                            style: GoogleFonts.cairo(
                                              fontSize: 18,
                                              color: themeProvider.isDarkMode
                                                  ? Colors.black
                                                  : Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: FadeTransition(
                                      opacity: _fadeAnimation,
                                      child: SlideTransition(
                                        position: _slideAnimation,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            setState(() {
                                              isLoading = true;
                                            });
                                            try {
                                              await context.read<LoginCubitUser>().signInWithGoogleUser(context);
                                            } catch (e) {
                                              if (mounted) {
                                                setState(() {
                                                  isLoading = false;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      languageProvider.translate('signup.errors.googleSignup'),
                                                      style: GoogleFonts.cairo(),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: isLoading
                                              ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                            ),
                                          )
                                              : Image.asset(
                                            'assets/google.png',
                                            height: 24,
                                          ),
                                          label: Text(
                                            isLoading
                                                ? languageProvider.translate('signup.googleLoading')
                                                : languageProvider.translate('signup.googleSignup'),
                                            style: GoogleFonts.cairo(
                                              fontSize: 16,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(30),
                                              side: const BorderSide(color: Colors.white70),
                                            ),
                                            elevation: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const LoginPage()),
                                        ),
                                        child: Text(
                                          languageProvider.translate('signup.login'),
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            color: themeProvider.isDarkMode
                                                ? Colors.white
                                                : const Color(0xff503636),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        languageProvider.translate('signup.haveAccount'),
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: themeProvider.isDarkMode
                                              ? Colors.white
                                              : const Color(0xff503636),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double width,
    bool isPassword = false,
    bool isConfirmPassword = false,
    String? Function(String?)? validator,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? (isConfirmPassword ? _obscureConfirmPassword : _obscurePassword) : false,
        style: GoogleFonts.cairo(color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.cairo(color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xff503636)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isConfirmPassword
                        ? (_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility)
                        : (_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    color: const Color(0xff503636),
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirmPassword) {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      } else {
                        _obscurePassword = !_obscurePassword;
                      }
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 15),
        ),
        validator: validator ?? (value) {
          if (value == null || value.isEmpty) {
            return languageProvider.translate('signup.validation.required');
          }
          return null;
        },
      ),
    );
  }

  String? validatePasswords(String? value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (value == null || value.isEmpty) {
      return languageProvider.translate('signup.validation.passwordRequired');
    }
    if (value.length < 6) {
      return languageProvider.translate('signup.validation.passwordLength');
    }
    if (confirmPasswordController.text != passwordController.text) {
      return languageProvider.translate('signup.validation.passwordsMismatch');
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    if (value == null || value.isEmpty) {
      return languageProvider.translate('signup.validation.confirmPasswordRequired');
    }
    if (value != passwordController.text) {
      return languageProvider.translate('signup.validation.passwordsMismatch');
    }
    return null;
  }
}