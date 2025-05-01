import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mahalattst2/UI/signup_screens/signup_user.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import 'home_screens/home_page.dart';
import 'login_page.dart';

class WelcomeItem {
  final String titleKey;
  final String imagePath;
  final IconData icon;

  WelcomeItem({
    required this.titleKey,
    required this.imagePath,
    required this.icon,
  });
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _showButtons = false;
  bool isDarkMode = false;
  final ScrollController _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  DateTime? _lastBackPressTime;

  late List<WelcomeItem> welcomeItems;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      setState(() {
        _showButtons = true;
      });
    });

    // Check for persistent login
    _checkLoginState();

    // بدء التمرير التلقائي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _initializeWelcomeItems(BuildContext context) {
    Provider.of<LanguageProvider>(context, listen: false);
    
    welcomeItems = [
      WelcomeItem(
        titleKey: "splash.categories.bags",
        imagePath: "assets/categories/bags.jpg",
        icon: Icons.shopping_bag,
      ),
      WelcomeItem(
        titleKey: "splash.categories.kidsClothes",
        imagePath: "assets/categories/childclothes.jpg",
        icon: Icons.child_care,
      ),
      WelcomeItem(
        titleKey: "splash.categories.kidsShoes",
        imagePath: "assets/categories/childshoes.jpg",
        icon: Icons.child_friendly,
      ),
      WelcomeItem(
        titleKey: "splash.categories.healthCare",
        imagePath: "assets/categories/healthcare.jpg",
        icon: Icons.spa,
      ),
      WelcomeItem(
        titleKey: "splash.categories.mensShoes",
        imagePath: "assets/categories/menshoes.jpg",
        icon: Icons.man,
      ),
      WelcomeItem(
        titleKey: "splash.categories.womensClothes",
        imagePath: "assets/categories/womanclothes.jpg",
        icon: Icons.woman,
      ),
      WelcomeItem(
        titleKey: "splash.categories.womensShoes",
        imagePath: "assets/categories/womenshoes.jpg",
        icon: Icons.woman,
      ),
      WelcomeItem(
        titleKey: "splash.categories.mensClothes",
        imagePath: "assets/categories/menclothes.jpg",
        icon: Icons.man,
      ),
    ];
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

  void _startAutoScroll() {
    if (_scrollController.hasClients) {
      double maxScrollExtent = _scrollController.position.maxScrollExtent;
      double currentPosition = _scrollController.position.pixels;

      // إذا وصلنا إلى نهاية القائمة
      if (currentPosition >= maxScrollExtent) {
        // العودة إلى البداية بسلاسة
        _scrollController.jumpTo(0);
      }

      // استمرار التمرير
      _scrollController
          .animateTo(
            maxScrollExtent,
            duration: const Duration(seconds: 15),
            curve: Curves.linear,
          )
          .then((_) {
            if (mounted) {
              _startAutoScroll();
            }
          });
    } else {
      // إذا لم يكن ListView جاهزاً بعد، نحاول مرة أخرى بعد فترة قصيرة
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _startAutoScroll();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    // Initialize welcome items with translations
    _initializeWelcomeItems(context);
    
    return WillPopScope(
      onWillPop: () async {
        if (_lastBackPressTime == null ||
            DateTime.now().difference(_lastBackPressTime!) >
                const Duration(seconds: 2)) {
          _lastBackPressTime = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              width: width * 0.5,
              content: Text(
                languageProvider.translate('home.pressAgainToExit'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              backgroundColor: const Color(0xffF1E4CF),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.02,
                vertical: height * 0.015,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(width * 0.1),
              ),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor:
            isDarkMode ? const Color(0xff1a1a1a) : const Color(0xff1D48A5),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  isDarkMode
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
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Stack(
                      children: [
                        Center(
                          child: Image.asset('assets/mahallat_logoo.png'),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? Colors.white.withOpacity(0.1) 
                                  : Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.language,
                                color: isDarkMode 
                                    ? Colors.white 
                                    : const Color(0xff503636),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      languageProvider.translate('home.selectLanguage'),
                                      style: GoogleFonts.cairo(),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: const Icon(Icons.language),
                                          title: Text(
                                            languageProvider.translate('home.arabic'),
                                            style: GoogleFonts.cairo(),
                                          ),
                                          onTap: () {
                                            languageProvider.changeLanguage('ar');
                                            Navigator.pop(context);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.language),
                                          title: Text(
                                            languageProvider.translate('home.english'),
                                            style: GoogleFonts.cairo(),
                                          ),
                                          onTap: () {
                                            languageProvider.changeLanguage('en');
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                children: [
                                  Container(
                                    height: 80,
                                    margin: const EdgeInsets.symmetric(vertical: 20),
                                    child: ListView.builder(
                                      controller: _scrollController,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: welcomeItems.length * 3,
                                      itemBuilder: (context, index) {
                                        return _buildWelcomeItem(
                                          welcomeItems[index % welcomeItems.length],
                                          languageProvider,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DefaultTextStyle(
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      color:isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                    child: AnimatedTextKit(
                                      animatedTexts: [
                                        FadeAnimatedText(
                                          languageProvider.translate('splash.slogans.professional'),
                                          duration: const Duration(
                                            milliseconds: 2000,
                                          ),
                                        ),
                                        FadeAnimatedText(
                                          languageProvider.translate('splash.slogans.trusted'),
                                          duration: const Duration(
                                            milliseconds: 2000,
                                          ),
                                        ),
                                        FadeAnimatedText(
                                          languageProvider.translate('splash.slogans.fast'),
                                          duration: const Duration(
                                            milliseconds: 2000,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showButtons)
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 40,
                                    left: 30,
                                    right: 30,
                                  ),
                                  child: Column(
                                    children: [
                                      _buildButton(
                                        languageProvider.translate('splash.buttons.login'),
                                        Icons.login,
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const LoginPage(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildButton(
                                        languageProvider.translate('splash.buttons.signup'),
                                        Icons.person_add,
                                        () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => const UserSignupScreen(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDarkMode ? Colors.grey[800] : Color(0xff503636),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isDarkMode ? Colors.white : Colors.white),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeItem(WelcomeItem item, LanguageProvider languageProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.white.withOpacity(0.1) 
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.2) 
                  : const Color(0xff503636).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 18,
              color: isDarkMode 
                  ? Colors.white 
                  : const Color(0xff503636),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            languageProvider.translate(item.titleKey),
            style: GoogleFonts.cairo(
              color: isDarkMode 
                  ? Colors.white 
                  : const Color(0xff503636),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
