import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:mahalattst2/UI/seller_pages/tager_maps.dart';
import 'package:provider/provider.dart';
import '../../auth/Data/models/stores_model.dart';
import '../../auth/Data/repos/store_repos/store_repo_impl.dart';
import '../../auth/Domain/entites/StoresEntity.dart';
import '../../logic/products_cubits/products_cubit.dart';
import '../../logic/stores_cubits/store_cubit.dart';
import '../../logic/stores_cubits/store_state.dart';
import '../../services/google_maps/google_maps_places_service.dart';
import 'products_seller_home.dart';
import 'Seller_Orders.dart';
import 'about_app_seller.dart';
import 'seller_profile.dart';
import '../../providers/language_provider.dart';

class SellerHomePage extends StatefulWidget {
  final String sellerId;

  const SellerHomePage({super.key, required this.sellerId});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  late StoreCubit _storeCubit;
  int _currentIndex = 0;
  bool _isLoading = false;
  List<String> _userStoreTypes = [];
  bool _isLoadingStoreTypes = true;
  late GoogleMapsPlacesService _placesService;
  int _selectedIndex = 0;
  DateTime? _lastBackPressTime;
  bool _hasNewOrders = false;

  @override
  void initState() {
    super.initState();
    _storeCubit = StoreCubit(StoreRepositoryImpl(FirebaseFirestore.instance));
    _loadUserStoreTypes();
    _placesService = GoogleMapsPlacesService();
    _checkForNewOrders();
    _listenToNewOrders();
  }

