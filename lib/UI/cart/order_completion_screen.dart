import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../auth/Data/repos/user_repos/auth_repo_user.dart';
import '../../core/errors/failures.dart';
import '../../google maps/models/distance_calculator.dart';
import '../../services/get_it_service.dart';
import '../home_screens/home_content.dart';
import '../home_screens/home_page.dart';
import '../maps/adress_managment_maps.dart';

import '../home_screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class OrderCompletionScreen extends StatefulWidget {
  final double totalPrice;
  final String sellerId;

  const OrderCompletionScreen({
    super.key,
    required this.totalPrice,
    required this.sellerId,
  });

  @override
  State<OrderCompletionScreen> createState() => _OrderCompletionScreenState();
}

class _OrderCompletionScreenState extends State<OrderCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressInfoController = TextEditingController();
  final _sizeDetailsController = TextEditingController();
  bool _isLoading = false;
  String? _storeName;
  Map<String, dynamic>? userLocation;
  String? locationAddress;
  bool isLoadingLocation = true;
  double _deliveryFee = 0.0;
  double _serviceFee = 0.0;
  final _authRepo = getIt<AuthRepoUser>();
  LatLng? _storeLocation;

  @override
  void initState() {
    super.initState();
    _loadStoreDetails();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressInfoController.dispose();
    _sizeDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreDetails() async {
    try {
      final storeDoc = await FirebaseFirestore.instance
              .collection('stores')
              .where('sellerId', isEqualTo: widget.sellerId)
              .get();

      if (storeDoc.docs.isNotEmpty) {
        final storeData = storeDoc.docs.first.data();
        print('Store Data: $storeData');
        
        setState(() {
          _storeName = storeData['name'];
          if (storeData['storeLocation'] != null) {
            final geoPoint = storeData['storeLocation'] as GeoPoint;
            _storeLocation = LatLng(
              geoPoint.latitude,
              geoPoint.longitude,
            );
            print('Store Location set: $_storeLocation');
          } else {
            print('Store location is null in store data');
          }
        });
        _calculateDeliveryFee();
      } else {
        print('No store found for sellerId: ${widget.sellerId}');
      }
    } catch (e) {
      print('Error loading store details: $e');
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final result = await _authRepo.getUserLocation(uid: user.uid);
        result.fold(
          (failure) {
            print('Failed to get user location: ${failure.message}');
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
            print('User Location Data: $locationData');
            setState(() {
              userLocation = locationData['userLocation'];
              locationAddress = locationData['location'];
              isLoadingLocation = false;
            });
            _calculateDeliveryFee();
          },
        );
      } else {
        print('No user logged in');
      }
    } catch (e) {
      print("Error loading user location: $e");
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  void _calculateDeliveryFee() {
    if (_storeLocation != null && userLocation != null) {
      final userLatLng = LatLng(
        userLocation!['latitude'],
        userLocation!['longitude'],
      );

      print('Store Location: ${_storeLocation!.latitude}, ${_storeLocation!.longitude}');
      print('User Location: ${userLatLng.latitude}, ${userLatLng.longitude}');

      final distance = DistanceCalculator.calculateDistance(
        _storeLocation!,
        userLatLng,
      );
      print('Calculated Distance: $distance km');

      final deliveryFee = DistanceCalculator.calculateDeliveryFee(distance);
      print('Delivery Fee: $deliveryFee JOD');

      // Calculate service fee as 3% of (total price + delivery fee)
      final serviceFee = (widget.totalPrice + deliveryFee) * 0.03;
      print('Service Fee: $serviceFee JOD');
      print('Total Price: ${widget.totalPrice} JOD');

      setState(() {
        _deliveryFee = deliveryFee;
        _serviceFee = double.parse(serviceFee.toStringAsFixed(2));
      });
    } else {
      print('Location data missing:');
      print('Store Location: $_storeLocation');
      print('User Location: $userLocation');
    }
  }

  String _mapFailureToMessage(Failure failure) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    if (failure is ServerFailure) {
      return failure.message;
    }
    return languageProvider.translate('orderCompletion.unexpectedError');
  }

  Future<void> _submitOrder() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    if (!_formKey.currentState!.validate()) return;

    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.translate('orderCompletion.pleaseAddAddress'),
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('orderCompletion.pleaseLogin'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get store address
      String? storeAddress;
      try {
        final storeDoc = await FirebaseFirestore.instance
            .collection('stores')
            .where('sellerId', isEqualTo: widget.sellerId)
                .get();

        if (storeDoc.docs.isNotEmpty) {
          final storeData = storeDoc.docs.first.data();
          if (storeData['address'] != null) {
            storeAddress = storeData['address'];
          }
        }
      } catch (e) {
        print('Error fetching store address: $e');
      }

      // Get cart items first
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');
      final cartItems = await cartRef.get();

      // Create order document
      final orderRef = FirebaseFirestore.instance.collection('Orders').doc();
      await orderRef.set({
        'orderId': orderRef.id,
            'userId': user.uid,
            'sellerId': widget.sellerId,
            'storeName': _storeName,
            'storeAddress': storeAddress,
        'storeLocation': _storeLocation != null
                    ? {
                      'latitude': _storeLocation!.latitude,
                      'longitude': _storeLocation!.longitude,
                    }
                    : null,
            'customerInfo': {
              'phoneNumber': _phoneController.text,
              'address': locationAddress,
              'addressInfo': _addressInfoController.text,
              'location': userLocation,
              'sizeDetails': _sizeDetailsController.text,
            },
            'orderDetails': {
              'productsTotal': widget.totalPrice,
              'deliveryFee': _deliveryFee,
              'serviceFee': _serviceFee,
              'finalTotal': widget.totalPrice + _deliveryFee + _serviceFee,
            },
            'paymentMethod': 'cash_on_delivery',
            'status': 'pending',
            'orderDate': FieldValue.serverTimestamp(),
        'items': cartItems.docs
                    .map(
                      (doc) => {
                        'productId': doc['productId'],
                        'name': doc['name'],
                        'price': doc['price'],
                        'quantity': doc['quantity'],
                        'image': doc['image'],
                        'totalPrice': doc['price'] * doc['quantity'],
                      },
                    )
                    .toList(),
          });

      // Clear cart after successful order
      final batch = FirebaseFirestore.instance.batch();
      for (var item in cartItems.docs) {
        batch.delete(item.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('orderCompletion.orderSubmitted'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Navigate to the main home screen with bottom navigation
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('orderCompletion.orderError'),
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWithFees = widget.totalPrice + _deliveryFee + _serviceFee;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffF1E4CF).withOpacity(0.8),
        elevation: 0,
        title: Text(
          languageProvider.translate('orderCompletion.title'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.043,
            color: const Color(0xff503636).withOpacity(0.75),
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.02,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_storeName != null)
                  Card(
                    color: Colors.white.withOpacity(0.9),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.03),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.translate('orderCompletion.store'),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff503636).withOpacity(0.75),
                            ),
                          ),
                          SizedBox(height: height * 0.01),
                          Text(
                            _storeName!,
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.04,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: height * 0.02),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate(
                      'orderCompletion.phone',
                    ),
                    labelStyle: GoogleFonts.cairo(
                      fontSize: width * 0.035,
                      color: const Color(0xff503636).withOpacity(0.75),
                    ),
                    hintText: languageProvider.translate(
                      'orderCompletion.phoneHint',
                    ),
                    hintStyle: GoogleFonts.cairo(
                      fontSize: width * 0.035,
                      color: Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                      borderSide: BorderSide(
                        color: const Color(0xff503636).withOpacity(0.75),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                      borderSide: BorderSide(
                        color: const Color(0xff503636).withOpacity(0.75),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                      borderSide: BorderSide(
                        color: const Color(0xff503636).withOpacity(0.75),
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: const Color(0xff503636).withOpacity(0.75),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: width * 0.04,
                      vertical: height * 0.02,
                    ),
                  ),
                  style: GoogleFonts.cairo(
                    fontSize: width * 0.035,
                    color: const Color(0xff503636),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return languageProvider.translate(
                        'orderCompletion.phoneHint',
                      );
                    }
                    if (value.length < 10) {
                      return languageProvider.translate(
                        'orderCompletion.phoneInvalid',
                      );
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.03),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate(
                            'orderCompletion.addressInfo',
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636).withOpacity(0.75),
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        TextFormField(
                          controller: _addressInfoController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: languageProvider.translate(
                              'orderCompletion.addressInfoHint',
                            ),
                            hintStyle: GoogleFonts.cairo(
                              fontSize: width * 0.035,
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.02),
                              borderSide: BorderSide(
                                color: Color(0xff503636).withOpacity(0.75),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.02),
                              borderSide: BorderSide(
                                color: Color(0xff503636).withOpacity(0.75),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.02),
                              borderSide: BorderSide(
                                color: Color(0xff503636).withOpacity(0.75),
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.info_outline,
                              color: Color(0xff503636).withOpacity(0.75),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.02),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.03),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate(
                            'orderCompletion.sizeDetails',
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636).withOpacity(0.75),
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        TextFormField(
                          controller: _sizeDetailsController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: languageProvider.translate(
                              'orderCompletion.sizeDetailsHint',
                            ),
                            hintStyle: GoogleFonts.cairo(
                              fontSize: width * 0.035,
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.02),
                              borderSide: BorderSide(
                                color: Color(0xff503636).withOpacity(0.75),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.02),
                              borderSide: BorderSide(
                                color: Color(0xff503636).withOpacity(0.75),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(width * 0.02),
                              borderSide: BorderSide(
                                color: Color(0xff503636).withOpacity(0.75),
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.straighten,
                              color: Color(0xff503636).withOpacity(0.75),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return languageProvider.translate(
                                'orderCompletion.sizeDetailsHint',
                              );
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.02),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.03),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate('orderCompletion.address'),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636).withOpacity(0.75),
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        if (isLoadingLocation)
                          const Center(child: CircularProgressIndicator())
                        else if (userLocation == null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xff503636,
                              ).withOpacity(0.75),
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.1,
                                vertical: height * 0.02,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  width * 0.1,
                                ),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AdressManagmentMaps(),
                                ),
                              ).then((_) => _loadUserLocation());
                            },
                            icon: Icon(
                              Icons.add_location_alt,
                              size: width * 0.06,
                              color: Colors.white,
                            ),
                            label: Text(
                              languageProvider.translate(
                                'orderCompletion.addAddress',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: const Color(
                                      0xff503636,
                                    ).withOpacity(0.75),
                                    size: width * 0.08,
                                  ),
                                  SizedBox(width: width * 0.03),
                                  Expanded(
                                    child: Text(
                                      locationAddress ??
                                          languageProvider.translate(
                                            'orderCompletion.noAddress',
                                          ),
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(
                                          0xff503636,
                                        ).withOpacity(0.75),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.02),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xff503636,
                                  ).withOpacity(0.75),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.1,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const AdressManagmentMaps(),
                                    ),
                                  ).then((_) => _loadUserLocation());
                                },
                                icon: Icon(
                                  Icons.edit,
                                  size: width * 0.05,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  languageProvider.translate(
                                    'orderCompletion.changeAddress',
                                  ),
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
                ),
                SizedBox(height: height * 0.03),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.03),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate(
                                'orderCompletion.productsPrice',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                            Text(
                              '${widget.totalPrice.toStringAsFixed(2)} ${languageProvider.translate('cart.price')}',
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.01),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate(
                                'orderCompletion.deliveryFee',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                            Text(
                              '${_deliveryFee.toStringAsFixed(2)} ${languageProvider.translate('cart.price')}',
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.01),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate(
                                'orderCompletion.serviceFee',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                            Text(
                              '${_serviceFee.toStringAsFixed(2)} ${languageProvider.translate('cart.price')}',
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                        Divider(height: height * 0.03),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate(
                                'orderCompletion.total',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                            Text(
                              '${totalWithFees.toStringAsFixed(2)} ${languageProvider.translate('cart.price')}',
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.bold,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.03),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(width * 0.03),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate(
                            'orderCompletion.paymentMethod',
                          ),
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636).withOpacity(0.75),
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              color: Color(0xff503636).withOpacity(0.75),
                            ),
                            SizedBox(width: width * 0.02),
                            Text(
                              languageProvider.translate(
                                'orderCompletion.cashOnDelivery',
                              ),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.03),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff503636).withOpacity(0.75),
                    padding: EdgeInsets.symmetric(vertical: height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(width * 0.02),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            languageProvider.translate(
                              'orderCompletion.confirmOrder',
                            ),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
}
