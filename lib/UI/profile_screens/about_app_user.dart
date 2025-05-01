import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'dart:math' as math;

class AboutAppUser extends StatefulWidget {
  const AboutAppUser({super.key});

  @override
  State<AboutAppUser> createState() => _AboutAppUserState();
}

class _AboutAppUserState extends State<AboutAppUser>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
        backgroundColor: const Color(0xffF1E4CF),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffF1E4CF), Colors.white],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Animated background icons
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Positioned(
                            left: width * 0.12,
                            top: height * 0.12,
                            child: Transform.rotate(
                              angle: _animation.value,
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: width * 0.1,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            right: width * 0.12,
                            top: height * 0.25,
                            child: Transform.rotate(
                              angle: -_animation.value,
                              child: Icon(
                                Icons.dry_cleaning_outlined,
                                size: width * 0.1,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            left: width * 0.25,
                            bottom: height * 0.25,
                            child: Transform.rotate(
                              angle: _animation.value * 0.5,
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: width * 0.1,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Main content
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: height * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            languageProvider.translate('aboutApp.title'),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.03),
                      // App description
                      _buildInfoCard(
                        languageProvider.translate('aboutApp.appDescription.title'),
                        languageProvider.translate('aboutApp.appDescription.content'),
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.02),
                      // Important notices
                      _buildInfoCard(
                        languageProvider.translate('aboutApp.importantNotices.title'),
                        languageProvider.translate('aboutApp.importantNotices.content'),
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.02),
                      // Become a seller
                      _buildInfoCard(
                        languageProvider.translate('aboutApp.becomeSeller.title'),
                        languageProvider.translate('aboutApp.becomeSeller.content'),
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.02),
                      // Become a driver
                      _buildInfoCard(
                        languageProvider.translate('aboutApp.becomeDriver.title'),
                        languageProvider.translate('aboutApp.becomeDriver.content'),
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.02),
                      // Contact us
                      _buildInfoCard(
                        languageProvider.translate('aboutApp.contactUs.title'),
                        languageProvider.translate('aboutApp.contactUs.content'),
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.05),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: width * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: height * 0.01),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: width * 0.035,
              color: Colors.black,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
