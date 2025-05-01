import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'dart:io';
import 'user_profile.dart';
import '../../auth/Data/models/user_model.dart';
import '../../logic/signup_cubits/signup_user_cubits/signup_user_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../UI/login_page.dart';

class EditUserProfile extends StatefulWidget {
  const EditUserProfile({super.key});

  @override
  _EditUserProfileState createState() => _EditUserProfileState();
}

class _EditUserProfileState extends State<EditUserProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _picker = ImagePicker();
  bool isDarkMode = false;
  bool isLoading = false;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

      if (doc.exists) {
        UserModel user = UserModel.fromMap(doc.data()!);
        setState(() {
          _nameController.text = user.name;
          _phoneController.text = user.phone;
          profileImageUrl = user.profileImageUrl;
        });
      }
    } catch (e) {
      print("خطأ في تحميل البيانات: $e");
    }
  }

  Future<void> _uploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        isLoading = true;
      });

      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${FirebaseAuth.instance.currentUser?.uid}.jpg');
      await storageRef.putFile(File(image.path));
      
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
        'profileImageUrl': imageUrl,
      });

      setState(() {
        profileImageUrl = imageUrl;
        isLoading = false;
      });
      
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('profile.imageUpdateSuccess'), style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, {'profileImageUrl': imageUrl});
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('profile.imageUpdateError'), style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage() async {
    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseStorage.instance.ref().child('profile_images/${FirebaseAuth.instance.currentUser?.uid}.jpg').delete();
      
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).update({
        'profileImageUrl': '',
      });

      setState(() {
        profileImageUrl = '';
        isLoading = false;
      });
      
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('profile.imageUpdateSuccess'), style: GoogleFonts.cairo()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, {'profileImageUrl': ''});
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(languageProvider.translate('profile.imageUpdateError'), style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'name': _nameController.text,
                'phone': _phoneController.text,
              });

          if (mounted) {
            final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  languageProvider.translate('editProfile.updateSuccess'),
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.translate('editProfile.updateError'),
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.yellow : Color(0xff503636),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor:
            isDarkMode ? const Color(0xff0d0d0d) : const Color(0xffF1E4CF),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: isDarkMode ? Colors.yellow : const Color(0xff503636),
            ),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),
      body: Material(
        child: Container(
          height: double.infinity,
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: isDarkMode ? Colors.grey[700] : Colors.white,
                          backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null || profileImageUrl!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: isDarkMode ? Colors.white : Colors.grey[600],
                                )
                              : null,
                        ),
                      ),
                      if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                        SizedBox(height: 15,),
                      if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                                  onPressed: isLoading ? null : _uploadImage,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: isLoading ? null : _deleteImage,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Text(
                        languageProvider.translate('editProfile.title'),
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Color(0xff503636),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Container(
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
                        child: Column(
                          children: [
                            TextFormField(
                              style: GoogleFonts.inter(color: Colors.black),
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: languageProvider.translate('editProfile.name'),
                                labelStyle: GoogleFonts.cairo(
                                  color: Colors.black,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider.translate('editProfile.nameHint');
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              style: GoogleFonts.inter(color: Colors.black),
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: languageProvider.translate('editProfile.phone'),
                                labelStyle: GoogleFonts.cairo(
                                  color: Colors.black,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return languageProvider.translate('editProfile.phoneHint');
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: isLoading ? null : _updateUserData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode
                                  ? Colors.white
                                  : const Color(0xff503636),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : Text(
                                  languageProvider.translate('editProfile.saveChanges'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    color:
                                        isDarkMode
                                            ? Colors.black
                                            : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 20),
                      // Delete Account Button
                      TextButton.icon(
                        onPressed: isLoading ? null : () => _showDeleteAccountDialog(),
                        icon: Icon(Icons.delete_forever, color: Colors.red),
                        label: Text(
                          languageProvider.translate('editProfile.deleteAccount'),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(color: Colors.red.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final emailController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            languageProvider.translate('editProfile.deleteAccountConfirmation'),
            style: GoogleFonts.cairo(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                languageProvider.translate('editProfile.deleteAccountMessage'),
                style: GoogleFonts.cairo(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: languageProvider.translate('editProfile.confirmEmail'),
                  labelStyle: GoogleFonts.cairo(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                languageProvider.translate('profile.cancel'),
                style: GoogleFonts.cairo(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (emailController.text == currentUser?.email) {
                  try {
                    // تسجيل الخروج أولاً
                    await FirebaseAuth.instance.signOut();

                    // حذف البيانات من Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser?.uid)
                        .delete();

                    // حذف الصورة من Storage إذا وجدت
                    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
                      try {
                        await FirebaseStorage.instance
                            .ref()
                            .child('profile_images/${currentUser?.uid}.jpg')
                            .delete();
                      } catch (e) {
                        // تجاهل أي خطأ في حذف الصورة
                      }
                    }

                    // حذف الحساب من Firebase Auth
                    await currentUser?.delete();

                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // في حالة حدوث خطأ، نقوم بالتنقل إلى صفحة تسجيل الدخول على أي حال
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        languageProvider.translate('editProfile.deleteError'),
                        style: GoogleFonts.cairo(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                languageProvider.translate('editProfile.confirmDelete'),
                style: GoogleFonts.cairo(
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
