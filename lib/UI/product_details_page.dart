import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/language_provider.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String storeName;

  const ProductDetailsPage({Key? key, required this.product, required this.storeName}) : super(key: key);

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  int quantity = 1;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _backgroundAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_backgroundController);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<bool> _checkCartStore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart');

    final cartItems = await cartRef.get();

    if (cartItems.docs.isEmpty) return true;

    final firstItem = cartItems.docs.first;
    final currentStoreId = firstItem['sellerId'];

    return currentStoreId == widget.product['sellerId'];
  }

  Future<void> _addToCart() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider.translate('cart.pleaseLogin'),
            style: GoogleFonts.cairo(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart');

      final sameStore = await _checkCartStore();

      if (!sameStore) {
        final shouldClearCart = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  languageProvider.translate('bags.alert'),
                  style: GoogleFonts.cairo(),
                ),
                content: Text(
                  languageProvider.translate('bags.clearCartMessage'),
                  style: GoogleFonts.cairo(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      languageProvider.translate('bags.no'),
                      style: GoogleFonts.cairo(),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      languageProvider.translate('bags.yes'),
                      style: GoogleFonts.cairo(),
                    ),
                  ),
                ],
              ),
        );

        if (shouldClearCart == null || !shouldClearCart) {
          return;
        }

        final batch = FirebaseFirestore.instance.batch();
        final cartItems = await cartRef.get();
        for (var doc in cartItems.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      final existingItem =
          await cartRef
              .where('productId', isEqualTo: widget.product['productId'])
              .get();

      if (existingItem.docs.isNotEmpty) {
        final currentQuantity = existingItem.docs.first['quantity'] as int;
        await cartRef.doc(existingItem.docs.first.id).update({
          'quantity': currentQuantity + quantity,
        });
      } else {
        await cartRef.add({
          'productId': widget.product['productId'],
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
              languageProvider.translate('home.error'),
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xffF1E4CF),
      appBar: AppBar(
        title: Text(
          languageProvider.translate('home.viewDetails'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: const Color(0xff503636),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffF1E4CF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xff503636)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Top row of icons
                    Positioned(
                      top: 50,
                      left: 20,
                      child: Transform.rotate(
                        angle: _backgroundAnimation.value,
                        child: Icon(
                          Icons.checkroom_outlined,
                          size: 60,
                          color: const Color(0xff503636).withOpacity(0.15),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Transform.rotate(
                        angle: -_backgroundAnimation.value * 0.7,
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 60,
                          color: const Color(0xff503636).withOpacity(0.15),
                        ),
                      ),
                    ),
                    // Middle row of icons
                    Positioned(
                      top: height * 0.3,
                      left: width * 0.2,
                      child: Transform.rotate(
                        angle: _backgroundAnimation.value * 0.5,
                        child: Icon(
                          Icons.dry_cleaning_outlined,
                          size: 70,
                          color: const Color(0xff503636).withOpacity(0.15),
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * 0.3,
                      right: width * 0.2,
                      child: Transform.rotate(
                        angle: -_backgroundAnimation.value * 0.3,
                        child: Icon(
                          Icons.local_laundry_service_outlined,
                          size: 70,
                          color: const Color(0xff503636).withOpacity(0.15),
                        ),
                      ),
                    ),
                    // Bottom row of icons
                    Positioned(
                      bottom: 50,
                      left: 20,
                      child: Transform.rotate(
                        angle: _backgroundAnimation.value * 0.8,
                        child: Icon(
                          Icons.face_retouching_natural_outlined,
                          size: 60,
                          color: const Color(0xff503636).withOpacity(0.15),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 50,
                      right: 20,
                      child: Transform.rotate(
                        angle: -_backgroundAnimation.value * 0.4,
                        child: Icon(
                          Icons.style_outlined,
                          size: 60,
                          color: const Color(0xff503636).withOpacity(0.15),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Slider
                Container(
                  height: height * 0.4,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            _currentPageNotifier.value = index;
                          },
                          itemCount: widget.product['images'].length,
                          itemBuilder: (context, index) {
                            return Hero(
                              tag: 'product_${widget.product['productId']}_$index',
                              child: CachedNetworkImage(
                                imageUrl: widget.product['images'][index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xff503636),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.error,
                                  color: Color(0xff503636),
                                ),
                              ),
                            );
                          },
                        ),
                        // Dots Indicator
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _currentPageNotifier,
                            builder: (context, currentPage, _) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  widget.product['images'].length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: currentPage == index ? 20 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: currentPage == index
                                          ? const Color(0xff503636)
                                          : Colors.grey.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 17),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        widget.product['name'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff503636),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.storeName.isNotEmpty
                          ? '${languageProvider.translate('home.storeName')}: ${widget.storeName}'
                          : 'اسم المحل غير متوفر',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: widget.storeName.isNotEmpty ? Colors.brown : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      // Price
                      Text(
                        '${widget.product['price']} ${languageProvider.translate('home.price')}',
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff503636),
                        ),
                      ),
                      SizedBox(height: height * 0.02),
                      // Size and Color (if available)
                      if (widget.product['size']?.isNotEmpty ?? false)
                        _buildInfoRow(
                          '${languageProvider.translate('home.size')}:',
                          widget.product['size'],
                        ),
                      if (widget.product['color']?.isNotEmpty ?? false)
                        _buildInfoRow(
                          '${languageProvider.translate('home.color')}:',
                          widget.product['color'],
                        ),
                      SizedBox(height: height * 0.02),
                      // Description
                      if (widget.product['description']?.isNotEmpty ?? false) ...[
                        Text(
                          '${languageProvider.translate('home.description')}:',
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.045,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636),
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Text(
                          widget.product['description'],
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                      // Quantity Selector
                      SizedBox(height: height * 0.01),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: const Color(0xff503636),
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() {
                                    quantity--;
                                  });
                                }
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                '$quantity',
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff503636),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: const Color(0xff503636),
                              onPressed: () {
                                if (quantity < widget.product['stock']) {
                                  setState(() {
                                    quantity++;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: height * 0.01),
                      // Add to Cart Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff503636),
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.2,
                              vertical: height * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            languageProvider.translate('home.addToCart'),
                            style: GoogleFonts.cairo(
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
              color: const Color(0xff503636),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: MediaQuery.of(context).size.width * 0.04,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
