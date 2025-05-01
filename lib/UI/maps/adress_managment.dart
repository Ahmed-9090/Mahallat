import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../auth/Data/repos/user_repos/auth_repo_imp_user.dart';
import '../../core/errors/failures.dart';
import '../../providers/language_provider.dart';
import '../../services/firebase_auth_services/firebase_auth_service_user.dart';
import '../../services/firestore_service.dart';
import 'adress_managment_maps.dart';


class AdressManagment extends StatefulWidget {
  const AdressManagment({super.key});

  @override
  State<AdressManagment> createState() => _AdressManagmentState();
}

class _AdressManagmentState extends State<AdressManagment> {
  Map<String, dynamic>? userLocation;
  String? locationAddress;
  bool isLoading = true;
  final AuthRepoImplementationUser _authRepo = AuthRepoImplementationUser(
    dataService: FireStoreService(),
    firebaseAuthService: FirebaseAuthServiceUser(),
  );

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
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
                    Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    ).translate('addressManagement.deleteSuccess'),
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
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).translate('addressManagement.deleteError'),
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
    return Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).translate('addressManagement.unexpectedError');
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          languageProvider.translate('addressManagement.title'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.043,
            color: Colors.black,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : userLocation == null
              ? _buildEmptyState(width, height, languageProvider)
              : _buildLocationState(width, height, languageProvider),
    );
  }

  Widget _buildEmptyState(
    double width,
    double height,
    LanguageProvider languageProvider,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/empty.json', width: width * 0.5),
          Text(
            languageProvider.translate('addressManagement.noAddress'),
            style: GoogleFonts.cairo(
              fontSize: width * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: height * 0.03),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF9800),
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.1,
                vertical: height * 0.02,
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
              size: width * 0.06,
              color: Colors.black,
            ),
            label: Text(
              languageProvider.translate('addressManagement.addNewAddress'),
              style: GoogleFonts.cairo(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationState(
    double width,
    double height,
    LanguageProvider languageProvider,
  ) {
    return Padding(
      padding: EdgeInsets.all(width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(width * 0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
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
                      color: Color(0xFFFF9800),
                      size: width * 0.08,
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: Text(
                        locationAddress ??
                            languageProvider.translate(
                              'addressManagement.noAddress',
                            ),
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
                        color: Colors.black,
                      ),
                      label: Text(
                        languageProvider.translate('addressManagement.edit'),
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.04,
                          color: Colors.black,
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
                        color: Colors.white,
                        size: width * 0.05,
                      ),
                      label: Text(
                        languageProvider.translate('addressManagement.delete'),
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
    );
  }
}
