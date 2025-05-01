import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';

class AboutAppSeller extends StatefulWidget {
  const AboutAppSeller({super.key});

  @override
  State<AboutAppSeller> createState() => _AboutAppSellerState();
}

class _AboutAppSellerState extends State<AboutAppSeller> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xffF1E4CF),
      appBar: AppBar(
        backgroundColor: const Color(0xffF1E4CF),
        elevation: 0,
        title: Text(
          languageProvider.translate('aboutAppSeller.title'),
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xff503636),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xff503636)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Animated background icons
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      left: width * 0.05,
                      top: height * 0.1,
                      child: Transform.rotate(
                        angle: _animation.value,
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: width * 0.1,
                          color: const Color(0xff503636).withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: width * 0.1,
                      top: height * 0.2,
                      child: Transform.rotate(
                        angle: -_animation.value * 0.8,
                        child: Icon(
                          Icons.checkroom_outlined,
                          size: width * 0.11,
                          color: const Color(0xff503636).withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: width * 0.15,
                      top: height * 0.7,
                      child: Transform.rotate(
                        angle: _animation.value * 0.6,
                        child: Icon(
                          Icons.local_mall_outlined,
                          size: width * 0.09,
                          color: const Color(0xff503636).withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      right: width * 0.08,
                      top: height * 0.8,
                      child: Transform.rotate(
                        angle: -_animation.value * 1.2,
                        child: Icon(
                          Icons.store_outlined,
                          size: width * 0.12,
                          color: const Color(0xff503636).withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: height * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.02),
                      Center(
                        child: Icon(
                          Icons.store_mall_directory,
                          size: width * 0.25,
                          color: const Color(0xff503636),
                        ),
                      ),
                      SizedBox(height: height * 0.03),
                      Text(
                        languageProvider.translate('aboutAppSeller.greeting'),
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff503636),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(height: height * 0.03),
                      _buildSection(
                        languageProvider.translate('aboutAppSeller.sections.subscriptionFees.title'),
                        languageProvider.translate('aboutAppSeller.sections.subscriptionFees.content'),
                        Icons.monetization_on_outlined,
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.02),
                      _buildSection(
                        languageProvider.translate('aboutAppSeller.sections.cancelSubscription.title'),
                        languageProvider.translate('aboutAppSeller.sections.cancelSubscription.content'),
                        Icons.cancel_outlined,
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.02),
                      _buildSection(
                        languageProvider.translate('aboutAppSeller.sections.imageQuality.title'),
                        languageProvider.translate('aboutAppSeller.sections.imageQuality.content'),
                        Icons.image_outlined,
                        width,
                        height,
                      ),
                      SizedBox(height: height * 0.03),
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(width * 0.05),
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
                            children: [
                              Text(
                                languageProvider.translate('aboutAppSeller.footer.thankYou'),
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.045,
                                  color: const Color(0xff503636),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                languageProvider.translate('aboutAppSeller.footer.signature'),
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff503636),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.05),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, double width, double height) {
    return Container(
      margin: EdgeInsets.only(bottom: height * 0.02),
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
          Row(
            children: [
              Icon(icon, color: const Color(0xff503636), size: width * 0.07),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff503636),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.015),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: width * 0.045,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
} 