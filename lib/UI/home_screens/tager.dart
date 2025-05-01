import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../auth/Data/repos/user_repos/auth_repo_user.dart';
import '../../core/errors/failures.dart';
import '../../providers/language_provider.dart';
import '../../services/get_it_service.dart';
import '../maps/adress_managment_maps.dart';


class tager extends StatefulWidget {
  const tager({super.key});

  @override
  State<tager> createState() => _tagerState();
}

class _tagerState extends State<tager> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  Map<String, dynamic>? userLocation;
  String? locationAddress;
  bool isLoading = true;
  final _authRepo = getIt<AuthRepoUser>();

  List<String> selectedCategories = [];
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _initializeCategories();
  }

  void _initializeCategories() {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    categories = [
      languageProvider.translate('tager.categories.mensClothing'),
      languageProvider.translate('tager.categories.womensClothing'),
      languageProvider.translate('tager.categories.kidsClothing'),
      languageProvider.translate('tager.categories.mensShoes'),
      languageProvider.translate('tager.categories.womensShoes'),
      languageProvider.translate('tager.categories.kidsShoes'),
      languageProvider.translate('tager.categories.bags'),
      languageProvider.translate('tager.categories.healthCare'),
    ];
  }

  Future<void> _loadUserLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final result = await _authRepo.getUserLocation(uid: user.uid);
        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _mapFailureToMessage(failure),
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          (locationData) {
            setState(() {
              userLocation = locationData['userLocation'];
              locationAddress = locationData['location'];
              isLoading = false;
            });
          },
        );
      }
    } catch (e) {
      print("Error loading user location: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final result = await _authRepo.deleteUserLocation(uid: user.uid);
        result.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _mapFailureToMessage(failure),
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          (_) {
            setState(() {
              userLocation = null;
              locationAddress = null;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    Provider.of<LanguageProvider>(context, listen: false).translate('tager.deleteSuccess'),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LanguageProvider>(context, listen: false).translate('tager.deleteError'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    }
    return Provider.of<LanguageProvider>(context, listen: false).translate('tager.unexpectedError');
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: const Color(0xff503636).withOpacity(0.75)),
        title: Text(
          languageProvider.translate('tager.title'),
          style: GoogleFonts.cairo(
              color: const Color(0xff503636).withOpacity(0.75),
              fontWeight: FontWeight.bold,
              fontSize: width * 0.045,
              letterSpacing: 1.2
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xffF1E4CF),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xffF1E4CF),
              const Color(0xfffaf1e6),
              const Color(0xffF7F7F7),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.05),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            labelText: languageProvider.translate('tager.phone'),
                            prefixIcon: Icon(Icons.phone, color: const Color(0xff503636).withOpacity(0.75)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.04),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return languageProvider.translate('tager.phoneHint');
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: height * 0.035),
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: languageProvider.translate('tager.name'),
                            prefixIcon: Icon(Icons.person, color: const Color(0xff503636).withOpacity(0.75)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.04),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return languageProvider.translate('tager.nameHint');
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: height * 0.035),
                        if (isLoading)
                          Center(child: CircularProgressIndicator(color: const Color(0xff503636).withOpacity(0.75)))
                        else if (userLocation == null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff503636).withOpacity(0.75),
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.1,
                                vertical: height * 0.01,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(width * 0.1),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdressManagmentMaps(),
                                ),
                              ).then((_) => _loadUserLocation());
                            },
                            icon: Icon(
                              Icons.add_location_alt,
                              size: width * 0.04,
                              color: Colors.white,
                            ),
                            label: Text(
                              languageProvider.translate('tager.address'),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.all(width * 0.07),
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(width * 0.05),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff503636).withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: const Color(0xff503636).withOpacity(0.75),
                                      size: width * 0.08,
                                    ),
                                    SizedBox(width: width * 0.03),
                                    Expanded(
                                      child: Text(
                                        locationAddress ?? languageProvider.translate('addressManagement.noAddress'),
                                        style: GoogleFonts.cairo(
                                          fontSize: width * 0.045,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xff503636).withOpacity(0.75),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: height * 0.03),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xff503636).withOpacity(0.75),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(width * 0.1),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AdressManagmentMaps(),
                                          ),
                                        ).then((_) => _loadUserLocation());
                                      },
                                      icon: Icon(
                                        Icons.edit,
                                        size: width * 0.05,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        languageProvider.translate('tager.edit'),
                                        style: GoogleFonts.cairo(
                                          fontSize: width * 0.04,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(width * 0.1),
                                        ),
                                      ),
                                      onPressed: _deleteLocation,
                                      icon: Icon(
                                        Icons.delete,
                                        size: width * 0.05,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        languageProvider.translate('tager.delete'),
                                        style: GoogleFonts.cairo(
                                          fontSize: width * 0.04,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.06),
                Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.05),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate('tager.selectCategories'),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636).withOpacity(0.75),
                          ),
                        ),
                        SizedBox(height: height * 0.03),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categories.map((category) {
                            return FilterChip(
                              label: Text(
                                category,
                                style: GoogleFonts.cairo(
                                  color: selectedCategories.contains(category)
                                      ? Colors.white
                                      : const Color(0xff503636).withOpacity(0.75),
                                ),
                              ),
                              selected: selectedCategories.contains(category),
                              selectedColor: const Color(0xff503636).withOpacity(0.75),
                              checkmarkColor: Colors.white,
                              backgroundColor: const Color(0xffF1E4CF),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedCategories.add(category);
                                  } else {
                                    selectedCategories.remove(category);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.024),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() &&
                        selectedCategories.isNotEmpty &&
                        userLocation != null) {
                      try {
                        await FirebaseFirestore.instance.collection('requests').add({
                          'email': emailController.text,
                          'name': nameController.text,
                          'categories': selectedCategories,
                          'address': locationAddress,
                          'userLocation': userLocation,
                          'phone': phoneController.text,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              languageProvider.translate('tager.success'),
                            ),
                            backgroundColor: const Color(0xff503636).withOpacity(0.75),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(width * 0.1),
                            ),
                          ),
                        );
                        // Clear form
                        emailController.clear();
                        phoneController.clear();
                        nameController.clear();
                        setState(() {
                          selectedCategories.clear();
                          userLocation = null;
                          locationAddress = null;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(languageProvider.translate('tager.error') + ': $e'),
                            backgroundColor: Colors.red.shade800,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(width * 0.1),
                            ),
                          ),
                        );
                      }
                    } else if (selectedCategories.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            languageProvider.translate('tager.selectCategory'),
                          ),
                          backgroundColor: const Color(0xff503636).withOpacity(0.75),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(width * 0.1),
                          ),
                        ),
                      );
                    } else if (userLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            languageProvider.translate('tager.addAddress'),
                          ),
                          backgroundColor: const Color(0xff503636).withOpacity(0.75),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(width * 0.1),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff503636).withOpacity(0.75),
                    padding: EdgeInsets.symmetric(vertical: height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    languageProvider.translate('tager.send'),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    nameController.clear();
    super.dispose();
  }
}
