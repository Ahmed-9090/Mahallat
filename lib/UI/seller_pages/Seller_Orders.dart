import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SellerOrders extends StatefulWidget {
  const SellerOrders({Key? key}) : super(key: key);

  @override
  State<SellerOrders> createState() => _SellerOrdersState();
}

class _SellerOrdersState extends State<SellerOrders> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _markOrdersAsRead();
  }

  Future<void> _markOrdersAsRead() async {
    final user = _auth.currentUser;
    if (user != null) {
      final ordersRef = _firestore.collection('Orders');
      final query = ordersRef
          .where('sellerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending');

      final snapshot = await query.get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': 'accepted',
          'lastRead': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('Marked ${snapshot.docs.length} orders as accepted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('sellerOrders.title')),
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
          _firestore
              .collection('Orders')
              .where('sellerId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('orderDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  languageProvider.translate('sellerOrders.loadingError'),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data?.docs.isEmpty ?? true) {
              return Center(
                child: Text(
                  languageProvider.translate('sellerOrders.noOrders'),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                final order = snapshot.data?.docs[index];
                final data = order?.data() as Map<String, dynamic>;
                final date = (data['orderDate'] as Timestamp).toDate();
                final items = data['items'] as List<dynamic>;
                final status = data['status'] as String;
                final storeName = data['storeName'] as String? ?? '';

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
                        // Order Date
                        Text(
                          languageProvider
                              .translate('sellerOrders.orderDate')
                              .replaceAll('{day}', date.day.toString())
                              .replaceAll('{month}', date.month.toString())
                              .replaceAll('{year}', date.year.toString()),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: const Color(0xff503636),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Size Details
                        if (data['sizeDetails'] != null &&
                            data['sizeDetails'].toString().isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.translate(
                                  'sellerOrders.sizeDetails',
                                ),
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff503636),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['sizeDetails'].toString(),
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: const Color(0xff503636),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: item['image'] as String,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child:
                                          CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                        width: double.infinity,
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Product Details
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
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        languageProvider
                                            .translate('sellerOrders.quantity')
                                            .replaceAll(
                                          '{quantity}',
                                          item['quantity'].toString(),
                                        ),
                                        style: GoogleFonts.cairo(
                                          fontSize: 14,
                                          color: const Color(0xff503636),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Show sizeDetails if exists for this item, directly under quantity
                                  if (item['sizeDetails'] != null &&
                                      item['sizeDetails'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 4.0,
                                        bottom: 4.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            languageProvider.translate(
                                              'sellerOrders.sizeDetails',
                                            ),
                                            style: GoogleFonts.cairo(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xff503636),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              item['sizeDetails'].toString(),
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                color: const Color(0xff503636),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                        // Show sizeDetails at the bottom of the card with translation and styling
                        if ((data['sizeDetails'] ??
                            (data['customerInfo']?['sizeDetails'])) !=
                            null &&
                            (data['sizeDetails'] ??
                                (data['customerInfo']?['sizeDetails']))
                                .toString()
                                .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageProvider.translate(
                                    'sellerOrders.sizeDetails',
                                  ),
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xff503636),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    (data['sizeDetails'] ??
                                        (data['customerInfo']?['sizeDetails']))
                                        .toString(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      color: const Color(0xff503636),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}