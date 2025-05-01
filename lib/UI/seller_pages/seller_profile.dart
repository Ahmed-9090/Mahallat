import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../auth/Data/models/stores_model.dart';
import '../../logic/products_cubits/products_cubit.dart';
import '../../logic/stores_cubits/store_cubit.dart';
import '../../providers/language_provider.dart';
import '../login_page.dart';
import '../splash_screen.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key});

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  bool _isDeleting = false;
  DateTime? _lastBackPressTime;

  Future<bool> _showDeleteConfirmation(StoreModel? store) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    bool deletionSucceeded = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            languageProvider.translate('sellerProfile.deleteAccountConfirmation'),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.right,
          ),
          content: Text(
            languageProvider.translate('sellerProfile.deleteAccountMessage'),
            style: GoogleFonts.cairo(),
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                languageProvider.translate('sellerProfile.cancel'),
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  setState(() {
                    _isDeleting = true;
                  });

                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    if (store != null) {
                      final storeCubit = context.read<StoreCubit>();
                      final productsCubit = context.read<ProductsCubit>();

                      await storeCubit.deleteStore(store.storeId);

                      for (var storeType in store.storeTypes) {
                        await productsCubit.deleteAllProductsForSeller(
                          store.sellerId,
                          storeType,
                        );
                      }
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .delete();

                    try {
                      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                      final profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';
                      if (profileImageUrl != null && profileImageUrl != '') {
                        await FirebaseStorage.instance
                            .ref()
                            .child('profile_images/${user.uid}.jpg')
                            .delete();
                      }
                    } catch (e) {
                      // تجاهل أي خطأ في حذف الصورة
                    }

                    await user.delete();

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('email');
                    await prefs.remove('password');

                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }

                    deletionSucceeded = true;
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          languageProvider.translate('sellerProfile.deleteError').replaceAll('{error}', e.toString()),
                        ),
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isDeleting = false;
                    });
                  }
                }
              },
              child: Text(
                languageProvider.translate('sellerProfile.delete'),
                style: GoogleFonts.cairo(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    return deletionSucceeded;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Future.microtask(() {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      });
      return const SizedBox();
    }
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

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
        appBar: AppBar(
          backgroundColor: const Color(0xffF1E4CF),
          elevation: 0,
          title: Text(
            languageProvider.translate('sellerProfile.title'),
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xff503636),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SplashScreen()),
                      (route) => false,
                  );
                }
              },
              icon: Icon(
                Icons.logout,
                color: const Color(0xff503636),
                size: width * 0.06,
              ),
            ),
          ],
        ),
        body: _isDeleting
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  languageProvider.translate('sellerProfile.loadingError'),
                  style: GoogleFonts.cairo(),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  languageProvider.translate('sellerProfile.noData'),
                  style: GoogleFonts.cairo(),
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final name = userData['name'] ?? 'غير محدد';
            final email = userData['email'] ?? 'غير محدد';
            final phone = userData['phone'] ?? 'غير محدد';
            final accountTypes = List<String>.from(userData['accountType'] ?? []);

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stores')
                  .where('sellerId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, storeSnapshot) {
                if (storeSnapshot.hasError) {
                  return Center(
                    child: Text(
                      languageProvider.translate('sellerProfile.loadingError'),
                      style: GoogleFonts.cairo(),
                    ),
                  );
                }

                if (storeSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stores = storeSnapshot.data?.docs
                    .map((doc) => StoreModel.fromFirestore(doc))
                    .toList() ??
                    [];

                return SingleChildScrollView(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Column(
                    children: [
                      // Profile Image
                      Container(
                        width: width * 0.3,
                        height: width * 0.3,
                        decoration: BoxDecoration(
                          color: const Color(0xff503636),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            size: width * 0.15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: height * 0.03),

                      // User Info Cards
                      _buildInfoCard(
                        title: languageProvider.translate('sellerProfile.name'),
                        value: name,
                        icon: Icons.person_outline,
                      ),
                      _buildInfoCard(
                        title: languageProvider.translate('sellerProfile.email'),
                        value: email,
                        icon: Icons.email_outlined,
                      ),
                      _buildInfoCard(
                        title: languageProvider.translate('sellerProfile.phone'),
                        value: phone,
                        icon: Icons.phone_outlined,
                      ),
                      _buildInfoCard(
                        title: languageProvider.translate('sellerProfile.accountType'),
                        value: accountTypes.join(' - '),
                        icon: Icons.store_outlined,
                      ),

                      SizedBox(height: height * 0.04),

                      // Delete Account Button
                      TextButton.icon(
                        onPressed: () async {
                          final deletionSuccess = await _showDeleteConfirmation(
                            stores.isNotEmpty ? stores.first : null,
                          );

                          if (deletionSuccess && mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                                  (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: Text(
                          languageProvider.translate('sellerProfile.deleteAccount'),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff503636), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff503636),
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
