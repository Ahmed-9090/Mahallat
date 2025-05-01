import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mahalattst2/UI/signup_screens/signup_user.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logic/login_cubits/login_cubiit_users/login_cubit_user.dart';
import '../logic/login_cubits/login_cubiit_users/login_states_user.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import 'home_screens/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isDarkMode = false;
  bool isLoading = false;
  bool _rememberMe = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool isPhoneVerification = false;
  bool isPhoneLogin = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DateTime? _lastBackPressTime;

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
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // تحميل بيانات تسجيل الدخول المحفوظة
    _loadSavedLoginData();
  }

  Future<void> _loadSavedLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveLoginData() async {
    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('rememberMe');
    }
  }

  Future<void> _checkLoginState() async {
    // Wait for a short delay to show the login page
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Check if user is already logged in
    final user = _auth.currentUser;
    await user?.reload(); // مهم تعمل reload عشان تجيب آخر حالة للـ verification
    final updatedUser = _auth.currentUser;

    if (updatedUser != null && updatedUser.emailVerified) {
      // User is logged in and email is verified
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    } else {
      // ممكن تضيف رسالة تقول إن الحساب مش متفعل
      print('User is not verified or not logged in');
      // أو تودي المستخدم لصفحة تطلب منه التفعيل مثلاً
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isPortrait = height > width;
    
    return WillPopScope(
      onWillPop: () async {
        if (_lastBackPressTime == null ||
            DateTime.now().difference(_lastBackPressTime!) >
                const Duration(seconds: 2)) {
          _lastBackPressTime = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              width: width * 0.6,
              content: Text(
                languageProvider.translate('home.pressAgainToExit'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              backgroundColor: const Color(0xff503636),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.02,
                vertical: height * 0.015,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(width * 0.02),
              ),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: isDarkMode ? const Color(0xff0d0d0d) : const Color(0xffF1E4CF),
          elevation: 0,
          actions: [
            IconButton(
              icon: Text(
                languageProvider.currentLocale.languageCode == 'ar' ? 'EN' : 'عربي',
                style: GoogleFonts.cairo(
                  color: isDarkMode ? Colors.white : const Color(0xff503636),
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
              ),
              onPressed: () {
                languageProvider.changeLanguage(
                  languageProvider.currentLocale.languageCode == 'ar' ? 'en' : 'ar'
                );
              },
            ),
          ],
        ),
        body: BlocListener<LoginCubitUser, LoginStateUser>(
          listener: (context, state) {
            if (state is LoginSuccessUserState) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    languageProvider.translate('login.success'),
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is LoginErrorUserState) {
              setState(() => isLoading = false);
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
          child: ModalProgressHUD(
            inAsyncCall: isLoading,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                    const Color(0xff0d0d0d),
                    const Color(0xff1a1a1a),
                    const Color(0xff2d2d2d),
                  ]
                      : [
                    const Color(0xffF1E4CF),
                    const Color(0xfffaf1e6),
                    Colors.white,
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: isPortrait ? height * 0.25 : height * 0.4,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'assets/mahallat_logoo1.png',
                                      height: isPortrait ? height * 0.12 : height * 0.2,
                                      width: isPortrait ? width * 0.6 : width * 0.4,
                                    ),
                                    SizedBox(height: height * 0.02),
                                    Text(
                                      languageProvider.translate('login.welcome'),
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.06,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : const Color(0xff503636).withOpacity(0.8),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.01),
                                    DefaultTextStyle(
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.04,
                                        color: isDarkMode ? Colors.white70 : const Color(0xff503636).withOpacity(.8),
                                      ),
                                      child: AnimatedTextKit(
                                        animatedTexts: [
                                          FadeAnimatedText(
                                            languageProvider.translate('login.slogans.professional'),
                                            duration: const Duration(milliseconds: 2000),
                                          ),
                                          FadeAnimatedText(
                                            languageProvider.translate('login.slogans.trusted'),
                                            duration: const Duration(milliseconds: 2000),
                                          ),
                                          FadeAnimatedText(
                                            languageProvider.translate('login.slogans.fast'),
                                            duration: const Duration(milliseconds: 2000),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.04),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(width * 0.04),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              style: GoogleFonts.inter(
                                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                fontSize: width * 0.04,
                              ),
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: languageProvider.translate('login.email.label'),
                                labelStyle: GoogleFonts.cairo(
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  fontSize: width * 0.04,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(width * 0.04),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  size: width * 0.06,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider.translate('login.email.error');
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(width * 0.04),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              style: GoogleFonts.inter(
                                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                fontSize: width * 0.04,
                              ),
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: languageProvider.translate('login.password.label'),
                                labelStyle: GoogleFonts.cairo(
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  fontSize: width * 0.04,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(width * 0.04),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                  size: width * 0.06,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                                    size: width * 0.06,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider.translate('login.password.error');
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: isLoading ? null : _showResetPasswordDialog,
                              child: Text(
                                languageProvider.translate('login.forgotPassword'),
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.035,
                                  color: isDarkMode ? Colors.white70 : const Color(0xff503636).withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.015),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xff503636),
                                  ),
                                  Text(
                                    languageProvider.translate('login.rememberMe'),
                                    style: GoogleFonts.cairo(
                                      fontSize: width * 0.035,
                                      color: isDarkMode ? Colors.white : const Color(0xff503636),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          if (!isPhoneVerification)
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      setState(() {
                                        isLoading = true;
                                      });

                                      try {
                                        await context.read<LoginCubitUser>().signInWithEmailAndPasswordUser(
                                          _emailController.text,
                                          _passwordController.text,
                                          context,
                                        );
                                        await _saveLoginData();
                                      } catch (e) {
                                        if (mounted) {
                                          setState(() => isLoading = false);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                languageProvider.translate('login.errors.loginFailed'),
                                                style: GoogleFonts.cairo(),
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkMode ? Colors.white : const Color(0xff503636),
                                    padding: EdgeInsets.symmetric(
                                      vertical: height * 0.02,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(width * 0.08),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: width * 0.06,
                                          height: width * 0.06,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          languageProvider.translate('login.loginButton'),
                                          style: GoogleFonts.cairo(
                                            fontSize: width * 0.045,
                                            color: isDarkMode ? Colors.black : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          SizedBox(height: height * 0.02),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const UserSignupScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      languageProvider.translate('login.signup'),
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.04,
                                        color: isDarkMode ? Colors.white : const Color(0xff503636).withOpacity(0.8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '  |    ${languageProvider.translate('login.noAccount')} ',
                                    style: GoogleFonts.cairo(
                                      fontSize: width * 0.04,
                                      color: isDarkMode ? Colors.white : const Color(0xff503636).withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          FadeTransition(
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
                                            languageProvider.translate('login.errors.unexpected'),
                                            style: GoogleFonts.cairo(),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: isLoading
                                    ? SizedBox(
                                  width: width * 0.06,
                                  height: width * 0.06,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                  ),
                                )
                                    : Image.asset(
                                  'assets/google.png',
                                  height: width * 0.06,
                                ),
                                label: Text(
                                  isLoading 
                                      ? languageProvider.translate('login.loading')
                                      : languageProvider.translate('login.googleLogin'),
                                  style: GoogleFonts.cairo(
                                    fontSize: width * 0.04,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.05,
                                    vertical: height * 0.015,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(width * 0.08),
                                    side: const BorderSide(color: Colors.white70),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          languageProvider.translate('login.resetPassword.title'),
          style: GoogleFonts.cairo(
            color: isDarkMode ? Colors.white : const Color(0xff503636),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: emailController,
          style: GoogleFonts.cairo(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: languageProvider.translate('login.resetPassword.email'),
            hintText: languageProvider.translate('login.resetPassword.emailHint'),
            labelStyle: GoogleFonts.cairo(
              color: isDarkMode ? Colors.white70 : const Color(0xff503636).withOpacity(0.8),
            ),
            hintStyle: GoogleFonts.cairo(
              color: isDarkMode ? Colors.white54 : Colors.grey,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white30 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white70 : const Color(0xff503636),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              languageProvider.translate('login.resetPassword.cancel'),
              style: GoogleFonts.cairo(
                color: isDarkMode ? Colors.white70 : const Color(0xff503636),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _resetPassword(emailController.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              languageProvider.translate('login.resetPassword.send'),
              style: GoogleFonts.cairo(
                color: isDarkMode ? Colors.white : const Color(0xff503636),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(String email) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    try {
      setState(() {
        isLoading = true;
      });

      await _auth.sendPasswordResetEmail(email: email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('login.resetPassword.success'),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = languageProvider.translate('login.resetPassword.errors.userNotFound');
          break;
        case 'invalid-email':
          errorMessage = languageProvider.translate('login.resetPassword.errors.invalidEmail');
          break;
        default:
          errorMessage = languageProvider.translate('login.resetPassword.errors.default');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('login.errors.unexpected'),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}