// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'stylist_profile_screen.dart';
import 'booking_screen.dart';
import 'user_profile_screen.dart';
import '../providers/user_provider.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _visibleStylistCount = 0;
  final int _loadDelay = 300; // milliseconds

  final List<Map<String, dynamic>> _stylists = [
    {
      'name': 'Alex Thompson',
      'specialty': 'Hair Coloring & Balayage',
      'description':
          'Expert in modern coloring techniques with 5 years of experience. Specializes in balayage, ombre, and color correction.',
      'experience': '5 years',
      'rating': 4.8,
      'image':
          'https://i.ibb.co/hFXbvzdJ/stylist-1-min.png', // Replace with your actual ImgBB direct URL
      'services': [
        'Hair Coloring',
        'Balayage',
        'Ombre',
        'Color Correction',
        'Haircut & Styling',
      ],
    },
    {
      'name': 'Marcus Lee',
      'specialty': 'Men\'s Haircutting',
      'description':
          'Master barber with expertise in classic and modern men\'s haircuts. Known for precise fades and beard grooming.',
      'experience': '8 years',
      'rating': 4.9,
      'image':
          'https://i.ibb.co/6cmR0Z3H/stylist-2-min.jpg', // Replace with your actual ImgBB direct URL
      'services': [
        'Men\'s Haircut',
        'Beard Grooming',
        'Hair Styling',
        'Hair Treatment',
      ],
    },
    {
      'name': 'Sophia Martinez',
      'specialty': 'Women\'s Haircutting',
      'description':
          'Specializes in women\'s haircuts and styling. Expert in layered cuts, bobs, and pixie cuts.',
      'experience': '6 years',
      'rating': 4.7,
      'image':
          'https://i.ibb.co/DPr3ZQF3/stylist-3-min.png', // Replace with your actual ImgBB direct URL
      'services': [
        'Women\'s Haircut',
        'Layered Cut',
        'Bob Cut',
        'Pixie Cut',
        'Hair Styling',
      ],
    },
    {
      'name': 'Ryan Patel',
      'specialty': 'Hair Treatment & Care',
      'description':
          'Certified hair care specialist focusing on treatments, scalp health, and hair restoration.',
      'experience': '4 years',
      'rating': 4.6,
      'image':
          'https://i.ibb.co/vvV92ybj/stylist-4-min.png', // Replace with your actual ImgBB direct URL
      'services': [
        'Hair Treatment',
        'Scalp Treatment',
        'Hair Spa',
        'Deep Conditioning',
        'Hair Mask',
      ],
    },
    {
      'name': 'Isabella Chen',
      'specialty': 'Hair Extensions',
      'description':
          'Expert in hair extensions and transformations. Specializes in tape-in, clip-in, and fusion methods.',
      'experience': '7 years',
      'rating': 4.8,
      'image':
          'https://i.ibb.co/G44S0FQR/stylist-5-min.png', // Replace with your actual ImgBB direct URL
      'services': [
        'Hair Extensions',
        'Hair Transformations',
        'Hair Styling',
        'Hair Treatment',
      ],
    },
    {
      'name': 'Jordan Williams',
      'specialty': 'Creative Styling',
      'description':
          'Creative stylist specializing in unique cuts, styling, and hair art. Perfect for those looking for bold transformations.',
      'experience': '3 years',
      'rating': 4.5,
      'image':
          'https://i.ibb.co/prGhsKRG/stylist-6-min.png', // Replace with your actual ImgBB direct URL
      'services': [
        'Creative Haircut',
        'Hair Art',
        'Hair Styling',
        'Hair Coloring',
      ],
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Haircut & Styling',
      'price': 50.00,
      'subServices': [
        {'name': 'Men\'s Haircut', 'price': 30.00},
        {'name': 'Women\'s Haircut', 'price': 40.00},
        {'name': 'Kids Haircut', 'price': 25.00},
        {'name': 'Bob Cut', 'price': 45.00},
        {'name': 'Pixie Cut', 'price': 45.00},
        {'name': 'Layered Cut', 'price': 50.00},
        {'name': 'Bang Trim', 'price': 20.00},
      ],
    },
    {
      'name': 'Hair Coloring',
      'price': 80.00,
      'subServices': [
        {'name': 'Full Color', 'price': 80.00},
        {'name': 'Highlights', 'price': 100.00},
        {'name': 'Balayage', 'price': 150.00},
        {'name': 'Ombre', 'price': 120.00},
        {'name': 'Root Touch-up', 'price': 60.00},
        {'name': 'Color Correction', 'price': 200.00},
      ],
    },
    {
      'name': 'Hair Treatment',
      'price': 60.00,
      'subServices': [
        {'name': 'Deep Conditioning', 'price': 40.00},
        {'name': 'Keratin Treatment', 'price': 150.00},
        {'name': 'Hair Spa', 'price': 70.00},
        {'name': 'Scalp Treatment', 'price': 50.00},
        {'name': 'Hair Mask', 'price': 45.00},
      ],
    },
    {'name': 'Hair Wash & Blow Dry', 'price': 40.00},
    {'name': 'Hair Extensions', 'price': 200.00},
    {'name': 'Hair Spa', 'price': 70.00},
    {'name': 'Hair Consultation', 'price': 20.00},
  ];

  @override
  void initState() {
    super.initState();
    _loadStylistsSequentially();
  }

  void _loadStylistsSequentially() {
    Timer.periodic(Duration(milliseconds: _loadDelay), (timer) {
      if (_visibleStylistCount < _stylists.length) {
        setState(() {
          _visibleStylistCount++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredStylists {
    if (_searchQuery.isEmpty) {
      return _stylists;
    }
    return _stylists.where((stylist) {
      return stylist['name'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          stylist['specialty'].toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  List<Map<String, dynamic>> get filteredServices {
    if (_searchQuery.isEmpty) {
      return _services;
    }
    return _services.where((service) {
      return service['name'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: theme.colorScheme.onBackground,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
              hintText: 'Search stylists, services...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.6),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (query) {
              setState(() {
                _searchQuery = query;
              });
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UserProfileScreen(
                          fullName:
                              userProvider.currentUser?.fullName ?? 'User',
                          email: userProvider.currentUser?.email ?? '',
                        ),
                  ),
                );
              },
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: theme.colorScheme.background,
              child: TabBar(
                tabs: const [Tab(text: 'Stylists'), Tab(text: 'Services')],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onBackground,
                indicatorColor: theme.colorScheme.primary,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Stylists Tab
                  _buildStylistGrid(),

                  // Services Tab
                  _buildServicesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    final filteredItems =
        _searchQuery.isEmpty
            ? _services
            : _services
                .where(
                  (service) =>
                      service['name'].toLowerCase().contains(_searchQuery),
                )
                .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final service = filteredItems[index];
        final hasSubServices = service['subServices'] != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () {
              if (hasSubServices) {
                _showSubServices(context, service);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BookingScreen(
                          serviceName: service['name'],
                          servicePrice: service['price'],
                        ),
                  ),
                );
              }
            },
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.spa,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(service['name']),
            subtitle: Text(hasSubServices ? 'Tap to view options' : ''),
            trailing: Text(
              '₹${service['price'].toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  void _showSubServices(BuildContext context, Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: service['subServices'].length,
                    itemBuilder: (context, index) {
                      final subService = service['subServices'][index];
                      return ListTile(
                        title: Text(subService['name']),
                        trailing: Text(
                          '₹${subService['price'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BookingScreen(
                                    serviceName: subService['name'],
                                    servicePrice: subService['price'],
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStylistGrid() {
    final stylists = filteredStylists;
    return GridView.builder(
      shrinkWrap: false,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _visibleStylistCount,
      itemBuilder: (context, index) {
        final stylist = stylists[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => StylistProfileScreen(
                      stylistName: stylist['name'],
                      specialty: stylist['specialty'],
                      description: stylist['description'],
                      experience: stylist['experience'],
                      rating: stylist['rating'],
                      services: List<String>.from(stylist['services']),
                      imageUrl: stylist['image'],
                    ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: stylist['image'] ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        memCacheWidth: 800,
                        memCacheHeight: 800,
                        maxWidthDiskCache: 800,
                        maxHeightDiskCache: 800,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        errorWidget: (context, url, error) {
                          print('Error loading image: $error');
                          print('Failed URL: $url');
                          return Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stylist['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stylist['specialty'],
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              stylist['rating'].toString(),
                              style: const TextStyle(fontSize: 11),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.access_time, size: 12),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                stylist['experience'],
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
