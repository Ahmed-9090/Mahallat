import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/Data/models/products_model.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class ArchivedProductsPage extends StatefulWidget {
  const ArchivedProductsPage({super.key});

  @override
  State<ArchivedProductsPage> createState() => _ArchivedProductsPageState();
}

class _ArchivedProductsPageState extends State<ArchivedProductsPage> {
  final List<String> collections = [
    'Bags',
    'HealthAndCare',
    'KidsClothes',
    'KidsShoes',
    'MenClothes',
    'MenShoes',
    'WomenClothes',
    'WomenShoes',
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate('archivedProducts.title'),
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: width * 0.04,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait(
          collections.map(
            (collection) =>
                FirebaseFirestore.instance
                    .collection(collection)
                    .where('isArchived', isEqualTo: true)
                    .get(),
          ),
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(languageProvider.translate('archivedProducts.error')),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Combine all documents from different collections
          final allProducts =
              snapshot.data!
                  .expand((querySnapshot) => querySnapshot.docs)
                  .toList();

          if (allProducts.isEmpty) {
            return Center(
              child: Text(
                languageProvider.translate('archivedProducts.noProducts'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.04,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(width * 0.05),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: height * 0.02,
              mainAxisSpacing: width * 0.02,
              childAspectRatio: 0.8,
            ),
            itemCount: allProducts.length,
            itemBuilder: (context, index) {
              final product = allProducts[index];
              final productData = product.data() as Map<String, dynamic>;
              final hasValidImages = (productData['images'] as List).isNotEmpty;

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(width * 0.04),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(width * 0.04),
                            ),
                            child:
                                hasValidImages
                                    ? CachedNetworkImage(
                                      imageUrl: productData['images'][0],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder:
                                          (context, url) => Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                    )
                                    : Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(
                                          Icons.image,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.unarchive,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final shouldUnarchive = await showDialog<
                                    bool
                                  >(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text(
                                            languageProvider.translate('archivedProducts.unarchive.title'),
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(
                                            languageProvider.translate('archivedProducts.unarchive.message'),
                                            style: GoogleFonts.cairo(),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: Text(
                                                languageProvider.translate('archivedProducts.unarchive.cancel'),
                                                style: GoogleFonts.cairo(),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: Text(
                                                languageProvider.translate('archivedProducts.unarchive.confirm'),
                                                style: GoogleFonts.cairo(
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (shouldUnarchive == true) {
                                    try {
                                      // Update the product's isArchived flag
                                      await FirebaseFirestore.instance
                                          .collection(
                                            product.reference.parent.id,
                                          )
                                          .doc(product.id)
                                          .update({
                                            'isArchived': false,
                                            'updatedAt':
                                                FieldValue.serverTimestamp(),
                                          });

                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            languageProvider.translate('archivedProducts.unarchive.success'),
                                            style: GoogleFonts.cairo(),
                                          ),
                                        ),
                                      );

                                      // Refresh the page
                                      setState(() {});
                                    } catch (e) {
                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${languageProvider.translate('archivedProducts.unarchive.error')}: $e',
                                            style: GoogleFonts.cairo(),
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
                    Padding(
                      padding: EdgeInsets.all(width * 0.03),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productData['name'],
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.04,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            '\ ${productData['price'].toStringAsFixed(2)} JOD',
                            style: GoogleFonts.cairo(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: height * 0.005),
                          Text(
                            '${languageProvider.translate('archivedProducts.collection')}: ${product.reference.parent.id}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