  Future<void> _loadUserStoreTypes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final accountTypes = List<String>.from(
            userDoc.data()?['accountType'] ?? [],
          );
          setState(() {
            _userStoreTypes = accountTypes;
            _isLoadingStoreTypes = false;
          });
          if (_userStoreTypes.isNotEmpty) {
            _refreshCurrentTab();
          }
        }
      }
    } catch (e) {
      print('Error loading user store types: $e');
      setState(() => _isLoadingStoreTypes = false);
    }
  }

  Future<void> _refreshCurrentTab() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (_userStoreTypes.isNotEmpty) {
        final category = _userStoreTypes[_currentIndex];
        await _storeCubit.loadStoreBySellerAndCategory(
          widget.sellerId,
          category,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkForNewOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final ordersRef = FirebaseFirestore.instance.collection('Orders');
        final query = ordersRef
            .where('sellerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending');

        final snapshot = await query.get();
        print(
          'Checking for new orders - Found ${snapshot.docs.length} pending orders',
        );

        if (mounted) {
          setState(() {
            _hasNewOrders = snapshot.docs.isNotEmpty;
          });
          print('Updated _hasNewOrders to: $_hasNewOrders');
        }
      } catch (e) {
        print('Error checking for new orders: $e');
      }
    }
  }

  void _listenToNewOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print('Setting up orders listener for user: ${user.uid}');
        FirebaseFirestore.instance
            .collection('Orders')
            .where('sellerId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pending')
            .snapshots()
            .listen(
              (snapshot) {
                print(
                  'Orders listener update - Found ${snapshot.docs.length} pending orders',
                );
                if (mounted) {
                  setState(() {
                    _hasNewOrders = snapshot.docs.isNotEmpty;
                  });
                  print('Updated _hasNewOrders to: $_hasNewOrders');
                }
              },
              onError: (error) {
                print('Error in orders listener: $error');
              },
            );
      } catch (e) {
        print('Error setting up orders listener: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    if (_isLoadingStoreTypes) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userStoreTypes.isEmpty) {
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
                backgroundColor: Color(0xff503636),

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
        appBar: AppBar(
          backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
          title: Text(
              languageProvider.translate('productsSeller.mystore'),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: width * 0.05,
            ),
          ),
        ),
        body: Center(
          child: Text(
              languageProvider.translate('productsSeller.noStoreTypes'),
              style: GoogleFonts.cairo(
                fontSize: width * 0.04,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );
    }

    final List<Widget> _pages = [
      // Main content
      DefaultTabController(
      length: _userStoreTypes.length,
      child: Scaffold(
          backgroundColor: const Color(0xffF1E4CF),
        appBar: AppBar(
            backgroundColor: const Color(0xffF1E4CF),
            automaticallyImplyLeading: false,
            elevation: 0,
          title: Text(
              languageProvider.translate('productsSeller.title'),
            style: GoogleFonts.cairo(
                fontSize: MediaQuery.of(context).size.width * 0.05,
              fontWeight: FontWeight.bold,
                color: const Color(0xff503636),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.language,
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text(
                            languageProvider.translate(
                              'productsSeller.language.switch',
                            ),
                            style: GoogleFonts.cairo(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text(
                                  languageProvider.translate(
                                    'productsSeller.language.arabic',
                                  ),
                                  style: GoogleFonts.cairo(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.04,
                                  ),
                                ),
                                onTap: () {
                                  languageProvider.changeLanguage('ar');
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: Text(
                                  languageProvider.translate(
                                    'productsSeller.language.english',
                                  ),
                                  style: GoogleFonts.cairo(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.04,
                                  ),
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
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: const Color(0xff503636),
                  size: MediaQuery.of(context).size.width * 0.06,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutAppSeller(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: const Color(0xff503636),
                      size: MediaQuery.of(context).size.width * 0.06,
                    ),
                    if (_hasNewOrders)
                      Positioned(
                        right: -5,
                        top: -5,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SellerOrders(),
                    ),
                  ).then((_) {
                    setState(() {
                      _hasNewOrders = false;
                    });
                  });
                },
              ),
            ],
          bottom: TabBar(
            isScrollable: true,
            labelStyle: GoogleFonts.cairo(
                fontSize: MediaQuery.of(context).size.width * 0.04,
              fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              unselectedLabelStyle: GoogleFonts.cairo(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                color: const Color(0xff503636),
              ),
              labelPadding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.04,
              ),
              indicatorColor: const Color(0xff503636),
              labelColor: Colors.black,
              unselectedLabelColor: const Color(0xff503636),
            tabs:
                  _userStoreTypes.map((category) {
                    final languageProvider = Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    );
                    return Tab(
                      text: languageProvider.translate(
                        'productsSeller.categories.$category',
                      ),
                    );
                  }).toList(),
            onTap: (index) {
              if (_currentIndex != index) {
                setState(() {
                  _currentIndex = index;
                });
                _refreshCurrentTab();
              }
            },
          ),
        ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xffF1E4CF), Color(0xfffaf1e6), Colors.white],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Provider<StoreCubit>.value(
          value: _storeCubit,
          child: TabBarView(
                physics:
                    _isLoading ? const NeverScrollableScrollPhysics() : null,
            children:
                _userStoreTypes.map((category) {
                  return _CategoryStoresTab(
                    sellerId: widget.sellerId,
                    category: category,
                    onStoreModified: _refreshCurrentTab,
                  );
                }).toList(),
          ),
            ),
          ),
        ),
      ),
      // Profile page
      const SellerProfile(),
    ];

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
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: const Color(0xffF1E4CF),
          selectedItemColor: const Color(0xff503636),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.cairo(
            fontSize: MediaQuery.of(context).size.width * 0.035,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontSize: MediaQuery.of(context).size.width * 0.035,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.store_outlined,
                size: MediaQuery.of(context).size.width * 0.06,
              ),
              label: languageProvider.translate(
                'productsSeller.navigation.store',
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_outline,
                size: MediaQuery.of(context).size.width * 0.06,
              ),
              label: languageProvider.translate(
                'productsSeller.navigation.profile',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStoresTab extends StatelessWidget {
  final String sellerId;
  final String category;
  final Future<void> Function() onStoreModified;

  const _CategoryStoresTab({
    required this.sellerId,
    required this.category,
    required this.onStoreModified,
  });

  void _showAddStoreDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    XFile? _selectedImage;
    final ImagePicker _picker = ImagePicker();
    bool _isProcessing = false;
    LatLng? _selectedLocation;
    final _placesService = GoogleMapsPlacesService();
    StoreStatus _selectedStatus = StoreStatus.open;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async => !_isProcessing,
                child: Dialog(
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            languageProvider.translate(
                              "productsSeller.addstore",
                            ),
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.05,
                              color: Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          if (_isProcessing)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: height * 0.01,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: width * 0.06,
                                    height: width * 0.06,
                                    child: CircularProgressIndicator(
                                      strokeWidth: width * 0.005,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Text(
                                    languageProvider.translate(
                                      'productsSeller.creatingStore',
                                    ),
                                    style: GoogleFonts.cairo(
                                      fontSize: width * 0.035,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: height * 0.2,
                                  width: double.infinity,
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          width * 0.02,
                                        ),
                                        child:
                                            _selectedImage != null
                                                ? Image.file(
                                                  File(_selectedImage!.path),
                                                  height: height * 0.2,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                                : Container(
                                                  color: Colors.grey[200],
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.store,
                                                      size: width * 0.1,
                                                    ),
                                                  ),
                                                ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.2,
                                                ),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.add_photo_alternate,
                                              color: Colors.blue,
                                              size: width * 0.06,
                                            ),
                                            onPressed:
                                                _isProcessing
                                                    ? null
                                                    : () async {
                                                      final image = await _picker
                                                          .pickImage(
                                                            source:
                                                                ImageSource
                                                                    .gallery,
                                                            imageQuality: 70,
                                                          );
                                                      if (image != null) {
                                                        setState(() {
                                                          _selectedImage =
                                                              image;
                                                        });
                                                      }
                                                    },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: height * 0.02),
                                TextFormField(
                                  controller: nameController,
                                  enabled: !_isProcessing,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.translate(
                                      'productsSeller.storeName',
                                    ),
                                    labelStyle: GoogleFonts.cairo(
                                      fontSize: width * 0.04,
                                      letterSpacing: 1.1,
                                    ),
                                    border: const OutlineInputBorder(),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value == null
                                              ? languageProvider.translate(
                                                'productsSeller.errors.required',
                                              )
                                              : null,
                                ),
                                SizedBox(height: height * 0.02),
                                TextFormField(
                                  controller: descController,
                                  enabled: !_isProcessing,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.translate(
                                      'productsSeller.description',
                                    ),
                                    labelStyle: GoogleFonts.cairo(
                                      fontSize: width * 0.04,
                                      letterSpacing: 1.1,
                                    ),
                                    border: const OutlineInputBorder(),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  maxLines: 3,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Text(
                            languageProvider.translate('storeStatus.title'),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Wrap(
                            spacing: width * 0.03,
                            runSpacing: height * 0.02,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildStatusButton(
                                context,
                                StoreStatus.open,
                                _selectedStatus,
                                (status) =>
                                    setState(() => _selectedStatus = status),
                              ),
                              _buildStatusButton(
                                context,
                                StoreStatus.busy,
                                _selectedStatus,
                                (status) =>
                                    setState(() => _selectedStatus = status),
                              ),
                              _buildStatusButton(
                                context,
                                StoreStatus.closed,
                                _selectedStatus,
                                (status) =>
                                    setState(() => _selectedStatus = status),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.02),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TagerMaps(),
                                ),
                              );
                              if (result != null &&
                                  result['storeLocation'] != null) {
                                final latLng =
                                    result['storeLocation'] as LatLng;
                                setState(() {
                                  _selectedLocation = latLng;
                                });

                                try {
                                  final address = await _placesService
                                      .getAddressFromLatLng(latLng);
                                  setState(() {
                                    locationController.text = address;
                                  });
                                } catch (e) {
                                  print('Error getting address: $e');
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.04,
                                vertical: height * 0.015,
                              ),
                            ),
                            label: Text(
                              languageProvider.translate(
                                'productsSeller.selectLocation',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            icon: Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: width * 0.06,
                            ),
                          ),
                          if (_selectedLocation == null)
                            Padding(
                              padding: EdgeInsets.only(top: height * 0.01),
                              child: Text(
                                languageProvider.translate(
                                  'productsSeller.errors.locationRequired',
                                ),
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.035,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          SizedBox(height: height * 0.02),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed:
                                    _isProcessing
                                        ? null
                                        : () => Navigator.pop(dialogContext),
                                child: Text(
                                  languageProvider.translate(
                                    'productsSeller.cancel',
                                  ),
                                  style: GoogleFonts.cairo(
                                    fontSize: width * 0.04,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: width * 0.02),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  disabledBackgroundColor: Colors.grey,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.03,
                                    vertical: height * 0.01,
                                  ),
                                ),
                                onPressed:
                                    _isProcessing
                                        ? null
                                        : () async {
                                          if (formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                            if (_selectedLocation == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    languageProvider.translate(
                                                      'productsSeller.errors.locationRequired',
                                                    ),
                                                    style: GoogleFonts.cairo(
                                                      fontSize: width * 0.035,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                              return;
                                            }
                                            setState(
                                              () => _isProcessing = true,
                                            );
                                            try {
                                              String imageUrl = '';
                                              if (_selectedImage != null) {
                                                final storageRef = FirebaseStorage
                                                    .instance
                                                    .ref()
                                                    .child(
                                                      'stores/$sellerId/${DateTime.now().millisecondsSinceEpoch}.jpg',
                                                    );
                                                await storageRef.putFile(
                                                  File(_selectedImage!.path),
                                                );
                                                imageUrl =
                                                    await storageRef
                                                        .getDownloadURL();
                                              }

                                              final userDoc =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(sellerId)
                                                      .get();

                                              if (!userDoc.exists) {
                                                throw Exception(
                                                  'User document not found',
                                                );
                                              }

                                              final accountTypes = List<
                                                String
                                              >.from(
                                                userDoc.data()?['accountType'] ??
                                                    [],
                                              );

                                              if (accountTypes.isEmpty) {
                                                throw Exception(
                                                  'No account types found for user',
                                                );
                                              }

                                              final store = StoreModel(
                                                sellerId: sellerId,
                                                storeId: '',
                                                storeTypes: accountTypes,
                                                name: nameController.text,
                                                location:
                                                    locationController.text,
                                                image: imageUrl,
                                                description:
                                                    descController.text,
                                                categories: accountTypes,
                                                storeLocation:
                                                    _selectedLocation ??
                                                    const LatLng(
                                                      32.0833,
                                                      36.1000,
                                                    ),
                                                status: _selectedStatus,
                                              );

                                              final storeCubit =
                                                  context.read<StoreCubit>();
                                              await storeCubit.createStore(
                                                store,
                                              );
                                              if (context.mounted) {
                                                Navigator.pop(dialogContext);
                                                await onStoreModified();
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                setState(
                                                  () => _isProcessing = false,
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      languageProvider.translate(
                                                        'productsSeller.errors.createStore',
                                                      ),
                                                      style: GoogleFonts.cairo(
                                                        fontSize: width * 0.035,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                child: Text(
                                  languageProvider.translate(
                                    'productsSeller.createStore',
                                  ),
                                  style: GoogleFonts.cairo(
                                    fontSize: width * 0.04,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
            },
          ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    StoreStatus status,
    StoreStatus selectedStatus,
    Function(StoreStatus) onStatusSelected,
  ) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    Color getStatusColor(StoreStatus status) {
      switch (status) {
        case StoreStatus.open:
          return const Color(0xFF4CAF50); // Modern green
        case StoreStatus.closed:
          return const Color(0xFFE53935); // Modern red
        case StoreStatus.busy:
          return const Color(0xFFFFA000); // Modern orange
      }
    }

    String getStatusText(StoreStatus status) {
      switch (status) {
        case StoreStatus.open:
          return languageProvider.translate('storeStatus.open');
        case StoreStatus.closed:
          return languageProvider.translate('storeStatus.closed');
        case StoreStatus.busy:
          return languageProvider.translate('storeStatus.busy');
      }
    }

    final isSelected = status == selectedStatus;
    final color = getStatusColor(status);

    return GestureDetector(
      onTap: () => onStatusSelected(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width * 0.28,
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: height * 0.015,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? color.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: width * 0.02),
            Expanded(
              child: Text(
                getStatusText(status),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.035,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: width * 0.05,
              ),
          ],
        ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        if (state is StoreLoading) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: width * 0.005,
            ),
          );
        } else if (state is StoreLoaded) {
          return _StoreView(
            store: state.store,
            onStoreModified: onStoreModified,
            sellerId: sellerId,
            currentCategory: category,
          );
        } else if (state is StoreNotFound) {
          return _EmptyState(
            category: category,
            onCreateStore: () => _showAddStoreDialog(context),
          );
        } else if (state is StoreError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: width * 0.12,
                  color: Colors.red,
                ),
                SizedBox(height: height * 0.02),
                Text(
                  state.message,
                  style: GoogleFonts.cairo(
                    fontSize: width * 0.04,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: height * 0.02),
                ElevatedButton(
                  onPressed: () {
                    context.read<StoreCubit>().loadStoreBySellerAndCategory(
                      sellerId,
                      category,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.05,
                      vertical: height * 0.015,
                    ),
                  ),
                  child: Text(
                    LanguageProvider().translate('productsSeller.retry'),
                    style: GoogleFonts.cairo(fontSize: width * 0.04),
                  ),
                ),
              ],
            ),
          );
        }
        return _EmptyState(
          category: category,
          onCreateStore: () => _showAddStoreDialog(context),
        );
      },
    );
  }
}

class _StoreView extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onStoreModified;
  final String sellerId;
  final String currentCategory;

  const _StoreView({
    required this.store,
    required this.onStoreModified,
    required this.sellerId,
    required this.currentCategory,
  });

  Color _getStatusColor(StoreStatus status) {
    switch (status) {
      case StoreStatus.open:
        return Colors.green;
      case StoreStatus.closed:
        return Colors.red;
      case StoreStatus.busy:
        return Colors.orange;
    }
  }

  String _getStatusText(StoreStatus status, BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    switch (status) {
      case StoreStatus.open:
        return languageProvider.translate('storeStatus.open');
      case StoreStatus.closed:
        return languageProvider.translate('storeStatus.closed');
      case StoreStatus.busy:
        return languageProvider.translate('storeStatus.busy');
    }
  }

  Widget _buildStatusButton(
    BuildContext context,
    StoreStatus status,
    StoreStatus selectedStatus,
    Function(StoreStatus) onStatusSelected,
  ) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    return GestureDetector(
      onTap: () => onStatusSelected(status),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: height * 0.01,
        ),
        decoration: BoxDecoration(
          color:
              status == selectedStatus
                  ? _getStatusColor(status).withOpacity(0.2)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(width * 0.02),
          border: Border.all(
            color:
                status == selectedStatus
                    ? _getStatusColor(status)
                    : Colors.grey[400]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: width * 0.02,
              height: width * 0.02,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: width * 0.02),
            Text(
              _getStatusText(status, context),
              style: GoogleFonts.cairo(
                fontSize: width * 0.035,
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(width * 0.02),
              child:
                  store.image.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: store.image,
                        height: height * 0.3,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: width * 0.005,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(Icons.error, size: width * 0.1),
                              ),
                            ),
                      )
                      : Container(
                        height: height * 0.3,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(Icons.store, size: width * 0.1),
                        ),
                      ),
            ),
            SizedBox(height: height * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
              store.name,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.06,
                color: Colors.black,
                letterSpacing: 1.5,
              ),
            ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.03,
                    vertical: height * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(store.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(width * 0.02),
                    border: Border.all(
                      color: _getStatusColor(store.status),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: width * 0.02,
                        height: width * 0.02,
                        decoration: BoxDecoration(
                          color: _getStatusColor(store.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      Text(
                        _getStatusText(store.status, context),
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.035,
                          color: _getStatusColor(store.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.02),
            Row(
              children: [
                Icon(Icons.location_on, size: width * 0.05, color: Colors.grey),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Text(
                    store.location,
                    style: GoogleFonts.cairo(
                      fontSize: width * 0.04,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.02),
            Text(
              languageProvider.translate('productsSeller.description'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.05,
                color: Colors.black,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              store.description,
              style: GoogleFonts.cairo(
                fontSize: width * 0.04,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: height * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProductsSellerHome(
                              sellerId: sellerId,
                              availableCollections: [currentCategory],
                              initialCollection: currentCategory,
                            ),
                      ),
                    );
                  },
                  icon: Icon(Icons.shopping_bag, size: width * 0.06),
                  label: Text(
                    languageProvider.translate('productsSeller.manageProducts'),
                    style: GoogleFonts.cairo(fontSize: width * 0.04),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.05,
                      vertical: height * 0.015,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEditStoreDialog(context, store),
                  icon: Icon(Icons.edit, size: width * 0.06),
                  label: Text(
                    languageProvider.translate('productsSeller.editStore'),
                    style: GoogleFonts.cairo(fontSize: width * 0.04),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.05,
                      vertical: height * 0.015,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStoreDialog(BuildContext context, StoreModel store) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final nameController = TextEditingController(text: store.name);
    final locationController = TextEditingController(text: store.location);
    final descController = TextEditingController(text: store.description);
    final formKey = GlobalKey<FormState>();
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final _placesService = GoogleMapsPlacesService();

    XFile? _selectedImage;
    final ImagePicker _picker = ImagePicker();
    bool _isProcessing = false;
    LatLng? _selectedLocation = store.storeLocation;
    StoreStatus _selectedStatus = store.status;

    void showDeleteDialog() {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              languageProvider.translate('productsSeller.deleteProduct'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.05,
                color: Colors.black,
              ),
            ),
            content: Text(
              languageProvider.translate('productsSeller.confirmations.delete'),
              style: GoogleFonts.cairo(
                fontSize: width * 0.04,
                color: Colors.grey[800],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  languageProvider.translate('productsSeller.cancel'),
                  style: GoogleFonts.cairo(
                    fontSize: width * 0.04,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.015,
                  ),
                ),
                onPressed: () async {
                  try {
                    final storeCubit = context.read<StoreCubit>();
                    final productsCubit = context.read<ProductsCubit>();
                    await storeCubit.deleteStore(store.storeId);
                    for (var storeType in store.storeTypes) {
                      await productsCubit.deleteAllProductsForSeller(
                        store.sellerId,
                        storeType,
                      );
                    }
                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                      onStoreModified();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting store: $e',
                            style: GoogleFonts.cairo(fontSize: width * 0.035),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  languageProvider.translate('productsSeller.delete'),
                  style: GoogleFonts.cairo(
                    fontSize: width * 0.04,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider.translate('productsSeller.editStore'),
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.05,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: width * 0.06,
                    ),
                    onPressed:
                        _isProcessing
                            ? null
                            : () {
                              Navigator.pop(context);
                              showDeleteDialog();
                            },
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: languageProvider.translate(
                            'productsSeller.storeName',
                          ),
                          labelStyle: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            color: Colors.grey[850],
                          ),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                        enabled: !_isProcessing,
                      ),
                      SizedBox(height: height * 0.02),
                      TextFormField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: languageProvider.translate(
                            'productsSeller.description',
                          ),
                          labelStyle: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            color: Colors.grey[850],
                          ),
                        ),
                        maxLines: 3,
                        enabled: !_isProcessing,
                      ),
                      SizedBox(height: height * 0.02),
                      ElevatedButton(
                        onPressed:
                            _isProcessing
                                ? null
                                : () async {
                                  final image = await _picker.pickImage(
                                    source: ImageSource.gallery,
                                  );
                                  if (image != null) {
                                    setState(() => _selectedImage = image);
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04,
                            vertical: height * 0.015,
                          ),
                        ),
                        child: Text(
                          languageProvider.translate(
                            'productsSeller.changeImage',
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_selectedImage != null)
                        Text(
                          languageProvider.translate(
                            'productsSeller.imageSelected',
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.035,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      SizedBox(height: height * 0.03),
                      Text(
                        languageProvider.translate('storeStatus.title'),
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
                          ),
                        ),
                      SizedBox(height: height * 0.02),
                      Wrap(
                        spacing: width * 0.03,
                        runSpacing: height * 0.02,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildStatusButton(
                            context,
                            StoreStatus.open,
                            _selectedStatus,
                            (status) =>
                                setState(() => _selectedStatus = status),
                          ),
                          _buildStatusButton(
                            context,
                            StoreStatus.busy,
                            _selectedStatus,
                            (status) =>
                                setState(() => _selectedStatus = status),
                          ),
                          _buildStatusButton(
                            context,
                            StoreStatus.closed,
                            _selectedStatus,
                            (status) =>
                                setState(() => _selectedStatus = status),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.03),
                      InkWell(
                        onTap:
                            _isProcessing
                                ? null
                                : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => TagerMaps(
                                            initialLocation: _selectedLocation,
                                          ),
                                    ),
                                  );
                                  if (result != null &&
                                      result['storeLocation'] != null) {
                                    final latLng =
                                        result['storeLocation'] as LatLng;
                                    setState(() {
                                      _selectedLocation = latLng;
                                    });

                                    try {
                                      setState(() => _isProcessing = true);
                                      final address = await _placesService
                                          .getAddressFromLatLng(latLng);
                                      setState(() {
                                        locationController.text = address;
                                      });

                                      final updatedStore = store.copyWith(
                                        storeLocation: _selectedLocation,
                                        location: locationController.text,
                                      );
                                      final storeCubit =
                                          context.read<StoreCubit>();
                                      await storeCubit.updateStore(
                                        updatedStore,
                                      );
                                      if (context.mounted) {
                                        onStoreModified();
                                        setState(() => _isProcessing = false);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        setState(() => _isProcessing = false);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              languageProvider.translate(
                                                'productsSeller.errors.updateLocation',
                                              ),
                                              style: GoogleFonts.cairo(
                                                fontSize: width * 0.035,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: width * 0.06),
                            Text(
                              languageProvider.translate(
                                'productsSeller.changeLocation',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedLocation == null)
                        Padding(
                          padding: EdgeInsets.only(top: height * 0.01),
                          child: Text(
                            languageProvider.translate(
                              'productsSeller.errors.locationRequired',
                            ),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.035,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03,
                      vertical: height * 0.01,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.1),
                    ),
                  ),
                  onPressed:
                      _isProcessing ? null : () => Navigator.pop(context),
                  child: Text(
                    languageProvider.translate('productsSeller.cancel'),
                    style: GoogleFonts.cairo(
                      fontSize: width * 0.04,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      _isProcessing
                          ? null
                          : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              setState(() => _isProcessing = true);
                              try {
                                final storeCubit = context.read<StoreCubit>();
                                String? imageUrl = store.image;

                                if (_selectedImage != null) {
                                  final storage = FirebaseStorage.instance;
                                  final ref = storage.ref().child(
                                    'store_images/${store.storeId}',
                                  );
                                  await ref.putFile(File(_selectedImage!.path));
                                  imageUrl = await ref.getDownloadURL();
                                }

                                final updatedStore = store.copyWith(
                                  name: nameController.text,
                                  location: locationController.text,
                                  description: descController.text,
                                  image: imageUrl,
                                  storeLocation: _selectedLocation,
                                  status: _selectedStatus,
                                );

                                await storeCubit.updateStore(updatedStore);
                                Navigator.pop(context);
                                onStoreModified();
                              } catch (e) {
                                setState(() => _isProcessing = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      languageProvider.translate(
                                        'productsSeller.errors.updateStore',
                                      ),
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.04,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                  child:
                      _isProcessing
                          ? SizedBox(
                            width: width * 0.05,
                            height: height * 0.02,
                            child: CircularProgressIndicator(
                              strokeWidth: width * 0.005,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                          : Text(
                            languageProvider.translate('productsSeller.save'),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.032,
                      vertical: height * 0.011,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.1),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatefulWidget {
  final String category;
  final VoidCallback onCreateStore;

  const _EmptyState({required this.category, required this.onCreateStore});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/empty.json',
            width: width * 0.5,
            height: height * 0.3,
          ),
          SizedBox(height: height * 0.02),
          Text(
            languageProvider
                .translate('productsSeller.store.noStores')
                .replaceAll(
                  '{categories}',
                  languageProvider.translate(
                    'productsSeller.categories.${widget.category}',
                  ),
                ),
            style: GoogleFonts.cairo(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: height * 0.02),
          ElevatedButton.icon(
            onPressed: widget.onCreateStore,
            icon: Icon(Icons.add, size: width * 0.06),
            label: Text(
              languageProvider.translate('productsSeller.createStore'),
              style: GoogleFonts.cairo(
                fontSize: width * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.05,
                vertical: height * 0.015,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
