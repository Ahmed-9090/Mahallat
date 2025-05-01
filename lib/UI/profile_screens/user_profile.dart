import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../auth/Data/models/user_model.dart';
import '../home_screens/shakawy.dart';
import '../home_screens/tager.dart';
import '../maps/adress_managment.dart';
import '../splash_screen.dart';
import '../profile_screens/edit_user_profile.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'about_app_user.dart';
import 'my_oeders.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isDarkMode = false;
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  final ImagePicker _picker = ImagePicker();
  bool isUploadingImage = false;

  Future<UserModel?> _fetchUserData() async {
    if (uid == null) return null;
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
    } catch (e) {
      print("خطأ في جلب البيانات: $e");
    }
    return null;
  }

  Future<void> _uploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        isUploadingImage = true;
      });

      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_images/$uid.jpg',
      );
      await storageRef.putFile(File(image.path));

      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
      });

      setState(() {
        isUploadingImage = false;
      });

      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('profile.imageUpdateSuccess'),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isUploadingImage = false;
      });
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('profile.imageUpdateError'),
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchSocial(String url, String fallbackUrl) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      await launchUrl(
        Uri.parse(fallbackUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<bool> _isInstagramInstalled() async {
    const scheme = 'instagram://';
    try {
      return await canLaunchUrl(Uri.parse(scheme));
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffF1E4CF), Color(0xffF1E4CF), Colors.white],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: FutureBuilder<UserModel?>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  languageProvider.translate('profile.loadingError'),
                  style: GoogleFonts.cairo(fontSize: width * 0.04),
                ),
              );
            }

            UserModel user = snapshot.data!;

            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Bar
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.01,
                      ),
                      decoration: const BoxDecoration(color: Color(0xffF1E4CF)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            languageProvider.translate('profile.title'),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Profile Image
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: height * 0.02),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (user.profileImageUrl != null &&
                                    user.profileImageUrl!.isNotEmpty) {
                                  _showFullImage(user.profileImageUrl!);
                                }
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: width * 0.12,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage:
                                        user.profileImageUrl != null &&
                                                user.profileImageUrl!.isNotEmpty
                                            ? NetworkImage(
                                              user.profileImageUrl!,
                                            )
                                            : null,
                                    child:
                                        user.profileImageUrl == null ||
                                                user.profileImageUrl!.isEmpty
                                            ? Icon(
                                              Icons.person,
                                              size: width * 0.12,
                                              color: Colors.grey[400],
                                            )
                                            : null,
                                  ),
                                  if (isUploadingImage)
                                    SizedBox(
                                      width: width * 0.24,
                                      height: width * 0.24,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.orange,
                                            ),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!isUploadingImage &&
                                (user.profileImageUrl == null ||
                                    user.profileImageUrl!.isEmpty))
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: width * 0.05,
                                    ),
                                    onPressed: _uploadImage,
                                    constraints: BoxConstraints(
                                      minWidth: width * 0.08,
                                      minHeight: width * 0.08,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Account Section
                    Padding(
                      padding: EdgeInsets.all(width * 0.04),
                      child: Column(
                        crossAxisAlignment:
                            isArabic
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            alignment:
                                isArabic
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Text(
                              languageProvider.translate('profile.account'),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.06,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),

                          // Profile Settings
                          Container(
                            alignment:
                                isArabic
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(width * 0.03),
                            ),
                            margin: EdgeInsets.symmetric(
                              vertical: height * 0.01,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.02,
                            ),
                            child: _buildSettingsItem(
                              icon: Icons.person_outline,
                              iconColor: Colors.orange,
                              title: 'profile.profileSettings',
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const EditUserProfile(),
                                  ),
                                );
                                if (result != null && mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),

                          // Profile Information
                          _buildSettingsItem(
                            icon: Icons.info_outline,
                            iconColor: Colors.orange,
                            title: 'profile.profileInfo',
                            onTap:
                                () => _showProfileInformationDialog(
                                  context,
                                  user,
                                ),
                          ),

                          // My Orders
                          _buildSettingsItem(
                            icon: Icons.history,
                            iconColor: Colors.orange,
                            title: 'profile.myOrders',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyOeders(),
                                ),
                              );
                            },
                          ),

                          // Manage addresses
                          _buildSettingsItem(
                            icon: Icons.location_on_outlined,
                            iconColor: Colors.orange,
                            title: 'profile.addressManagement',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdressManagment(),
                                ),
                              );
                            },
                          ),

                          // Become a Seller
                          _buildSettingsItem(
                            icon: Icons.store_outlined,
                            iconColor: Colors.orange,
                            title: 'profile.becomeSeller',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const tager(),
                                ),
                              );
                            },
                          ),

                          // Change Language
                          _buildLanguageItem(onTap: () {}),

                          SizedBox(height: height * 0.02),

                          // About & support Section
                          Container(
                            width: double.infinity,
                            alignment:
                                isArabic
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            margin: EdgeInsets.only(top: height * 0.02),
                            padding: EdgeInsets.all(width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(width * 0.03),
                            ),
                            child: Text(
                              languageProvider.translate(
                                'profile.aboutAndSupport',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.06,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),

                          // Help Center
                          _buildSettingsItem(
                            icon: Icons.help_outline,
                            iconColor: Colors.grey,
                            title: 'profile.helpCenter',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Shakawy(),
                                ),
                              );
                            },
                          ),

                          // Social Media Section
                          Container(
                            width: double.infinity,
                            alignment:
                                isArabic
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            margin: EdgeInsets.only(top: height * 0.02),
                            padding: EdgeInsets.all(width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(width * 0.03),
                            ),
                            child: Text(
                              languageProvider.translate('profile.followUs'),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.06,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.02),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () async {
                                  await _launchSocial(
                                    'https://www.facebook.com/share/1Aud2q44Wg/',
                                    'https://www.facebook.com/share/16aHX3Wc7B/',
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(width * 0.03),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[800],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.facebook,
                                    color: Colors.white,
                                    size: width * 0.07,
                                  ),
                                ),
                              ),
                              SizedBox(width: width * 0.05),
                              InkWell(
                                onTap: () async {
                                  if (await _isInstagramInstalled()) {
                                    await launchUrl(
                                      Uri.parse(
                                        'instagram://user?username=mahallat.jo',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    await launchUrl(
                                      Uri.parse(
                                        'https://www.instagram.com/mahallat.jo',
                                      ),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(width * 0.03),
                                  decoration: BoxDecoration(
                                    color: Colors.pink[400],
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/insta_logo.png',
                                    width: width * 0.07,
                                    height: width * 0.07,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.03),

                          // Logout
                          _buildLogoutButton(
                            onTap: () => _showLogoutDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: height * 0.02),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            if (!isArabic) ...[
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(width * 0.02),
                ),
                child: Icon(icon, color: iconColor, size: width * 0.05),
              ),
              SizedBox(width: width * 0.04),
            ],
            Expanded(
              child: Text(
                languageProvider.translate(title),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
            ),
            if (isArabic) ...[
              SizedBox(width: width * 0.04),
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(width * 0.02),
                ),
                child: Icon(icon, color: iconColor, size: width * 0.05),
              ),
            ],
            SizedBox(width: width * 0.02),
            Icon(
              isArabic ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
              color: Colors.grey,
              size: width * 0.04,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem({required VoidCallback onTap}) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                languageProvider.translate('profile.changeLanguage'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      languageProvider.translate('home.arabic'),
                      style: GoogleFonts.cairo(fontSize: width * 0.04),
                    ),
                    trailing:
                        languageProvider.currentLocale.languageCode == 'ar'
                            ? Icon(Icons.check, color: Colors.green)
                            : null,
                    onTap: () async {
                      await languageProvider.changeLanguage('ar');
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      languageProvider.translate('home.english'),
                      style: GoogleFonts.cairo(fontSize: width * 0.04),
                    ),
                    trailing:
                        languageProvider.currentLocale.languageCode == 'en'
                            ? Icon(Icons.check, color: Colors.green)
                            : null,
                    onTap: () async {
                      await languageProvider.changeLanguage('en');
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: height * 0.02),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            if (!isArabic) ...[
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(width * 0.02),
                ),
                child: Icon(
                  Icons.language,
                  color: Colors.orange,
                  size: width * 0.05,
                ),
              ),
              SizedBox(width: width * 0.04),
            ],
            Text(
              languageProvider.currentLocale.languageCode == 'ar'
                  ? languageProvider.translate('home.arabic')
                  : languageProvider.translate('home.english'),
              style: GoogleFonts.cairo(
                fontSize: width * 0.04,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: width * 0.02),
            Expanded(
              child: Text(
                languageProvider.translate('profile.changeLanguage'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
            ),
            if (isArabic) ...[
              SizedBox(width: width * 0.04),
              Container(
                padding: EdgeInsets.all(width * 0.02),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(width * 0.02),
                ),
                child: Icon(
                  Icons.language,
                  color: Colors.orange,
                  size: width * 0.05,
                ),
              ),
            ],
            SizedBox(width: width * 0.02),
            Icon(
              isArabic ? Icons.arrow_forward_ios : Icons.arrow_forward_ios,
              color: Colors.grey,
              size: width * 0.04,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton({required VoidCallback onTap}) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: height * 0.02),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade200),
          borderRadius: BorderRadius.circular(width * 0.02),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isArabic) ...[
              Icon(Icons.logout, color: Colors.red, size: width * 0.05),
              SizedBox(width: width * 0.02),
            ],
            Text(
              languageProvider.translate('profile.logout'),
              style: GoogleFonts.cairo(
                color: Colors.red,
                fontSize: width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isArabic) ...[
              SizedBox(width: width * 0.02),
              Icon(Icons.logout, color: Colors.red, size: width * 0.05),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final width = MediaQuery.of(context).size.width;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            languageProvider.translate('profile.logoutConfirmation'),
            style: GoogleFonts.cairo(
              fontSize: width * 0.045,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            languageProvider.translate('profile.logoutMessage'),
            style: GoogleFonts.cairo(fontSize: width * 0.04),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                languageProvider.translate('profile.cancel'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.04,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => SplashScreen()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageProvider.translate('profile.logoutSuccess'),
                        style: GoogleFonts.cairo(fontSize: width * 0.035),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(
                languageProvider.translate('profile.confirm'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.04,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProfileInformationDialog(
    BuildContext context,
    UserModel user,
  ) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffF1E4CF),
              borderRadius: BorderRadius.circular(width * 0.06),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: height * 0.02,
                      horizontal: width * 0.05,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.brown[800],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(width * 0.06),
                        topRight: Radius.circular(width * 0.06),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          languageProvider.translate(
                            'profile.profileInfoTitle',
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: width * 0.06,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(width * 0.06),
                    child: Column(
                      children: [
                        if (user.profileImageUrl != null &&
                            user.profileImageUrl!.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.brown[300]!,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: width * 0.15,
                              backgroundImage: NetworkImage(
                                user.profileImageUrl!,
                              ),
                            ),
                          ),
                        SizedBox(height: height * 0.03),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(width * 0.05),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.transparent.withOpacity(0.08),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.05),
                            child: Column(
                              children: [
                                _buildInfoRow('profile.name', user.name),
                                _buildInfoRow('profile.email', user.email),
                                _buildInfoRow('profile.phone', user.phone),
                                _buildInfoRow(
                                  'profile.location',
                                  user.location,
                                ),
                                _buildInfoRow(
                                  'profile.accountType',
                                  user.accountType.join(', '),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String labelKey, String value) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(vertical: height * 0.01),
      child: Column(
        crossAxisAlignment:
            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            languageProvider.translate(labelKey),
            style: GoogleFonts.cairo(
              fontSize: width * 0.04,
              color: Colors.brown[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: height * 0.01),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: height * 0.01,
              horizontal: width * 0.04,
            ),
            decoration: BoxDecoration(
              color: Colors.brown[50],
              borderRadius: BorderRadius.circular(width * 0.03),
              border: Border.all(color: Colors.brown[200]!, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.cairo(
                      fontSize: width * 0.045,
                      fontWeight: FontWeight.w500,
                      color: Colors.brown[800],
                    ),
                    textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
