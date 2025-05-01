import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class MyOeders extends StatefulWidget {
  const MyOeders({super.key});

  @override
  State<MyOeders> createState() => _MyOedersState();
}

class _MyOedersState extends State<MyOeders> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isArabic = languageProvider.currentLocale.languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate('myOrders.title'),
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xff503636),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffF1E4CF),
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
          stream:
              FirebaseFirestore.instance
                  .collection('Orders')
                  .where('userId', isEqualTo: userId)
                  .orderBy('orderDate', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  languageProvider.translate('myOrders.loadingError'),
                  style: GoogleFonts.cairo(color: const Color(0xff503636)),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  languageProvider.translate('myOrders.noOrders'),
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    color: const Color(0xff503636),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final order =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                final items = order['items'] as List<dynamic>;
                final orderDate = (order['orderDate'] as Timestamp).toDate();
                final status = order['status'] as String;
                final customerInfo =
                    order['customerInfo'] as Map<String, dynamic>;
                final orderDetails =
                    order['orderDetails'] as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xfffaf1e6),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Status and Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(orderDate),
                              style: GoogleFonts.cairo(
                                color: const Color(0xff503636),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Store Info
                        Text(
                          '${languageProvider.translate('myOrders.store')}: ${order['storeName']}',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Order Items
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, itemIndex) {
                            final item =
                                items[itemIndex] as Map<String, dynamic>;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  // Product Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: item['image'] as String,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            width: 80,
                                            height: 80,
                                            color: Colors.grey[200],
                                            child: const Icon(Icons.error),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] as String,
                                          style: GoogleFonts.cairo(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xff503636),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${languageProvider.translate('myOrders.quantity')}: ${item['quantity']}',
                                          style: GoogleFonts.cairo(
                                            color: const Color(0xff503636),
                                          ),
                                        ),
                                        Text(
                                          '${languageProvider.translate('myOrders.price')}: ${item['price']} د.أ',
                                          style: GoogleFonts.cairo(
                                            color: const Color(0xff503636),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        // Order Details
                        Text(
                          languageProvider.translate('myOrders.orderDetails'),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate('myOrders.productsTotal'),
                              style: GoogleFonts.cairo(
                                color: const Color(0xff503636),
                              ),
                            ),
                            Text(
                              '${orderDetails['productsTotal']} د.أ',
                              style: GoogleFonts.cairo(
                                color: const Color(0xff503636),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate('myOrders.deliveryFee'),
                              style: GoogleFonts.cairo(
                                color: const Color(0xff503636),
                              ),
                            ),
                            Text(
                              '${orderDetails['deliveryFee']} د.أ',
                              style: GoogleFonts.cairo(
                                color: const Color(0xff503636),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate('myOrders.serviceFee'),
                              style: GoogleFonts.cairo(
                                color: const Color(0xff503636),
                              ),
                            ),
                            Text(
                              '${orderDetails['serviceFee']} د.أ',
                              style: GoogleFonts.cairo(
                                color: const Color(0xff503636),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate('myOrders.finalTotal'),
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff503636),
                              ),
                            ),
                            Text(
                              '${orderDetails['finalTotal']} د.أ',
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff503636),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Customer Info
                        Text(
                          languageProvider.translate('myOrders.deliveryInfo'),
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff503636),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${languageProvider.translate('myOrders.phoneNumber')}: ${customerInfo['phoneNumber']}',
                          style: GoogleFonts.cairo(
                            color: const Color(0xff503636),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${languageProvider.translate('myOrders.address')}: ${customerInfo['address']}',
                          style: GoogleFonts.cairo(
                            color: const Color(0xff503636),
                          ),
                        ),
                        if (customerInfo['addressInfo'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${languageProvider.translate('myOrders.addressDetails')}: ${customerInfo['addressInfo']}',
                            style: GoogleFonts.cairo(
                              color: const Color(0xff503636),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
