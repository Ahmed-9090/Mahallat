import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../auth/Data/models/products_model.dart';
import '../../logic/products_cubits/products_cubit.dart';
import '../../logic/products_cubits/products_state.dart';
import '../../providers/language_provider.dart';

class ClothesSellerPage extends StatefulWidget {
  final String sellerId;
  final List<String> availableCollections;
  final String initialCollection;

  const ClothesSellerPage({
    super.key,
    required this.sellerId,
    required this.availableCollections,
    required this.initialCollection,
  });

  @override
  State<ClothesSellerPage> createState() => _ClothesSellerPageState();
}

class _ClothesSellerPageState extends State<ClothesSellerPage> {
  late String _currentCollection;

  @override
  void initState() {
    super.initState();
    // Validate initial collection
    _currentCollection = widget.availableCollections.contains(widget.initialCollection)
        ? widget.initialCollection
        : widget.availableCollections.isNotEmpty
        ? widget.availableCollections.first
        : 'Men Clothing';
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
    return BlocConsumer<ProductsCubit, ProductsState>(
      listener: (context, state) {
        if (state is ProductsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.translate('clothesSeller.errors.loadFailed'))),
          );
        } else if (state is ProductAddedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.translate('clothesSeller.success.added'))),
          );
          _loadProducts();
        } else if (state is ProductUpdatedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.translate('clothesSeller.success.updated'))),
          );
          _loadProducts();
        } else if (state is ProductDeletedSuccessfully) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.translate('clothesSeller.success.deleted'))),
          );
          _loadProducts();
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: DropdownButton<String>(
              value: _currentCollection,
              items: widget.availableCollections.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null && newValue != _currentCollection) {
                  setState(() {
                    _currentCollection = newValue;
                  });
                  _loadProducts();
                }
              },
              underline: Container(),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadProducts,
              ),
            ],
          ),
          body: _buildBody(state),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddProductDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProductsState state) {
    final languageProvider = Provider.of<LanguageProvider>(context);
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductsModel product) {
    final hasValidImage = product.images.isNotEmpty &&
        product.images.first.isNotEmpty;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showProductDetails(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: hasValidImage
                    ? CachedNetworkImage(
                  imageUrl: product.images.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => _buildPlaceholderImage(),
                  errorWidget: (context, url, error) => _buildPlaceholderImage(),
                )
                    : _buildPlaceholderImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.cairo(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stock: ${product.stock}',
                    style: GoogleFonts.cairo(fontSize: 12),
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
                languageProvider.translate('clothesSeller.noProducts'),
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
                languageProvider.translate('clothesSeller.startAdding'),
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

  void _showAddProductDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final width = MediaQuery.of(context).size.width;

    XFile? _selectedImage;
    final ImagePicker _picker = ImagePicker();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(languageProvider.translate('clothesSeller.addProduct')),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: languageProvider.translate('clothesSeller.productName'),
                          hintText: languageProvider.translate('clothesSeller.productNameHint'),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? languageProvider.translate('clothesSeller.errors.required') : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: languageProvider.translate('clothesSeller.price'),
                          hintText: languageProvider.translate('clothesSeller.priceHint'),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? languageProvider.translate('clothesSeller.errors.required') : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: stockController,
                        decoration: InputDecoration(
                          labelText: languageProvider.translate('clothesSeller.stock'),
                          hintText: languageProvider.translate('clothesSeller.stockHint'),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? languageProvider.translate('clothesSeller.errors.required') : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: languageProvider.translate('clothesSeller.description'),
                          hintText: languageProvider.translate('clothesSeller.descriptionHint'),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final image = await _picker.pickImage(source: ImageSource.gallery);
                          if (image != null) {
                            setState(() => _selectedImage = image);
                          }
                        },
                        child: Text(languageProvider.translate('clothesSeller.addImage')),
                      ),
                      if (_selectedImage != null) Text(languageProvider.translate('clothesSeller.imageSelected')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(languageProvider.translate('clothesSeller.cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      final product = ProductsModel(
                        sellerId: widget.sellerId,
                        productId: '',
                        storeType: _currentCollection,
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        stock: int.parse(stockController.text),
                        description: descController.text,
                        images: _selectedImage != null
                            ? ['https://example.com/${_selectedImage!.path}']
                            : [],
                      );
                      context.read<ProductsCubit>().addProduct(product);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(languageProvider.translate('clothesSeller.save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProductDetails(BuildContext context, ProductsModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                trailing: Text('Stock: ${product.stock}'),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(product.description),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => _showEditProductDialog(context, product),
                    child: Text('Edit'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ProductsCubit>().deleteProduct(product);
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, ProductsModel product) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stock.toString());
    final descController = TextEditingController(text: product.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(languageProvider.translate('clothesSeller.editProduct')),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('clothesSeller.productName'),
                      hintText: languageProvider.translate('clothesSeller.productNameHint'),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? languageProvider.translate('clothesSeller.errors.required') : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('clothesSeller.price'),
                      hintText: languageProvider.translate('clothesSeller.priceHint'),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? languageProvider.translate('clothesSeller.errors.required') : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: stockController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('clothesSeller.stock'),
                      hintText: languageProvider.translate('clothesSeller.stockHint'),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty ?? true ? languageProvider.translate('clothesSeller.errors.required') : null,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: languageProvider.translate('clothesSeller.description'),
                      hintText: languageProvider.translate('clothesSeller.descriptionHint'),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(languageProvider.translate('clothesSeller.cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final updatedProduct = product.copyWith(
                    name: nameController.text,
                    price: double.parse(priceController.text),
                    stock: int.parse(stockController.text),
                    description: descController.text,
                  );
                  context.read<ProductsCubit>().updateProduct(updatedProduct);
                  Navigator.pop(context);
                }
              },
              child: Text(languageProvider.translate('clothesSeller.save')),
            ),
          ],
        );
      },
    );
  }
}