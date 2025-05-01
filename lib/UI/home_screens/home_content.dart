import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../../providers/language_provider.dart';
import '../categories/bags.dart' as bags;
import '../categories/healthAndCare.dart' as health;
import '../categories/kidsClothes.dart' as kids;
import '../categories/kidsshoes.dart' as kidShoes;
import '../categories/menClothes.dart' as men;
import '../categories/menshoes.dart' as menShoes;
import '../categories/womenClothes.dart' as women;
import '../categories/womenshoes.dart' as womenShoes;
import '../cart/cart_screen.dart';
import '../product_details_page.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  String _searchQuery = '';
  String? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchFocused = false;
  bool _showSelectCategoryMessage = false;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  DateTime? _lastBackPressTime;
  Map<String, String> _storesMap = {};
  bool _storesLoading = true;

  final List<Map<String, String>> categories = [
    {
      'title': 'mensClothing',
      'image': 'assets/images/menclothes.jpg',
      'type': 'Men Clothing',
    },
    {
      'title': 'womensClothing',
      'image': 'assets/images/womanclothes.jpg',
      'type': 'Women Clothing',
    },
    {
      'title': 'kidsClothing',
      'image': 'assets/images/childcolthes.jpg',
      'type': 'Kids Clothing',
    },
    {
      'title': 'mensShoes',
      'image': 'assets/images/men shoes.jpg',
      'type': 'Men Shoes',
    },
    {
      'title': 'womensShoes',
      'image': 'assets/images/women shoes.jpg',
      'type': 'Women Shoes',
    },
    {
      'title': 'kidsShoes',
      'image': 'assets/images/childs shoes.jpg',
      'type': 'Kids Shoes',
    },
    {'title': 'bags', 'image': 'assets/images/bags.jpg', 'type': 'Bags'},
    {
      'title': 'healthAndBeauty',
      'image': 'assets/images/health and care.jpg',
      'type': 'Health And Beauty',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_backgroundController);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fetchStores();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _searchController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isVideoInitialized && !_videoController.value.isPlaying) {
      _videoController.play();
    }
  }

  @override
  void didUpdateWidget(HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isVideoInitialized) {
      _videoController.play();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/video.mp4');
      await _videoController
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isVideoInitialized = true;
              });
              _videoController.setLooping(true);
              _videoController.play();
            }
          })
          .catchError((error) {
            print('Error initializing video: $error');
            if (mounted) {
              setState(() {
                _isVideoInitialized = false;
              });
            }
          });
    } catch (e) {
      print('Error creating video controller: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  Future<void> _fetchStores() async {
    final storesSnapshot =
        await FirebaseFirestore.instance.collection('stores').get();
    final map = <String, String>{};
    for (var doc in storesSnapshot.docs) {
      final data = doc.data();
      map[data['sellerId']] = data['name'] ?? '';
    }
    print('Stores loaded: ${map.length}'); // Debug
    setState(() {
      _storesMap = map;
      _storesLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        if (_lastBackPressTime == null ||
            DateTime.now().difference(_lastBackPressTime!) >
                const Duration(seconds: 2)) {
          _lastBackPressTime = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              width: width * 0.5,
              content: Text(
                languageProvider.translate('home.pressAgainToExit'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              backgroundColor: const Color(0xffF1E4CF),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.02,
                vertical: height * 0.015,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(width * 0.1),
              ),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xffF1E4CF),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Color(0xffF1E4CF)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseAuth.instance.currentUser != null
                      ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .snapshots()
                      : Stream<DocumentSnapshot>.empty(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                    final username = userData?['name'] ?? '';
                  return Text(
                      username.isNotEmpty
                          ? languageProvider
                              .translate('home.welcomeUser')
                              .replaceAll('{username}', username)
                          : languageProvider.translate('home.welcome'),
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                }
                return Text(
                    languageProvider.translate('home.welcome'),
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xff503636),
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseAuth.instance.currentUser != null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('cart')
                              .snapshots()
                          : Stream<QuerySnapshot>.empty(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.docs.isNotEmpty) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xff503636),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${snapshot.data!.docs.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffF1E4CF), Color(0xffF1E4CF)],
          ),
        ),
        child: SafeArea(
            child: Stack(
              children: [
                // Animated background icons
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _backgroundAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Bottom row of icons - Left side
                          Positioned(
                            left: 20,
                            bottom: 20,
                            child: Transform.rotate(
                              angle: _backgroundAnimation.value,
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 70,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 80,
                            bottom: 40,
                            child: Transform.rotate(
                              angle: -_backgroundAnimation.value * 0.7,
                              child: Icon(
                                Icons.dry_cleaning_outlined,
                                size: 65,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 160,
                            bottom: 20,
                            child: Transform.rotate(
                              angle: _backgroundAnimation.value * 0.5,
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 70,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          // Bottom row of icons - Right side
                          Positioned(
                            right: 20,
                            bottom: 20,
                            child: Transform.rotate(
                              angle: -_backgroundAnimation.value * 0.3,
                              child: Icon(
                                Icons.checkroom_outlined,
                                size: 70,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 80,
                            bottom: 40,
                            child: Transform.rotate(
                              angle: _backgroundAnimation.value * 0.8,
                              child: Icon(
                                Icons.local_laundry_service_outlined,
                                size: 65,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 160,
                            bottom: 20,
                            child: Transform.rotate(
                              angle: -_backgroundAnimation.value * 0.4,
                              child: Icon(
                                Icons.face_retouching_natural_outlined,
                                size: 70,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          // Middle row of icons
                          Positioned(
                            left: 40,
                            bottom: 100,
                            child: Transform.rotate(
                              angle: _backgroundAnimation.value * 0.6,
                              child: Icon(
                                Icons.accessibility_new_outlined,
                                size: 60,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 40,
                            bottom: 100,
                            child: Transform.rotate(
                              angle: -_backgroundAnimation.value * 0.9,
                              child: Icon(
                                Icons.self_improvement_outlined,
                                size: 60,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          // Additional icons
                          Positioned(
                            left: 120,
                            bottom: 120,
                            child: Transform.rotate(
                              angle: _backgroundAnimation.value * 0.2,
                              child: Icon(
                                Icons.straighten_outlined,
                                size: 60,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 120,
                            bottom: 120,
                            child: Transform.rotate(
                              angle: -_backgroundAnimation.value * 0.5,
                              child: Icon(
                                Icons.style_outlined,
                                size: 60,
                                color: const Color(
                                  0xff503636,
                                ).withOpacity(0.25),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Focus(
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isSearchFocused = hasFocus;
                                if (hasFocus && _selectedFilter == null) {
                                  _showSelectCategoryMessage = true;
                                } else {
                                  _showSelectCategoryMessage = false;
                                }
                        });
                      },
                      child: TextField(
                        controller: _searchController,
                              readOnly: _selectedFilter == null,
                              onTap: () {
                                if (_selectedFilter == null) {
                                  setState(() {
                                    _showSelectCategoryMessage = true;
                                  });
                                }
                              },
                        decoration: InputDecoration(
                                hintText: languageProvider.translate(
                                  'home.searchHint',
                                ),
                          hintStyle: GoogleFonts.cairo(
                            color:
                                _isSearchFocused
                                    ? const Color(0xff503636)
                                    : Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                _isSearchFocused
                                    ? const Color(0xff503636)
                                    : Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                        ),
                      ),
                      if (_showSelectCategoryMessage && _selectedFilter == null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  languageProvider.translate(
                                    'home.selectCategoryFirst',
                                  ),
                                  style: GoogleFonts.cairo(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                  ),
                ),
                const SizedBox(height: 8),
                // Filter Buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ...categories.map(
                        (category) => _buildFilterButton(
                          category['title']!,
                          category['type']!,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Video Banner
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        _isVideoInitialized &&
                                _videoController.value.isInitialized
                            ? FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController.value.size.width,
                                      height:
                                          _videoController.value.size.height,
                                child: VideoPlayer(_videoController),
                              ),
                            )
                            : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                  ),
                ),
                // Search Results
                if (_searchQuery.isNotEmpty || _selectedFilter != null)
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('stores')
                            .where(
                              'storeTypes',
                              arrayContains: _selectedFilter ?? '',
                            )
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('حدث خطأ ما'));
                      }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                      }

                      final stores =
                          snapshot.data!.docs.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                            final name =
                                      data['name']?.toString().toLowerCase() ??
                                      '';
                            final storeTypes = List<String>.from(
                              data['storeTypes'] ?? [],
                            );

                            if (_searchQuery.isNotEmpty &&
                                      !name.contains(
                                        _searchQuery.toLowerCase(),
                                      )) {
                              return false;
                            }

                            if (_selectedFilter != null &&
                                !storeTypes.contains(_selectedFilter)) {
                              return false;
                            }

                            return true;
                          }).toList();

                      if (stores.isEmpty) {
                              return Center(
                          child: Padding(
                                  padding: EdgeInsets.all(width * 0.05),
                                  child: Text(
                                    languageProvider.translate(
                                      'home.noResults',
                                    ),
                                  ),
                          ),
                        );
                      }

                            return Column(
                              children: [
                                // Products Section
                                StreamBuilder<QuerySnapshot>(
                                  stream:
                                      _selectedFilter != null
                                          ? FirebaseFirestore.instance
                                              .collection(
                                                _getCollectionName(
                                                  _selectedFilter!,
                                                ),
                                              )
                                              .where(
                                                'isArchived',
                                                isEqualTo: false,
                                              )
                                              .snapshots()
                                          : const Stream.empty(),
                                  builder: (context, productSnapshot) {
                                    if (productSnapshot.hasError) {
                                      return const Center(
                                        child: Text('حدث خطأ ما'),
                                      );
                                    }

                                    if (productSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final products =
                                        productSnapshot.data?.docs.where((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final name =
                                              data['name']
                                                  ?.toString()
                                                  .toLowerCase() ??
                                              '';

                                          if (_searchQuery.isNotEmpty &&
                                              !name.contains(
                                                _searchQuery.toLowerCase(),
                                              )) {
                                            return false;
                                          }

                                          return true;
                                        }).toList() ??
                                        [];

                                    if (products.isEmpty && stores.isEmpty) {
                                      return Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(width * 0.05),
                                          child: Text(
                                            languageProvider.translate(
                                              'home.noResults',
                                            ),
                                        ),
                                  ),
                                );
                                    }

                                    if (_storesLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    return Column(
                                      children: [
                                        if (products.isNotEmpty) ...[
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.05,
                                              vertical: height * 0.01,
                                            ),
                                            child: Text(
                                              languageProvider.translate(
                                                'home.products',
                                              ),
                                              style: GoogleFonts.cairo(
                                                fontSize: width * 0.04,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xff503636),
                                              ),
                                            ),
                                          ),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            padding: EdgeInsets.all(
                                              width * 0.05,
                                            ),
                                            itemCount: products.length,
                                            itemBuilder: (context, index) {
                                              final product =
                                                  products[index].data()
                                                      as Map<String, dynamic>;
                                              return _buildProductItem(
                                                product,
                                                context,
                                                _storesMap,
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                        );
                                      },
                                    ),
                                // Stores Section
                                if (stores.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      languageProvider.translate('home.stores'),
                                          style: GoogleFonts.cairo(
                                        fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                        color: const Color(0xff503636),
                                      ),
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: stores.length,
                                    itemBuilder: (context, index) {
                                      final store =
                                          stores[index].data()
                                              as Map<String, dynamic>;
                                      return _buildStoreItem(store, context);
                                    },
                                  ),
                                ],
                              ],
                      );
                    },
                  ),
                // Categories
                if (_searchQuery.isEmpty && _selectedFilter == null)
                        SizedBox(height: height * 0.02),
                Container(
                  width: double.infinity,
                        padding: EdgeInsets.all(width * 0.05),
                        decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xffF1E4CF), Colors.white],
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                              languageProvider.translate('home.categories'),
                        style: GoogleFonts.cairo(
                                fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                            SizedBox(height: height * 0.02),
                      // First Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCategoryItem(
                            categories[0]['title']!,
                            categories[0]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => men.Menclothes(),
                                ),
                              );
                            },
                          ),
                          _buildCategoryItem(
                            categories[1]['title']!,
                            categories[1]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                        builder:
                                            (context) => women.Womanclothes(),
                                ),
                              );
                            },
                          ),
                          _buildCategoryItem(
                            categories[2]['title']!,
                            categories[2]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                        builder:
                                            (context) => kids.KIdsclothes(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Second Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCategoryItem(
                            categories[3]['title']!,
                            categories[3]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                        builder:
                                            (context) => menShoes.MenShoes(),
                                ),
                              );
                            },
                          ),
                          _buildCategoryItem(
                            categories[4]['title']!,
                            categories[4]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                womenShoes.Womenshoes(),
                                ),
                              );
                            },
                          ),
                          _buildCategoryItem(
                            categories[5]['title']!,
                            categories[5]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                        builder:
                                            (context) => kidShoes.Kidsshoes(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SizedBox(width: 100),
                          _buildCategoryItem(
                            categories[6]['title']!,
                            categories[6]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => bags.Bags(),
                                ),
                              );
                            },
                          ),
                          _buildCategoryItem(
                            categories[7]['title']!,
                            categories[7]['image']!,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const health.Healthandcare(),
                                ),
                              );
                            },
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title, String? type) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isSelected = _selectedFilter == type;
    final highlight = _showSelectCategoryMessage && _selectedFilter == null;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          languageProvider.translate('home.categoriesList.$title'),
          style: GoogleFonts.cairo(
            color: isSelected ? Colors.white : const Color(0xff503636),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? type : null;
            _showSelectCategoryMessage = false;
          });
        },
        backgroundColor:
            isSelected
                ? const Color(0xff503636)
                : highlight
                ? Colors.red.withOpacity(0.15)
                : const Color(0xffF1E4CF),
        selectedColor: const Color(0xff503636),
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color:
                isSelected
                    ? const Color(0xff503636)
                    : highlight
                    ? Colors.red
                    : const Color(0xffF1E4CF),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: width * 0.01),
          padding: EdgeInsets.all(width * 0.02),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(width * 0.03),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: width * 0.15,
                height: width * 0.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * 0.02),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: height * 0.01),
              Text(
                languageProvider.translate('home.categoriesList.$title'),
                style: GoogleFonts.cairo(
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreItem(Map<String, dynamic> store, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);

    Color getStatusColor(String status) {
      switch (status) {
        case 'open':
          return const Color(0xFF4CAF50); // Green
        case 'closed':
          return const Color(0xFFE53935); // Red
        case 'busy':
          return const Color(0xFFFFA000); // Yellow/Orange
        default:
          return Colors.grey;
      }
    }

    String getStatusText(String status) {
      switch (status) {
        case 'open':
          return languageProvider.translate('storeStatus.open');
        case 'closed':
          return languageProvider.translate('storeStatus.closed');
        case 'busy':
          return languageProvider.translate('storeStatus.busy');
        default:
          return '';
      }
    }

    return GestureDetector(
      onTap: () {
        final storeType = _selectedFilter ?? '';
        final sellerId = store['sellerId'] ?? '';
        final storeName = store['name'] ?? '';

        if (storeType == 'Men Clothing') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => men.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        } else if (storeType == 'Women Clothing') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => women.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        } else if (storeType == 'Kids Clothing') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => kids.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        } else if (storeType == 'Men Shoes') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => menShoes.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        } else if (storeType == 'Women Shoes') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => womenShoes.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        } else if (storeType == 'Kids Shoes') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => kidShoes.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        } else if (storeType == 'Bags') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => bags.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        } else if (storeType == 'Health And Beauty') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => health.StoreProducts(
                    sellerId: sellerId,
                    storeName: storeName,
                  ),
            ),
          );
        }
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              margin: EdgeInsets.only(bottom: height * 0.02),
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(width * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(width * 0.02),
                    child: Image.network(
                      store['image'] ?? '',
                      width: width * 0.2,
                      height: width * 0.2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: width * 0.2,
                          height: width * 0.2,
                          color: Colors.grey[200],
                          child: Icon(Icons.store, size: width * 0.1),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store['name'] ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: height * 0.005),
                        Text(
                          store['location'] ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.02,
                            vertical: height * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              store['status'] ?? '',
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(width * 0.03),
                            border: Border.all(
                              color: getStatusColor(store['status'] ?? ''),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: width * 0.02,
                                height: width * 0.02,
                                decoration: BoxDecoration(
                                  color: getStatusColor(store['status'] ?? ''),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: width * 0.01),
                              Text(
                                getStatusText(store['status'] ?? ''),
                                style: GoogleFonts.cairo(
                                  fontSize: width * 0.03,
                                  color: getStatusColor(store['status'] ?? ''),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildProductItem(
    Map<String, dynamic> product,
    BuildContext context,
    Map<String, String> storesMap,
  ) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final sellerId = product['sellerId'] ?? '';
    final storeName = storesMap[sellerId] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: product,
              storeName: storeName,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.02),
        padding: EdgeInsets.all(width * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(width * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(width * 0.02),
                  child: Image.network(
                    (product['images'] as List<dynamic>?)?.first?.toString() ?? '',
                    width: width * 0.2,
                    height: width * 0.2,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: width * 0.2,
                        height: width * 0.2,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, size: width * 0.1),
                      );
                    },
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        '${product['price'] ?? 0} ${languageProvider.translate('home.price')}',
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.035,
                          color: const Color(0xff503636),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product['productType'] != null) ...[
                        SizedBox(height: height * 0.005),
                        Text(
                          product['productType'] ?? '',
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (product['size'] != null) ...[
                        SizedBox(height: height * 0.005),
                        Text(
                          '${languageProvider.translate('home.size')}: ${product['size']}',
                          style: GoogleFonts.cairo(
                            fontSize: width * 0.035,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      SizedBox(height: height * 0.005),
                      Text(
                        storeName.isNotEmpty
                            ? '${languageProvider.translate('home.storeName')}: $storeName'
                            : 'اسم المحل غير متوفر',
                        style: GoogleFonts.cairo(
                          fontSize: width * 0.035,
                          color: storeName.isNotEmpty ? Colors.brown : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsPage(
                                product: product,
                                storeName: storeName,
                              ),
                        ),
                      );
                    },
                    icon: Icon(Icons.remove_red_eye_outlined, size: width * 0.045),
                    label: Text(
                      languageProvider.translate('home.viewDetails'),
                      style: GoogleFonts.cairo(fontSize: width * 0.03),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff503636),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(width * 0.02),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsPage(
                                product: product,
                                storeName: storeName,
                              ),
                        ),
                      );
                    },
                    icon: Icon(Icons.shopping_cart_outlined, size: width * 0.045),
                    label: Text(
                      languageProvider.translate('home.addToCart'),
                      style: GoogleFonts.cairo(fontSize: width * 0.03),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff503636),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: height * 0.01),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(width * 0.02),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCollectionName(String filter) {
    switch (filter) {
      case 'Men Clothing':
        return 'MenClothes';
      case 'Women Clothing':
        return 'WomenClothes';
      case 'Kids Clothing':
        return 'KidsClothes';
      case 'Men Shoes':
        return 'MenShoes';
      case 'Women Shoes':
        return 'WomenShoes';
      case 'Kids Shoes':
        return 'KidsShoes';
      case 'Bags':
        return 'Bags';
      case 'Health And Beauty':
        return 'HealthAndCare';
      default:
        return '';
    }
  }
}
