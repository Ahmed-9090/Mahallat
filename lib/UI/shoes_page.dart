import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../auth/Data/models/stores_model.dart';
import '../auth/Data/repos/store_repos/store_repo_impl.dart';
import '../logic/stores_cubits/store_cubit.dart';
import '../logic/stores_cubits/store_state.dart';
import '../providers/language_provider.dart';

class ShoesPage extends StatefulWidget {
  const ShoesPage({super.key});

  @override
  State<ShoesPage> createState() => _ShoesPageState();
}

class _ShoesPageState extends State<ShoesPage> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return BlocProvider(
      create: (context) => StoreCubit(
        StoreRepositoryImpl(FirebaseFirestore.instance),
      )..loadStoresByCategory('shoes'),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            languageProvider.translate('shoes.title'),
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: () => _showFilterDialog(context),
            ),
          ],
        ),
        body: BlocBuilder<StoreCubit, StoreState>(
          builder: (context, state) {
            if (state is StoreLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is StoreError) {
              return Center(child: Text(state.message));
            } else if (state is StoresLoaded) {
              return _buildStoreList(state.stores);
            }
            return Center(child: Text(languageProvider.translate('shoes.noStores')));
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: 0,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildStoreList(List<StoreModel> stores) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shoe type filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFeatureChip(languageProvider.translate('shoes.filters.sneakers')),
                const SizedBox(width: 8),
                _buildFeatureChip(languageProvider.translate('shoes.filters.athletic')),
                const SizedBox(width: 8),
                _buildFeatureChip(languageProvider.translate('shoes.filters.casual')),
                const SizedBox(width: 8),
                _buildFeatureChip(languageProvider.translate('shoes.filters.formal')),
                const SizedBox(width: 8),
                _buildFeatureChip(languageProvider.translate('shoes.filters.boots')),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Store listings
          ...stores.map((store) => _buildStoreItem(
            name: store.name,
            location: store.location,
            imageUrl: store.image,
            rating: 4.5, // Example rating (would come from store data in real app)
          )),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text) {
    return Chip(
      label: Text(
        text,
        style: GoogleFonts.cairo(fontSize: 14),
      ),
      backgroundColor: Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildStoreItem({
    required String name,
    required String location,
    required String imageUrl,
    required double rating,
  }) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store image with shoe-themed placeholder
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: Icon(Icons.shopping_bag, size: 50, color: Colors.grey[400]),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: Icon(Icons.store, size: 50, color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Store name and rating
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          languageProvider.translate('shoes.filters.title'),
          style: GoogleFonts.cairo(),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption(languageProvider.translate('shoes.filters.mensShoes')),
              _buildFilterOption(languageProvider.translate('shoes.filters.womensShoes')),
              _buildFilterOption(languageProvider.translate('shoes.filters.kidsShoes')),
              _buildFilterOption(languageProvider.translate('shoes.filters.onSale')),
              _buildFilterOption(languageProvider.translate('shoes.filters.newArrivals')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.translate('shoes.filters.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              // Apply filters here
              Navigator.pop(context);
            },
            child: Text(languageProvider.translate('shoes.filters.applyFilters')),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(value: false, onChanged: (val) {}),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}