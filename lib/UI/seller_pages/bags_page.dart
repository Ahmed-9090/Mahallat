import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/Data/models/stores_model.dart';
import '../../auth/Data/repos/store_repos/store_repo_impl.dart';
import '../../logic/stores_cubits/store_cubit.dart';
import '../../logic/stores_cubits/store_state.dart';



class BagsPage extends StatefulWidget {
  const BagsPage({super.key});

  @override
  State<BagsPage> createState() => _BagsPageState();
}

class _BagsPageState extends State<BagsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StoreCubit(
        StoreRepositoryImpl(FirebaseFirestore.instance),
      )..loadStoresByCategory('bags'),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Bag Stores',
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
            return const Center(child: Text('No stores available'));
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
          // Store features row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFeatureChip('Handbags'),
                const SizedBox(width: 8),
                _buildFeatureChip('Backpacks'),
                const SizedBox(width: 8),
                _buildFeatureChip('Luggage'),
                const SizedBox(width: 8),
                _buildFeatureChip('Premium'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Store listings
          ...stores.map((store) => _buildStoreItem(
            name: store.name,
            location: store.location,
            imageUrl: store.image,
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store image from Firestore URL
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.store)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Store name
          Text(
            name.length > 25 ? '${name.substring(0, 25)}...' : name,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Location and info row
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                location.length > 30 ? '${location.substring(0, 30)}...' : location,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.grey[600],
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
}