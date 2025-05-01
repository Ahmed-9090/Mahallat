import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../auth/Data/models/stores_model.dart';
import '../../auth/Data/repos/store_repos/store_repo_impl.dart';
import '../../logic/stores_cubits/store_cubit.dart';
import '../../logic/stores_cubits/store_state.dart';


class PerfumesPage extends StatefulWidget {
  const PerfumesPage({super.key});

  @override
  State<PerfumesPage> createState() => _PerfumesPageState();
}

class _PerfumesPageState extends State<PerfumesPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StoreCubit(
        StoreRepositoryImpl(FirebaseFirestore.instance),
      )..loadStoresByCategory('perfumes'),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Perfume Stores',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
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
            return const Center(child: Text('No perfume stores available'));
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Perfume type filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFeatureChip('Men\'s'),
                const SizedBox(width: 8),
                _buildFeatureChip('Women\'s'),
                const SizedBox(width: 8),
                _buildFeatureChip('Unisex'),
                const SizedBox(width: 8),
                _buildFeatureChip('Luxury'),
                const SizedBox(width: 8),
                _buildFeatureChip('Niche'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Store listings
          ...stores.map((store) => _buildStoreItem(
            name: store.name,
            location: store.location,
            imageUrl: store.image,
            description: store.description,
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
    String? description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store image with perfume-themed placeholder
          Container(
            height: 180, // Slightly taller for perfume items
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
                    child: Icon(Icons.spa, size: 50, color: Colors.grey[400]),
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

          // Store name
          Text(
            name,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                location,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Brief description if available
          if (description != null && description.isNotEmpty)
            Text(
              description.length > 60 ? '${description.substring(0, 60)}...' : description,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),
        ],
      ),
    );
  }
}