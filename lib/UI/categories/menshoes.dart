import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import '../home_screens/home_page.dart';
import '../product_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class Category {
  final String name;
  final List<String>? subCategories;

  Category({required this.name, this.subCategories});
}

final List<Category> mainCategories = [
  Category(name: 'أحذية رياضية'),
  Category(name: 'أحذية رسمية'),
  Category(name: 'أحذية كاجوال'),
  Category(name: 'بوت'),
  Category(name: 'أخرى'),
];

class MenShoes extends StatefulWidget {
  const MenShoes({super.key});

  @override
  State<MenShoes> createState() => _MenShoesState();
}

class _MenShoesState extends State<MenShoes> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/video.mp4');
      await _videoController
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _videoController.setLooping(true);
              _videoController.play();
            }
          })
          .catchError((error) {
            print('Error initializing video: $error');
            if (mounted) {
              setState(() {
                _isVideoInitialized = false;
              });
            }
          });
    } catch (e) {
      print('Error creating video controller: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xff503636), size: width * 0.06),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        title: Text(
          languageProvider.translate('menShoes.title'),
          style: GoogleFonts.cairo(
            fontSize: width * 0.05,
            fontWeight: FontWeight.bold,
            color: const Color(0xff503636),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffF1E4CF),
        elevation: 0,
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
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Video Banner
              Container(
                height: height * 0.25,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * 0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(width * 0.03),
                  child: _isVideoInitialized && _videoController.value.isInitialized
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController.value.size.width,
                            height: _videoController.value.size.height,
                            child: VideoPlayer(_videoController),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Text(
                              languageProvider.translate('menShoes.loading'),
                              style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              _buildCategorySelector(),
              selectedCategory == null
                  ? StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('stores')
                            .where('categories', arrayContains: 'Men Shoes')
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            languageProvider.translate('menShoes.errorLoading'),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.04,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stores = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.all(width * 0.04),
                        itemCount: stores.length,
                        itemBuilder: (context, index) {
                          final store = stores[index];
                          final statusString = store['status'] ?? '';
                          Color statusColor;
                          String statusText;
                          switch (statusString) {
                            case 'open':
                              statusColor = const Color(0xFF4CAF50);
                              statusText = languageProvider.translate(
                                'storeStatus.open',
                              );
                              break;
                            case 'closed':
                              statusColor = const Color(0xFFE53935);
                              statusText = languageProvider.translate(
                                'storeStatus.closed',
                              );
                              break;
                            case 'busy':
                              statusColor = const Color(0xFFFFA000);
                              statusText = languageProvider.translate(
                                'storeStatus.busy',
                              );
                              break;
                            default:
                              statusColor = Colors.grey;
                              statusText = '';
                          }
                          return Padding(
                            padding: EdgeInsets.only(bottom: height * 0.02),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => StoreProducts(
                                          sellerId: store['sellerId'],
                                          storeName: store['name'],
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xfffaf1e6),
                                ),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(width * 0.02),
                                      child: Container(
                                        width: width * 0.2,
                                        height: height * 0.1,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: NetworkImage(store['image']),
                                            fit: BoxFit.cover,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.all(width * 0.02),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  store['name'],
                                                  style: GoogleFonts.cairo(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: width * 0.04,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (statusText.isNotEmpty) ...[
                                                  SizedBox(width: width * 0.02),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: width * 0.02,
                                                      vertical: height * 0.005,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(width * 0.03),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.circle,
                                                          color: statusColor,
                                                          size: width * 0.025,
                                                        ),
                                                        SizedBox(width: width * 0.01),
                                                        Text(
                                                          statusText,
                                                          style: GoogleFonts.cairo(
                                                            fontSize: width * 0.03,
                                                            color: statusColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SizedBox(height: height * 0.01),
                                            Text(
                                              store['description'],
                                              style: GoogleFonts.cairo(
                                                color: Colors.grey,
                                                fontSize: width * 0.035,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                  : StreamBuilder<QuerySnapshot>(
                    stream: _buildProductsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('حدث خطأ ما', style: GoogleFonts.cairo()),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final languageProvider = Provider.of<LanguageProvider>(
                        context,
                      );
                      final products = snapshot.data!.docs;
                      if (products.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              languageProvider.translate('bags.noProducts'),
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.68,
                            ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Container(
                            decoration: const BoxDecoration(
                              color: Color(0xfffaf1e6),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ProductDetailsPage(
                                          product:
                                              product.data()
                                                  as Map<String, dynamic>,
                                          storeName: product['storeName'] ?? '',
                                        ),
                                  ),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          product['images'][0],
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  spreadRadius: 1,
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add_shopping_cart,
                                                color: Color(0xff44A2E6),
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                final user =
                                                    FirebaseAuth
                                                        .instance
                                                        .currentUser;
                                                if (user == null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'يرجى تسجيل الدخول أولاً',
                                                        style:
                                                            GoogleFonts.cairo(),
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                try {
                                                  final cartRef =
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(user.uid)
                                                          .collection('cart');

                                                  final cartItems =
                                                      await cartRef.get();
                                                  if (cartItems
                                                      .docs
                                                      .isNotEmpty) {
                                                    final firstItem =
                                                        cartItems.docs.first;
                                                    final currentStoreId =
                                                        firstItem['sellerId'];

                                                    if (currentStoreId !=
                                                        product['sellerId']) {
                                                      final shouldClearCart = await showDialog<
                                                        bool
                                                      >(
                                                        context: context,
                                                        builder:
                                                            (
                                                              context,
                                                            ) => AlertDialog(
                                                              title: Text(
                                                                languageProvider
                                                                    .translate(
                                                                      'menClothes.alert',
                                                                    ),
                                                                style:
                                                                    GoogleFonts.cairo(),
                                                              ),
                                                              content: Text(
                                                                'لديك منتجات في السلة من متجر آخر. إضافة هذا المنتج ستؤدي إلى حذف المنتجات السابقة. هل تريد المتابعة؟',
                                                                style:
                                                                    GoogleFonts.cairo(),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed:
                                                                      () => Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                                  child: Text(
                                                                    'لا',
                                                                    style:
                                                                        GoogleFonts.cairo(),
                                                                  ),
                                                                ),
                                                                TextButton(
                                                                  onPressed:
                                                                      () => Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                                  child: Text(
                                                                    'نعم',
                                                                    style:
                                                                        GoogleFonts.cairo(),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                      );

                                                      if (shouldClearCart ==
                                                              null ||
                                                          !shouldClearCart) {
                                                        return;
                                                      }

                                                      final batch =
                                                          FirebaseFirestore
                                                              .instance
                                                              .batch();
                                                      for (var doc
                                                          in cartItems.docs) {
                                                        batch.delete(
                                                          doc.reference,
                                                        );
                                                      }
                                                      await batch.commit();
                                                    }
                                                  }

                                                  final existingItem =
                                                      await cartRef
                                                          .where(
                                                            'productId',
                                                            isEqualTo:
                                                                product.id,
                                                          )
                                                          .get();

                                                  if (existingItem
                                                      .docs
                                                      .isNotEmpty) {
                                                    final currentQuantity =
                                                        existingItem
                                                                .docs
                                                                .first['quantity']
                                                            as int;
                                                    await cartRef
                                                        .doc(
                                                          existingItem
                                                              .docs
                                                              .first
                                                              .id,
                                                        )
                                                        .update({
                                                          'quantity':
                                                              currentQuantity +
                                                              1,
                                                        });
                                                  } else {
                                                    await cartRef.add({
                                                      'productId': product.id,
                                                      'name': product['name'],
                                                      'price': product['price'],
                                                      'image':
                                                          product['images'][0],
                                                      'quantity': 1,
                                                      'sellerId':
                                                          product['sellerId'],
                                                      'timestamp':
                                                          FieldValue.serverTimestamp(),
                                                    });
                                                  }

                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'تمت الإضافة إلى السلة',
                                                          style:
                                                              GoogleFonts.cairo(),
                                                        ),
                                                        duration:
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'حدث خطأ ما. يرجى المحاولة مرة أخرى',
                                                          style:
                                                              GoogleFonts.cairo(),
                                                        ),
                                                        duration:
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        right: 4.0,
                                        left: 4.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FutureBuilder<DocumentSnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection('stores')
                                                .where(
                                                  'sellerId',
                                                  isEqualTo:
                                                      product['sellerId'],
                                                )
                                                .get()
                                                .then(
                                                  (snapshot) =>
                                                      snapshot.docs.first,
                                                ),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Text(
                                                  snapshot.data!['name'],
                                                  style: GoogleFonts.cairo(
                                                    fontSize: 12,
                                                    color: const Color(
                                                      0xff44A2E6,
                                                    ),
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                );
                                              }
                                              return const SizedBox.shrink();
                                            },
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            product['name'],
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (product['description'] !=
                                              null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              product['description'],
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          const SizedBox(height: 2),
                                          Text(
                                            '${product['price']} JOD',
                                            style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xff44A2E6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final languageProvider = Provider.of<LanguageProvider>(context);
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    return Container(
      height: height * 0.06,
      margin: EdgeInsets.symmetric(vertical: height * 0.02),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mainCategories.length,
        itemBuilder: (context, index) {
          final category = mainCategories[index];
          final isSelected = selectedCategory == category.name;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.02),
            child: FilterChip(
              label: Text(
                languageProvider.translate('menShoes.${category.name}'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.035,
                  color: isSelected ? Colors.white : const Color(0xff503636),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (isSelected) {
                    selectedCategory = null;
                  } else {
                    selectedCategory = category.name;
                  }
                });
              },
              backgroundColor: const Color(0xffF1E4CF),
              selectedColor: const Color(0xff503636),
              checkmarkColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.03,
                vertical: height * 0.01,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(width * 0.03),
                side: BorderSide(
                  color: isSelected ? const Color(0xff503636) : const Color(0xffF1E4CF),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _buildProductsStream() {
    if (selectedCategory == 'other') {
      final excludedTypes = [
        'sportsShoes',
        'boots',
        'casualShoes',
        'formalShoes',
      ];

      return FirebaseFirestore.instance
          .collection('MenShoes')
          .where('productType', whereNotIn: excludedTypes)
          .where('isArchived', isEqualTo: false)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('MenShoes')
        .where('productType', isEqualTo: selectedCategory)
        .where('isArchived', isEqualTo: false)
        .snapshots();
  }
}

class StoreProducts extends StatefulWidget {
  final String sellerId;
  final String storeName;

  const StoreProducts({
    super.key,
    required this.sellerId,
    required this.storeName,
  });

  @override
  State<StoreProducts> createState() => _StoreProductsState();
}

class _StoreProductsState extends State<StoreProducts> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/video.mp4');
      await _videoController
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _videoController.setLooping(true);
              _videoController.play();
            }
          })
          .catchError((error) {
            print('Error initializing video: $error');
            if (mounted) {
              setState(() {
                _isVideoInitialized = false;
              });
            }
          });
    } catch (e) {
      print('Error creating video controller: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.storeName,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: const Color(0xff503636),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffF1E4CF),
        elevation: 0,
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
        height: double.infinity,
        child: Column(
          children: [
            // Video Banner
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    _isVideoInitialized && _videoController.value.isInitialized
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _videoController.value.size.width,
                              height: _videoController.value.size.height,
                              child: VideoPlayer(_videoController),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
              ),
            ),
            _buildCategorySelector(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('حدث خطأ ما', style: GoogleFonts.cairo()),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs;
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        'لا يوجد منتجات',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.68,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
                        decoration: const BoxDecoration(
                          color: Color(0xfffaf1e6),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProductDetailsPage(
                                      product:
                                          product.data()
                                              as Map<String, dynamic>,
                                      storeName: widget.storeName,
                                    ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        product['images'][0],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              spreadRadius: 1,
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.add_shopping_cart,
                                            color: Color(0xff44A2E6),
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            final user =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser;
                                            if (user == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'يرجى تسجيل الدخول أولاً',
                                                    style: GoogleFonts.cairo(),
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            try {
                                              final cartRef = FirebaseFirestore
                                                  .instance
                                                  .collection('users')
                                                  .doc(user.uid)
                                                  .collection('cart');

                                              final cartItems =
                                                  await cartRef.get();
                                              if (cartItems.docs.isNotEmpty) {
                                                final firstItem =
                                                    cartItems.docs.first;
                                                final currentStoreId =
                                                    firstItem['sellerId'];
                                                final languageProvider =
                                                    Provider.of<
                                                      LanguageProvider
                                                    >(context, listen: false);

                                                if (currentStoreId !=
                                                    product['sellerId']) {
                                                  final shouldClearCart = await showDialog<
                                                    bool
                                                  >(
                                                    context: context,
                                                    builder:
                                                        (
                                                          context,
                                                        ) => AlertDialog(
                                                          title: Text(
                                                            languageProvider
                                                                .translate(
                                                                  'menClothes.alert',
                                                                ),
                                                            style:
                                                                GoogleFonts.cairo(),
                                                          ),
                                                          content: Text(
                                                            languageProvider
                                                                .translate(
                                                                  'menClothes.clearCartMessage',
                                                                ),
                                                            style:
                                                                GoogleFonts.cairo(),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        false,
                                                                      ),
                                                              child: Text(
                                                                'لا',
                                                                style:
                                                                    GoogleFonts.cairo(),
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed:
                                                                  () =>
                                                                      Navigator.of(
                                                                        context,
                                                                      ).pop(
                                                                        true,
                                                                      ),
                                                              child: Text(
                                                                'نعم',
                                                                style:
                                                                    GoogleFonts.cairo(),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                  );

                                                  if (shouldClearCart == null ||
                                                      !shouldClearCart) {
                                                    return;
                                                  }

                                                  final batch =
                                                      FirebaseFirestore.instance
                                                          .batch();
                                                  for (var doc
                                                      in cartItems.docs) {
                                                    batch.delete(doc.reference);
                                                  }
                                                  await batch.commit();
                                                }
                                              }

                                              final existingItem =
                                                  await cartRef
                                                      .where(
                                                        'productId',
                                                        isEqualTo: product.id,
                                                      )
                                                      .get();

                                              if (existingItem
                                                  .docs
                                                  .isNotEmpty) {
                                                final currentQuantity =
                                                    existingItem
                                                            .docs
                                                            .first['quantity']
                                                        as int;
                                                await cartRef
                                                    .doc(
                                                      existingItem
                                                          .docs
                                                          .first
                                                          .id,
                                                    )
                                                    .update({
                                                      'quantity':
                                                          currentQuantity + 1,
                                                    });
                                              } else {
                                                await cartRef.add({
                                                  'productId': product.id,
                                                  'name': product['name'],
                                                  'price': product['price'],
                                                  'image': product['images'][0],
                                                  'quantity': 1,
                                                  'sellerId':
                                                      product['sellerId'],
                                                  'timestamp':
                                                      FieldValue.serverTimestamp(),
                                                });
                                              }
                                              final languageProvider =
                                                  Provider.of<LanguageProvider>(
                                                    context,
                                                    listen: false,
                                                  );

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      languageProvider.translate(
                                                        'womenClothes.addedToCart',
                                                      ),
                                                      style:
                                                          GoogleFonts.cairo(),
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'حدث خطأ ما. يرجى المحاولة مرة أخرى',
                                                      style:
                                                          GoogleFonts.cairo(),
                                                    ),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    right: 4.0,
                                    left: 4.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.storeName,
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          color: const Color(0xff44A2E6),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        product['name'],
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (product['description'] != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          product['description'],
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        '${product['price']} JOD',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xff44A2E6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mainCategories.length,
        itemBuilder: (context, index) {
          final category = mainCategories[index];
          final isSelected = selectedCategory == category.name;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FilterChip(
              label: Text(
                category.name,
                style: GoogleFonts.cairo(
                  color: isSelected ? Colors.white : const Color(0xff503636),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (isSelected) {
                    selectedCategory = null;
                  } else {
                    selectedCategory = category.name;
                  }
                });
              },
              backgroundColor: const Color(0xffF1E4CF),
              selectedColor: const Color(0xff503636),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected
                          ? const Color(0xff503636)
                          : const Color(0xffF1E4CF),
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _buildProductsStream() {
    Query query = FirebaseFirestore.instance
        .collection('MenShoes')
        .where('sellerId', isEqualTo: widget.sellerId)
        .where('isArchived', isEqualTo: false);

    if (selectedCategory == 'other') {
      final excludedTypes = [
        'sportsShoes',
        'boots',
        'casualShoes',
        'formalShoes',
      ];
      query = query.where('productType', whereNotIn: excludedTypes);
    } else if (selectedCategory != null) {
      query = query.where('productType', isEqualTo: selectedCategory);
    }

    return query.snapshots();
  }
}

class ProductCard extends StatefulWidget {
  final QueryDocumentSnapshot product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 1;
  final user = FirebaseAuth.instance.currentUser;
  String? storeName;

  @override
  void initState() {
    super.initState();
    _loadStoreName();
  }

  Future<void> _loadStoreName() async {
    try {
      final storeDoc =
          await FirebaseFirestore.instance
              .collection('stores')
              .where('sellerId', isEqualTo: widget.product['sellerId'])
              .get();

      if (storeDoc.docs.isNotEmpty) {
        setState(() {
          storeName = storeDoc.docs.first['name'];
        });
      }
    } catch (e) {
      print('Error loading store name: $e');
    }
  }

  Future<bool> _checkCartStore() async {
    if (user == null) return false;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart');

    final cartItems = await cartRef.get();

    if (cartItems.docs.isEmpty) return true;

    // التحقق من أول منتج في السلة لمعرفة المتجر الحالي
    final firstItem = cartItems.docs.first;
    final currentStoreId = firstItem['sellerId'];

    // التحقق مما إذا كان المنتج الجديد من نفس المتجر
    return currentStoreId == widget.product['sellerId'];
  }

  void _addToCart() async {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              languageProvider.translate('womenClothes.pleaseLogin'),

              style: GoogleFonts.cairo()),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cart');

      // التحقق من المتجر الحالي في السلة
      final sameStore = await _checkCartStore();
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      if (!sameStore) {
        // عرض مربع حوار للتأكيد
        final shouldClearCart = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  languageProvider.translate('menClothes.alert'),
                  style: GoogleFonts.cairo(),
                ),
                content: Text(
                  languageProvider.translate('menClothes.clearCartMessage'),
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                        languageProvider.translate('womenClothes.no')
    , style: GoogleFonts.cairo()),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
    languageProvider.translate('womenClothes.no'),
                        style: GoogleFonts.cairo()),
                  ),
                ],
              ),
        );

        if (shouldClearCart == null || !shouldClearCart) {
          return;
        }

        // حذف جميع المنتجات السابقة
        final batch = FirebaseFirestore.instance.batch();
        final cartItems = await cartRef.get();
        for (var doc in cartItems.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      final existingItem =
          await cartRef.where('productId', isEqualTo: widget.product.id).get();

      if (existingItem.docs.isNotEmpty) {
        final currentQuantity = existingItem.docs.first['quantity'] as int;
        await cartRef.doc(existingItem.docs.first.id).update({
          'quantity': currentQuantity + quantity,
        });
      } else {
        await cartRef.add({
          'productId': widget.product.id,
          'name': widget.product['name'],
          'price': widget.product['price'],
          'image': widget.product['images'][0],
          'quantity': quantity,
          'sellerId': widget.product['sellerId'],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('womenClothes.addedToCart'),
              style: GoogleFonts.cairo(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              languageProvider.translate('womenClothes.error'),

              style: GoogleFonts.cairo(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(width * 0.02)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius:  BorderRadius.vertical(top: Radius.circular(width * 0.02)),
            child: Image.network(
              widget.product['images'][0],
              width: double.infinity,
              height: height * 0.2,
              fit: BoxFit.cover,
              cacheWidth: width.toInt() * 2,
              cacheHeight: height.toInt() * 1,
            ),
          ),
          // معلومات المنتج
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اسم المتجر
                  if (storeName != null)
                    Text(
                      storeName!,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: Colors.blue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 1),
                  // اسم المنتج
                  Text(
                    widget.product['name'],
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  // الوصف
                  Text(
                    widget.product['description'] ?? '',
                    style: GoogleFonts.cairo(color: Colors.grey, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  // السعر
                  Text(
                    '${widget.product['price']} JOD',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  // أزرار الكمية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            size: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$quantity',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (quantity < widget.product['stock']) {
                            setState(() {
                              quantity++;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.add_circle_outline, size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // زر الإضافة إلى السلة
                  SizedBox(
                    width: double.infinity,
                    height: 22,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff44A2E6),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        languageProvider.translate('womenClothes.addedToCart'),

                        style: GoogleFonts.cairo(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
