import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetails({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  int quantity = 1;
  late final User? user;
  late final LanguageProvider languageProvider;
  late final Map<String, dynamic> translations;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    translations = languageProvider.translations;
  }

  void _addToCart() async {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations['productDetails']['pleaseLogin'])),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('cart');

      final existingItem =
          await cartRef.where('productId', isEqualTo: widget.product['id']).get();

      if (existingItem.docs.isNotEmpty) {
        final currentQuantity = existingItem.docs.first['quantity'] as int;
        await cartRef.doc(existingItem.docs.first.id).update({
          'quantity': currentQuantity + quantity,
        });
      } else {
        await cartRef.add({
          'productId': widget.product['id'],
          'name': widget.product['name'],
          'price': widget.product['price'],
          'image': widget.product['images'][0],
          'quantity': quantity,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(
              languageProvider.translate('womenClothes.addedToCart'),

            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(
              languageProvider.translate('womenClothes.error'),

            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: height * 0.3,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 1,
              ),
              items:
                  (widget.product['images'] as List).map((image) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(width * 0.02),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(width * 0.02),
                            child: Image.network(image, fit: BoxFit.cover),
                          ),
                        );
                      },
                    );
                  }).toList(),
            ),
             SizedBox(height: height * 0.02),
            Text(
              widget.product['name'] ?? '',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
             SizedBox(height: height * 0.02),
                  Text(
              '${widget.product['price'] ?? 0} ${translations['productDetails']['price']}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                    ),
                  ),
                   SizedBox(height: height * 0.02),
                  Text(
              '${translations['productDetails']['stock']}: ${widget.product['stock'] ?? 0}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
             SizedBox(height: height * 0.02),
            Text(
              translations['productDetails']['description'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              widget.product['description'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
                  ),
                   SizedBox(height: height * 0.02),
                  Row(
              mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                  translations['productDetails']['quantity'],
                        style:  TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.05,
                  ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon:  Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() {
                              quantity--;
                            });
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style:  TextStyle(
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                        if (quantity < (widget.product['stock'] ?? 0)) {
                            setState(() {
                              quantity++;
                            });
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        padding:  EdgeInsets.symmetric(vertical: height * 0.02),
                      ),
                child: Text(
                  translations['productDetails']['addToCart'],
                  style:  GoogleFonts.cairo(
                            fontSize: width * 0.05,
                          fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: height * 0.05),
          ],
        ),
      ),
    );
  }
}
