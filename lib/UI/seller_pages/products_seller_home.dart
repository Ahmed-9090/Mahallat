import 'dart:io';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../auth/Data/models/products_model.dart';
import '../../auth/Data/models/stores_model.dart';
import '../../auth/Data/models/product_types.dart';
import '../../logic/products_cubits/products_cubit.dart';
import '../../logic/products_cubits/products_state.dart';
import 'archived_products_page.dart';
import '../../providers/language_provider.dart';

class ProductsSellerHome extends StatefulWidget {
  final String sellerId;
  final List<String> availableCollections;
  final String initialCollection;

  const ProductsSellerHome({
    super.key,
    required this.sellerId,
    required this.availableCollections,
    required this.initialCollection,
  });

  @override
  State<ProductsSellerHome> createState() => _ProductsSellerHomeState();
}

class _ProductsSellerHomeState extends State<ProductsSellerHome> {
  late String _currentCollection;
  String? _selectedProductType;

  // Helper method to get translated text for display
  String getTranslatedProductType(String type) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    switch (widget.initialCollection) {
      case 'Men Clothing':
        return languageProvider.translate('menClothes.$type');
      case 'Women Clothing':
        return languageProvider.translate('womenClothes.$type');
      case 'Kids Clothing':
        return languageProvider.translate('kidsClothes.$type');
      case 'Men Shoes':
        return languageProvider.translate('menShoes.$type');
      case 'Women Shoes':
        return languageProvider.translate('womenShoes.$type');
      case 'Kids Shoes':
        return languageProvider.translate('kidsShoes.$type');
      case 'Health And Beauty':
        return languageProvider.translate('healthAndCare.$type');
      case 'Bags':
        return languageProvider.translate('bags.$type');
      default:
        return type;
    }
  }

  // Helper method to get translated type info for display
  String getTranslatedTypeInfo(String info) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (widget.initialCollection == 'Men Clothing' && _selectedProductType != null) {
      final Map<String, Map<String, String>> typeInfoTranslations = {
        'Straight': {'ar': 'ستريت', 'en': 'Straight'},
        'Slim Fit': {'ar': 'سليم فيت', 'en': 'Slim Fit'},
        'Boyfriend': {'ar': 'بوي فريند', 'en': 'Boyfriend'},
        'Tapered': {'ar': 'تايبرد', 'en': 'Tapered'},
        'Cropped': {'ar': 'كروب', 'en': 'Cropped'},
        'Baggy': {'ar': 'باجي', 'en': 'Baggy'},
        'Skinny': {'ar': 'سكني', 'en': 'Skinny'},
        'Round Neck': {'ar': 'ياقة مستديرة', 'en': 'Round Neck'},
        'V-Neck': {'ar': 'ياقة على شكل V', 'en': 'V-Neck'},
        'Polo': {'ar': 'بولو', 'en': 'Polo'},
        'Henley': {'ar': 'هنلي', 'en': 'Henley'},
        'Hoodie': {'ar': 'هودي', 'en': 'Hoodie'},
        'High Neck': {'ar': 'ياقة عالية', 'en': 'High Neck'},
        'Wool Sweater': {'ar': 'سويتر صوف', 'en': 'Wool Sweater'},
        'Cotton Sweater': {'ar': 'سويتر قطن', 'en': 'Cotton Sweater'}
      };
      
      final currentLanguage = languageProvider.currentLocale.languageCode;
      return typeInfoTranslations[info]?[currentLanguage] ?? info;
    }
    return info;
  }

  // Helper method to get English value for storage
  String getEnglishTypeInfo(String info) {
    if (widget.initialCollection == 'Men Clothing' && _selectedProductType != null) {
      final Map<String, String> typeInfoToEnglish = {
        'ستريت': 'Straight',
        'سليم فيت': 'Slim Fit',
        'بوي فريند': 'Boyfriend',
        'تايبرد': 'Tapered',
        'كروب': 'Cropped',
        'باجي': 'Baggy',
        'سكني': 'Skinny',
        'ياقة مستديرة': 'Round Neck',
        'ياقة على شكل V': 'V-Neck',
        'بولو': 'Polo',
        'هنلي': 'Henley',
        'هودي': 'Hoodie',
        'ياقة عالية': 'High Neck',
        'سويتر صوف': 'Wool Sweater',
        'سويتر قطن': 'Cotton Sweater'
      };
      return typeInfoToEnglish[info] ?? info;
    }
    return info;
  }

  @override
  void initState() {
    super.initState();
    _currentCollection =
        widget.availableCollections.contains(widget.initialCollection)
            ? widget.initialCollection
            : widget.availableCollections.isNotEmpty
            ? widget.availableCollections.first
            : StoreModel.validStoreTypes.first;
    _loadProducts();
  }

  void _loadProducts() {
    context.read<ProductsCubit>().loadProductsBySeller(
      widget.sellerId,
      _currentCollection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    var width = MediaQuery.of(context).size.width;
    return BlocConsumer<ProductsCubit, ProductsState>(
      listener: (context, state) {
        if (state is ProductsError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is ProductAddedSuccessfully) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          _loadProducts();
        } else if (state is ProductUpdatedSuccessfully) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          _loadProducts();
        } else if (state is ProductDeletedSuccessfully) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
          _loadProducts();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xffF1E4CF),
            title: Text(
              languageProvider.translate('productsSeller.title'),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: const Color(0xff503636),
                fontSize: width * 0.04,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.archive, color: const Color(0xff503636)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArchivedProductsPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: const Color(0xff503636)),
                onPressed: _loadProducts,
              ),
            ],
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
            child: _buildBody(state),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddProductDialog(context),
            backgroundColor: const Color(0xff503636),
            child: Icon(Icons.add, color: Colors.white),
            tooltip: languageProvider.translate('productsSeller.addProduct'),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProductsState state) {
    if (state is ProductsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ProductsLoaded && state.products.isEmpty) {
      return _buildEmptyState();
    } else if (state is ProductsLoaded) {
      return _buildProductGrid(state.products);
    }
    return _buildEmptyState();
  }

  Widget _buildProductGrid(List<ProductsModel> products) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.all(width * 0.05),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: height * 0.02,
          mainAxisSpacing: width * 0.02,
          childAspectRatio: 0.8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          if (product.isArchived ?? false) return const SizedBox.shrink();
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductsModel product) {
    final hasValidImages = product.images.isNotEmpty;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    int _currentImageIndex = 0;

    return Card(
      color: const Color(0xfffaf1e6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(width * 0.04),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(context, product),
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
                            ? Stack(
                              children: [
                                PageView.builder(
                                  itemCount: product.images.length,
                                  onPageChanged: (index) {
                                    _currentImageIndex = index;
                                  },
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      imageUrl: product.images[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder:
                                          (context, url) =>
                                              _buildPlaceholderImage(),
                                      errorWidget:
                                          (context, url, error) =>
                                              _buildPlaceholderImage(),
                                    );
                                  },
                                ),
                                if (product.images.length > 1)
                                  Positioned(
                                    bottom: 8,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        product.images.length,
                                        (index) => Container(
                                          width: 8,
                                          height: 8,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                _currentImageIndex == index
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                      0.5,
                                                    ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                            : _buildPlaceholderImage(),
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
                          Icons.archive,
                          color: Colors.black,
                          size: 20,
                        ),
                        onPressed: () async {
                          final shouldArchive = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text(
                                    'Archive Product',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to archive this product?',
                                    style: GoogleFonts.cairo(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.cairo(),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: Text(
                                        'Archive',
                                        style: GoogleFonts.cairo(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          if (shouldArchive == true) {
                            try {
                              // Create updated product with isArchived set to true
                              final updatedProduct = product.copyWith(
                                isArchived: true,
                                updatedAt: DateTime.now(),
                              );

                              // Use ProductsCubit to update the product
                              context.read<ProductsCubit>().updateProduct(
                                updatedProduct,
                              );
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to archive product: $e',
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
                    product.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.04,
                      color: const Color(0xff503636),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: height * 0.005),
                  Text(
                    '\ ${product.price.toStringAsFixed(2)} JOD',
                    style: GoogleFonts.cairo(
                      color: const Color(0xff44A2E6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: height * 0.005),
                  Text(
                    'Stock: ${product.stock}',
                    style: GoogleFonts.cairo(
                      fontSize: width * 0.034,
                      color: product.stock > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState() {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/empty.json',
                width: width * 0.5,
                height: height * 0.4,
              ),
              Text(
                languageProvider.translate('productsSeller.noProducts'),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.05,
                  color: Colors.black,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: height * 0.02),
              Text(
                languageProvider.translate('productsSeller.startAdding'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.036,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkPublishingStatus(
    BuildContext context,
    ProductsModel product,
  ) async {

    try {
      final statusDoc =
          await FirebaseFirestore.instance
              .collection('Automatic Publish')
              .doc('status')
              .get();

      // Transform collection name
      String transformedCollection = _currentCollection;
      switch (_currentCollection) {
        case 'Men Clothing':
          transformedCollection = 'MenClothes';
          break;
        case 'Women Clothing':
          transformedCollection = 'WomenClothes';
          break;
        case 'Kids Clothing':
          transformedCollection = 'KidsClothes';
          break;
        case 'Men Shoes':
          transformedCollection = 'MenShoes';
          break;
        case 'Women Shoes':
          transformedCollection = 'WomenShoes';
          break;
        case 'Kids Shoes':
          transformedCollection = 'KidsShoes';
          break;
        case 'Health And Beauty':
          transformedCollection = 'HealthAndCare';
          break;
        case 'Bags':
          transformedCollection = 'Bags';
          break;
      }

      if (statusDoc.exists && statusDoc.data()?['isAutomatic'] == true) {
        // Publish directly to the original collection
        context.read<ProductsCubit>().addProduct(product);
        Navigator.pop(context);
      } else {
        // Add to Pending Products collection with all product variables
        await FirebaseFirestore.instance.collection('Pending Products').add({
          'sellerId': product.sellerId,
          'productId': product.productId,
          'storeType': product.storeType,
          'name': product.name,
          'price': product.price,
          'stock': product.stock,
          'description': product.description,
          'images': product.images,
          'productType': product.productType,
          'typeInfo': product.typeInfo,
          'color': product.color,
          'size': product.size,
          'isArchived': product.isArchived ?? false,
          'createdAt': product.createdAt,
          'updatedAt': product.updatedAt,
          'originalCollection': transformedCollection,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product submitted for review')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking publishing status: $e')),
        );
      }
    }
  }



  Future<void> updateProductDirectlyOrPending(
      BuildContext context,
      ProductsModel product,
      ) async {
    try {
      // Transform collection name
      String transformedCollection = _currentCollection;
      switch (_currentCollection) {
        case 'Men Clothing':
          transformedCollection = 'MenClothes';
          break;
        case 'Women Clothing':
          transformedCollection = 'WomenClothes';
          break;
        case 'Kids Clothing':
          transformedCollection = 'KidsClothes';
          break;
        case 'Men Shoes':
          transformedCollection = 'MenShoes';
          break;
        case 'Women Shoes':
          transformedCollection = 'WomenShoes';
          break;
        case 'Kids Shoes':
          transformedCollection = 'KidsShoes';
          break;
        case 'Health And Beauty':
          transformedCollection = 'HealthAndCare';
          break;
        case 'Bags':
          transformedCollection = 'Bags';
          break;
      }

      // Always update product using cubit
      context.read<ProductsCubit>().updateProduct(product);
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }




  void _showAddProductDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();
    final colorController = TextEditingController();
    final sizeController = TextEditingController();
    final customTypeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<XFile> _selectedImages = [];
    final ImagePicker _picker = ImagePicker();
    bool _isUploading = false;
    String? _selectedTypeInfo;
    bool _showCustomTypeField = false;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    List<String> getProductTypes() {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      switch (widget.initialCollection) {
        case 'Men Clothing':
          return ProductTypes.menClothingTypes.keys.toList();
        case 'Women Clothing':
          return ProductTypes.womenClothingTypes;
        case 'Kids Clothing':
          return ProductTypes.kidsClothingTypes;
        case 'Men Shoes':
          return ProductTypes.menShoesTypes;
        case 'Women Shoes':
          return ProductTypes.womenShoesTypes;
        case 'Kids Shoes':
          return ProductTypes.kidsShoesTypes;
        case 'Health And Beauty':
          return ProductTypes.healthAndBeautyTypes;
        case 'Bags':
          return ProductTypes.bagsTypes;
        default:
          return [];
      }
    }

    List<String>? getTypeInfoOptions() {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (widget.initialCollection == 'Men Clothing' && _selectedProductType != null) {
        // Map of product types to their type info in English
        final Map<String, List<String>> typeInfo = {
          'بناطيل جينز': [
            'Straight',
            'Slim Fit',
            'Boyfriend',
            'Tapered',
            'Cropped',
            'Baggy',
            'Skinny',
            'Round Neck',
            'V-Neck',
            'Polo',
            'Henley',
            'Hoodie',
            'High Neck',
            'Wool Sweater',
            'Cotton Sweater'
          ],
          'بناطيل قماش': [],
          'بناطيل كارغو': [],
          'رياضة': [],
          'قمصان': [],
          'تيشيرتات وبلايز': [],
          'جاكيتات': [],
          'بليزر': [],
          'بدلات': [],
          'أخرى': []
        };

        return typeInfo[_selectedProductType];
      }
      return null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(width * 0.04),
              ),
              child: Container(
                width: width * 0.9,
                constraints: BoxConstraints(maxHeight: height * 0.8),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          languageProvider.translate('productsSeller.addProduct'),
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.05,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: height * 0.04),
                        Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedProductType,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.productType'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.02,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.02,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.02,
                                    ),
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                ),
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                selectedItemBuilder: (BuildContext context) {
                                  return getProductTypes().map<Widget>((String type) {
                                    return Text(
                                      getTranslatedProductType(type),
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.035,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.035,
                                  color: Colors.black,
                                ),
                                items: getProductTypes().map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: height * 0.01,
                                      ),
                                      child: Text(
                                        getTranslatedProductType(type),
                                        style: GoogleFonts.cairo(
                                          fontSize: width * 0.035,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProductType = value;
                                    _showCustomTypeField = value == 'أخرى';
                                    _selectedTypeInfo = null;
                                  });
                                },
                                validator: (value) => value == null ? 'Required' : null,
                              ),
                              SizedBox(height: height * 0.02),
                              if (_showCustomTypeField)
                                TextFormField(
                                  controller: customTypeController,
                                  decoration: InputDecoration(
                                    labelText: 'Custom Product Type',
                                    labelStyle: GoogleFonts.cairo(
                                      color: Colors.grey[700],
                                      fontSize: width * 0.035,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                ),
                              SizedBox(height: height * 0.02),
                              if (getTypeInfoOptions() != null &&
                                  getTypeInfoOptions()!.isNotEmpty)
                                DropdownButtonFormField<String>(
                                  value: _selectedTypeInfo,
                                  decoration: InputDecoration(
                                    labelText: 'Type Info',
                                    labelStyle: GoogleFonts.cairo(
                                      color: Colors.grey[700],
                                      fontSize: width * 0.035,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  selectedItemBuilder: (BuildContext context) {
                                    return getTypeInfoOptions()!.map<Widget>((String info) {
                                      return Text(
                                        getTranslatedTypeInfo(info),
                                        style: GoogleFonts.cairo(
                                          fontSize: width * 0.035,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList();
                                  },
                                  style: GoogleFonts.cairo(
                                    fontSize: width * 0.035,
                                    color: Colors.black,
                                  ),
                                  items: getTypeInfoOptions()!.map((info) {
                                    return DropdownMenuItem(
                                      value: info,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: height * 0.01,
                                        ),
                                        child: Text(
                                          getTranslatedTypeInfo(info),
                                          style: GoogleFonts.cairo(
                                            fontSize: width * 0.035,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTypeInfo = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Required' : null,
                                ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.productName'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: priceController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.price'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: stockController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.stock'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: colorController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.color'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              if (widget.initialCollection !=
                                  'Health And Beauty')
                                SizedBox(height: height * 0.02),
                              if (widget.initialCollection !=
                                      'Health And Beauty' &&
                                  widget.initialCollection != 'Bags')
                                TextFormField(
                                  controller: sizeController,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.translate('productsSeller.size'),
                                    labelStyle: GoogleFonts.cairo(
                                      color: Colors.grey[700],
                                      fontSize: width * 0.035,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                ),
                              if (widget.initialCollection !=
                                      'Health And Beauty' &&
                                  widget.initialCollection != 'Bags')
                                SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: descController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.description'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              SizedBox(height: height * 0.02),
                              // Image Grid
                              if (_selectedImages.isNotEmpty)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: width * 0.02,
                                        mainAxisSpacing: height * 0.02,
                                        childAspectRatio: 1,
                                      ),
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            File(_selectedImages[index].path),
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              SizedBox(height: height * 0.02),
                              if (_selectedImages.length < 4)
                                ElevatedButton(
                                  onPressed:
                                      _isUploading
                                          ? null
                                          : () async {
                                            final images = await _picker
                                                .pickMultiImage(
                                                  imageQuality: 70,
                                                );
                                            if (images.isNotEmpty) {
                                              final remainingSlots =
                                                  4 - _selectedImages.length;
                                              final imagesToAdd =
                                                  images
                                                      .take(remainingSlots)
                                                      .toList();
                                              setState(() {
                                                _selectedImages.addAll(
                                                  imagesToAdd,
                                                );
                                              });
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                  ),
                                  child: Text(
                                    languageProvider.translate('productsSeller.addImages') + ' ${4 - _selectedImages.length}' + languageProvider.translate('productsSeller.remainingImages'),
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              if (_isUploading)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.02,
                                  ),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed:
                                  _isUploading
                                      ? null
                                      : () => Navigator.pop(context),
                              child: Text(
                                languageProvider.translate('productsSeller.cancel'),
                                style: GoogleFonts.cairo(
                                  color: Colors.black,
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed:
                                  _isUploading
                                      ? null
                                      : () async {
                                        if (formKey.currentState?.validate() ??
                                            false) {
                                          if (_selectedImages.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  languageProvider.translate('productsSeller.selectimage'),
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          setState(() => _isUploading = true);

                                          try {
                                            List<String> imageUrls = [];

                                            // Upload all images to Firebase Storage
                                            for (XFile image
                                                in _selectedImages) {
                                              final storageRef = FirebaseStorage
                                                  .instance
                                                  .ref()
                                                  .child(
                                                    'products/${widget.sellerId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                                                  );

                                              await storageRef.putFile(
                                                File(image.path),
                                              );
                                              final imageUrl =
                                                  await storageRef
                                                      .getDownloadURL();
                                              imageUrls.add(imageUrl);
                                            }

                                            final product = ProductsModel(
                                              sellerId: widget.sellerId,
                                              productId: '',
                                              storeType: _currentCollection,
                                              name: nameController.text,
                                              price: double.parse(
                                                priceController.text,
                                              ),
                                              stock: int.parse(
                                                stockController.text,
                                              ),
                                              description: descController.text,
                                              images: imageUrls,
                                              productType:
                                                  _showCustomTypeField
                                                      ? customTypeController
                                                          .text
                                                      : _selectedProductType,
                                              typeInfo: _selectedTypeInfo != null ? getEnglishTypeInfo(_selectedTypeInfo!) : null,
                                              color:
                                                  widget.initialCollection ==
                                                          'Health And Beauty'
                                                      ? ''
                                                      : colorController.text,
                                              size:
                                                  (widget.initialCollection ==
                                                              'Health And Beauty' ||
                                                          widget.initialCollection ==
                                                              'Bags')
                                                      ? ''
                                                      : sizeController.text,
                                            );

                                            await _checkPublishingStatus(
                                              context,
                                              product,
                                            );
                                          } catch (e) {
                                            setState(
                                              () => _isUploading = false,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to upload images: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              child: Text(
                                languageProvider.translate('productsSeller.save'),
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: width * 0.04,
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
        );
      },
    );
  }

  void _showProductDetails(BuildContext context, ProductsModel product) {

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final stockController = TextEditingController(
      text: product.stock.toString(),
    );
    final descController = TextEditingController(text: product.description);
    final colorController = TextEditingController(text: product.color);
    final sizeController = TextEditingController(text: product.size);
    final customTypeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<XFile> _selectedImages = [];
    final ImagePicker _picker = ImagePicker();
    bool _isUploading = false;
    String? _selectedTypeInfo = product.typeInfo;
    bool _showCustomTypeField = false;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    List<String> getProductTypes() {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      switch (widget.initialCollection) {
        case 'Men Clothing':
          return ProductTypes.menClothingTypes.keys.toList();
        case 'Women Clothing':
          return ProductTypes.womenClothingTypes;
        case 'Kids Clothing':
          return ProductTypes.kidsClothingTypes;
        case 'Men Shoes':
          return ProductTypes.menShoesTypes;
        case 'Women Shoes':
          return ProductTypes.womenShoesTypes;
        case 'Kids Shoes':
          return ProductTypes.kidsShoesTypes;
        case 'Health And Beauty':
          return ProductTypes.healthAndBeautyTypes;
        case 'Bags':
          return ProductTypes.bagsTypes;
        default:
          return [];
      }
    }

    // Initialize product type handling
    List<String> productTypes = getProductTypes();
    if (!productTypes.contains(product.productType ?? '')) {
      _showCustomTypeField = true;
      _selectedProductType = 'أخرى';
      customTypeController.text = product.productType ?? '';
    } else {
      _selectedProductType = product.productType;
    }

    List<String>? getTypeInfoOptions() {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (widget.initialCollection == 'Men Clothing' && _selectedProductType != null) {
        // Map of product types to their type info in English
        final Map<String, List<String>> typeInfo = {
          'بناطيل جينز': [
            'Straight',
            'Slim Fit',
            'Boyfriend',
            'Tapered',
            'Cropped',
            'Baggy',
            'Skinny',
            'Round Neck',
            'V-Neck',
            'Polo',
            'Henley',
            'Hoodie',
            'High Neck',
            'Wool Sweater',
            'Cotton Sweater'
          ],
          'بناطيل قماش': [],
          'بناطيل كارغو': [],
          'رياضة': [],
          'قمصان': [],
          'تيشيرتات وبلايز': [],
          'جاكيتات': [],
          'بليزر': [],
          'بدلات': [],
          'أخرى': []
        };

        return typeInfo[_selectedProductType];
      }
      return null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(width * 0.05),
              ),
              child: Container(
                width: width * 0.9,
                constraints: BoxConstraints(maxHeight: height * 0.8),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate('productsSeller.editProduct'),
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.05,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  _isUploading
                                      ? null
                                      : () async {
                                        final shouldDelete = await showDialog<
                                          bool
                                        >(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: Text(
                                                  languageProvider.translate('productsSeller.deleteProduct'),
                                                  style: GoogleFonts.cairo(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: Text(
                                                  languageProvider.translate('productsSeller.confirmations.delete'),
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
                                                      languageProvider.translate('productsSeller.cancel'),
                                                      style:
                                                          GoogleFonts.cairo(),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: Text(
                                                      languageProvider.translate('productsSeller.delete'),
                                                      style: GoogleFonts.cairo(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (shouldDelete == true) {
                                          try {
                                            // Delete all product images
                                            for (String imageUrl
                                                in product.images) {
                                              try {
                                                await FirebaseStorage.instance
                                                    .refFromURL(imageUrl)
                                                    .delete();
                                              } catch (e) {
                                                print(
                                                  'Failed to delete image: $e',
                                                );
                                              }
                                            }

                                            // Delete product from users' cart
                                            final usersSnapshot = await FirebaseFirestore.instance
                                                .collection('users')
                                                .get();

                                            for (var userDoc in usersSnapshot.docs) {
                                              final cartSnapshot = await userDoc.reference
                                                  .collection('cart')
                                                  .where('productId', isEqualTo: product.productId)
                                                  .get();

                                              for (var cartDoc in cartSnapshot.docs) {
                                                await cartDoc.reference.delete();
                                              }
                                            }

                                            context
                                                .read<ProductsCubit>()
                                                .deleteProduct(product);
                                            Navigator.pop(dialogContext);
                                          } catch (e) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to delete product: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.02),
                        Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedProductType,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.productType'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.02,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.02,
                                    ),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      width * 0.02,
                                    ),
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                ),
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                selectedItemBuilder: (BuildContext context) {
                                  return getProductTypes().map<Widget>((String type) {
                                    return Text(
                                      getTranslatedProductType(type),
                                      style: GoogleFonts.cairo(
                                        fontSize: width * 0.035,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.035,
                                  color: Colors.black,
                                ),
                                items: getProductTypes().map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: height * 0.01,
                                      ),
                                      child: Text(
                                        getTranslatedProductType(type),
                                        style: GoogleFonts.cairo(
                                          fontSize: width * 0.035,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProductType = value;
                                    _showCustomTypeField = value == 'أخرى';
                                    _selectedTypeInfo = null;
                                  });
                                },
                                validator: (value) => value == null ? 'Required' : null,
                              ),
                              SizedBox(height: height * 0.02),
                              if (_showCustomTypeField)
                                TextFormField(
                                  controller: customTypeController,
                                  decoration: InputDecoration(
                                    labelText: 'Custom Product Type',
                                    labelStyle: GoogleFonts.cairo(
                                      color: Colors.grey[700],
                                      fontSize: width * 0.035,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                ),
                              SizedBox(height: height * 0.04),
                              if (getTypeInfoOptions() != null &&
                                  getTypeInfoOptions()!.isNotEmpty)
                                DropdownButtonFormField<String>(
                                  value: _selectedTypeInfo,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.translate('productsSeller.typeInfo'),
                                    labelStyle: GoogleFonts.cairo(
                                      color: Colors.grey[700],
                                      fontSize: width * 0.035,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        width * 0.02,
                                      ),
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  selectedItemBuilder: (BuildContext context) {
                                    return getTypeInfoOptions()!.map<Widget>((String info) {
                                      return Text(
                                        getTranslatedTypeInfo(info),
                                        style: GoogleFonts.cairo(
                                          fontSize: width * 0.035,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }).toList();
                                  },
                                  style: GoogleFonts.cairo(
                                    fontSize: width * 0.035,
                                    color: Colors.black,
                                  ),
                                  items: getTypeInfoOptions()!.map((info) {
                                    return DropdownMenuItem(
                                      value: info,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: height * 0.01,
                                        ),
                                        child: Text(
                                          getTranslatedTypeInfo(info),
                                          style: GoogleFonts.cairo(
                                            fontSize: width * 0.035,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTypeInfo = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Required' : null,
                                ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.productName'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: priceController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.price'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: stockController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.stock'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: colorController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.color'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Required'
                                            : null,
                              ),
                              if (widget.initialCollection !=
                                  'Health And Beauty')
                                SizedBox(height: height * 0.02),
                              if (widget.initialCollection !=
                                      'Health And Beauty' &&
                                  widget.initialCollection != 'Bags')
                                TextFormField(
                                  controller: sizeController,
                                  decoration: InputDecoration(
                                    labelText: languageProvider.translate('productsSeller.size'),
                                    labelStyle: GoogleFonts.cairo(
                                      color: Colors.grey[700],
                                      fontSize: width * 0.035,
                                    ),
                                  ),
                                  validator:
                                      (value) =>
                                          value?.isEmpty ?? true
                                              ? 'Required'
                                              : null,
                                ),
                              if (widget.initialCollection !=
                                      'Health And Beauty' &&
                                  widget.initialCollection != 'Bags')
                                SizedBox(height: height * 0.02),
                              TextFormField(
                                controller: descController,
                                decoration: InputDecoration(
                                  labelText: languageProvider.translate('productsSeller.description'),
                                  labelStyle: GoogleFonts.cairo(
                                    color: Colors.grey[700],
                                    fontSize: width * 0.035,
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              SizedBox(height: height * 0.02),
                              // Image Grid
                              if (product.images.isNotEmpty ||
                                  _selectedImages.isNotEmpty)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: width * 0.02,
                                        mainAxisSpacing: height * 0.02,
                                        childAspectRatio: 1,
                                      ),
                                  itemCount:
                                      product.images.length +
                                      _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    if (index < product.images.length) {
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: product.images[index],
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  product.images.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    } else {
                                      final selectedIndex =
                                          index - product.images.length;
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              File(
                                                _selectedImages[selectedIndex]
                                                    .path,
                                              ),
                                              height: 150,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedImages.removeAt(
                                                    selectedIndex,
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              SizedBox(height: height * 0.02),
                              if ((product.images.length +
                                      _selectedImages.length) <
                                  4)
                                ElevatedButton(
                                  onPressed:
                                      _isUploading
                                          ? null
                                          : () async {
                                            final images = await _picker
                                                .pickMultiImage(
                                                  imageQuality: 70,
                                                );
                                            if (images.isNotEmpty) {
                                              final remainingSlots =
                                                  4 -
                                                  (product.images.length +
                                                      _selectedImages.length);
                                              final imagesToAdd =
                                                  images
                                                      .take(remainingSlots)
                                                      .toList();
                                              setState(() {
                                                _selectedImages.addAll(
                                                  imagesToAdd,
                                                );
                                              });
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                  ),
                                  child: Text(
                                    languageProvider.translate('productsSeller.addImages') + ' ${4 - _selectedImages.length} ' + languageProvider.translate('productsSeller.remainingImages'),
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              if (_isUploading)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.02,
                                  ),
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: height * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed:
                                  _isUploading
                                      ? null
                                      : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: Size(width * 0.3, 50),
                              ),
                              child: Text(
                                languageProvider.translate('productsSeller.cancel'),
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed:
                                  _isUploading
                                      ? null
                                      : () async {
                                        if (formKey.currentState?.validate() ??
                                            false) {
                                          if (product.images.isEmpty && _selectedImages.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  languageProvider.translate('productsSeller.selectimage'),
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() => _isUploading = true);

                                          try {
                                            List<String> imageUrls = List.from(
                                              product.images,
                                            );

                                            // Upload new images
                                            for (XFile image
                                                in _selectedImages) {
                                              final storageRef = FirebaseStorage
                                                  .instance
                                                  .ref()
                                                  .child(
                                                    'products/${product.sellerId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                                                  );

                                              await storageRef.putFile(
                                                File(image.path),
                                              );
                                              final imageUrl =
                                                  await storageRef
                                                      .getDownloadURL();
                                              imageUrls.add(imageUrl);
                                            }

                                            final updatedProduct = product.copyWith(
                                              name: nameController.text,
                                              price: double.parse(
                                                priceController.text,
                                              ),
                                              stock: int.parse(
                                                stockController.text,
                                              ),
                                              description: descController.text,
                                              images: imageUrls,
                                              productType:
                                                  _showCustomTypeField
                                                      ? customTypeController
                                                          .text
                                                      : _selectedProductType,
                                              typeInfo: _selectedTypeInfo != null ? getEnglishTypeInfo(_selectedTypeInfo!) : null,
                                              color:
                                                  widget.initialCollection ==
                                                          'Health And Beauty'
                                                      ? ''
                                                      : colorController.text,
                                              size:
                                                  (widget.initialCollection ==
                                                              'Health And Beauty' ||
                                                          widget.initialCollection ==
                                                              'Bags')
                                                      ? ''
                                                      : sizeController.text,
                                            );

                                            await updateProductDirectlyOrPending(
                                              context,
                                              updatedProduct,
                                            );
                                          } catch (e) {
                                            setState(
                                              () => _isUploading = false,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to update product: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize: Size(width * 0.3, 50),
                              ),
                              child: Text(
                                languageProvider.translate('productsSeller.save'),
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontSize: width * 0.04,
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
        );
      },
    );
  }
}

