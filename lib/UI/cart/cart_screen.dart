import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_completion_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final width = size.width;
    final height = size.height - padding.top - padding.bottom;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            languageProvider.translate('cart.title'),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: width * 0.05,
              color: const Color(0xff503636).withOpacity(0.75),
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
              colors: [Color(0xffF1E4CF), Color(0xfffaf1e6), Color(0xffF1E4CF)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Center(
            child: Text(
              languageProvider.translate('cart.pleaseLogin'),
              style: GoogleFonts.cairo(
                fontSize: width * 0.045,
                color: const Color(0xff503636).withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate('cart.title'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: width * 0.05,
            color: const Color(0xff503636).withOpacity(0.75),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('cart')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  languageProvider.translate('cart.error'),
                  style: GoogleFonts.cairo(
                    fontSize: width * 0.045,
                    color: const Color(0xff503636).withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: const Color(0xff503636).withOpacity(0.75),
                ),
              );
            }

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  languageProvider.translate('cart.empty'),
                  style: GoogleFonts.cairo(
                    fontSize: width * 0.045,
                    color: const Color(0xff503636).withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            double totalPrice = 0;
            for (var doc in snapshot.data!.docs) {
              totalPrice += (doc['price'] as num) * (doc['quantity'] as num);
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(width * 0.04),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final item = snapshot.data!.docs[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: height * 0.02),
                        decoration: BoxDecoration(
                          color: const Color(0xfffaf1e6),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xff503636).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.03),
                          child: Row(
                            children: [
                              // Product Image
                              Container(
                                width: width * 0.2,
                                height: width * 0.2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(width * 0.02),
                                  border: Border.all(
                                    color: const Color(0xff503636).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                borderRadius: BorderRadius.circular(width * 0.02),
                                child: Hero(
                                  tag: 'product_${item.id}',
                                  child: Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.image_not_supported,
                                          color: const Color(0xff503636).withOpacity(0.75),
                                          size: width * 0.08,
                                      );
                                    },
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: width * 0.04),
                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: width * 0.04,
                                        color: const Color(0xff503636).withOpacity(0.75),
                                      ),
                                    ),
                                    SizedBox(height: height * 0.01),
                                    Text(
                                      '${item['price']} ${languageProvider.translate('cart.price')}',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xff503636).withOpacity(0.75),
                                        fontWeight: FontWeight.w600,
                                        fontSize: width * 0.035,
                                      ),
                                    ),
                                    Text(
                                      '${languageProvider.translate('cart.total')}: ${(item['price'] as num) * (item['quantity'] as num)} ${languageProvider.translate('cart.price')}',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xff503636).withOpacity(0.75),
                                        fontWeight: FontWeight.w600,
                                        fontSize: width * 0.035,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xfffaf1e6),
                                  borderRadius: BorderRadius.circular(width * 0.02),
                                  border: Border.all(
                                    color: const Color(0xff503636).withOpacity(0.2),
                                    width: width * 0.005,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove,
                                        size: width * 0.05,
                                        color: const Color(0xff503636).withOpacity(0.75),
                                      ),
                                      onPressed: () {
                                        if (item['quantity'] > 1) {
                                          item.reference.update({
                                            'quantity': item['quantity'] - 1,
                                          });
                                        }
                                      },
                                      constraints: BoxConstraints(
                                        minWidth: width * 0.08,
                                        minHeight: width * 0.08,
                                      ),
                                    ),
                                    Text(
                                      '${item['quantity']}',
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.04,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xff503636).withOpacity(0.75),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.add,
                                        size: width * 0.05,
                                        color: const Color(0xff503636).withOpacity(0.75),
                                      ),
                                      onPressed: () {
                                        item.reference.update({
                                          'quantity': item['quantity'] + 1,
                                        });
                                      },
                                      constraints: BoxConstraints(
                                        minWidth: width * 0.08,
                                        minHeight: width * 0.08,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete Button
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: const Color(0xff503636).withOpacity(0.75),
                                  size: width * 0.06,
                                ),
                                onPressed: () {
                                  item.reference.delete().then((_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          languageProvider.translate('cart.productDeleted'),
                                          style: GoogleFonts.cairo(
                                            fontSize: width * 0.035,
                                            color: Colors.white,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: const Color(0xff503636).withOpacity(0.75),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        margin: EdgeInsets.all(width * 0.04),
                                      ),
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Total Price and Checkout Button
                Container(
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff503636).withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              languageProvider.translate('cart.totalPrice'),
                            style: GoogleFonts.cairo(
                                fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                                color: const Color(0xff503636).withOpacity(0.75),
                            ),
                          ),
                          Text(
                              '${totalPrice.toStringAsFixed(2)} ${languageProvider.translate('cart.price')}',
                            style: GoogleFonts.cairo(
                                fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                                color: const Color(0xff503636).withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                        SizedBox(height: height * 0.02),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final firstItem = snapshot.data!.docs.first;
                            final sellerId = firstItem['sellerId'];
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OrderCompletionScreen(
                                      totalPrice: totalPrice,
                                      sellerId: sellerId,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff503636).withOpacity(0.75),
                              padding: EdgeInsets.symmetric(
                                vertical: height * 0.02,
                              ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(width * 0.05),
                            ),
                              elevation: 2,
                          ),
                          child: Text(
                              languageProvider.translate('cart.completeOrder'),
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
