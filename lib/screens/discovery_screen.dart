// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'booking_screen.dart';
import 'user_profile_screen.dart';
import 'stylist_profile_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Example services data - in a real app, this would come from a backend
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
    {'name': 'Hair Trim', 'price': 30.00},
    {'name': 'Hair Consultation', 'price': 20.00},
  ];

  // Example stylists data
  final List<Map<String, dynamic>> _stylists = [
    {
      'name': 'Stylist 1',
      'specialty': 'Hair Coloring & Balayage',
      'description':
          'Expert in modern coloring techniques with 5 years of experience. Specializes in balayage, ombre, and color correction.',
      'experience': '5 years',
      'rating': 4.8,
      'services': [
        'Hair Coloring',
        'Balayage',
        'Ombre',
        'Color Correction',
        'Haircut & Styling',
      ],
    },
    {
      'name': 'Stylist 2',
      'specialty': 'Men\'s Haircutting',
      'description':
          'Master barber with expertise in classic and modern men\'s haircuts. Known for precise fades and beard grooming.',
      'experience': '8 years',
      'rating': 4.9,
      'services': [
        'Men\'s Haircut',
        'Beard Grooming',
        'Hair Styling',
        'Hair Treatment',
      ],
    },
    {
      'name': 'Stylist 3',
      'specialty': 'Women\'s Haircutting',
      'description':
          'Specializes in women\'s haircuts and styling. Expert in layered cuts, bobs, and pixie cuts.',
      'experience': '6 years',
      'rating': 4.7,
      'services': [
        'Women\'s Haircut',
        'Layered Cut',
        'Bob Cut',
        'Pixie Cut',
        'Hair Styling',
      ],
    },
    {
      'name': 'Stylist 4',
      'specialty': 'Hair Treatment & Care',
      'description':
          'Certified hair care specialist focusing on treatments, scalp health, and hair restoration.',
      'experience': '4 years',
      'rating': 4.6,
      'services': [
        'Hair Treatment',
        'Scalp Treatment',
        'Hair Spa',
        'Deep Conditioning',
        'Hair Mask',
      ],
    },
    {
      'name': 'Stylist 5',
      'specialty': 'Hair Extensions',
      'description':
          'Expert in hair extensions and transformations. Specializes in tape-in, clip-in, and fusion methods.',
      'experience': '7 years',
      'rating': 4.9,
      'services': [
        'Hair Extensions',
        'Hair Transformations',
        'Hair Styling',
        'Hair Treatment',
      ],
    },
    {
      'name': 'Stylist 6',
      'specialty': 'Creative Styling',
      'description':
          'Creative stylist specializing in unique cuts, styling, and hair art. Perfect for those looking for bold transformations.',
      'experience': '3 years',
      'rating': 4.5,
      'services': [
        'Creative Haircut',
        'Hair Art',
        'Hair Styling',
        'Hair Coloring',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search stylists, services...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              final user = context.read<UserProvider>().currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UserProfileScreen(
                          fullName: user.fullName,
                          email: user.email,
                        ),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [Tab(text: 'Stylists'), Tab(text: 'Services')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStylistsTab(), _buildServicesTab()],
      ),
    );
  }

  Widget _buildStylistsTab() {
    final filteredItems =
        _searchQuery.isEmpty
            ? _stylists
            : _stylists
                .where(
                  (stylist) =>
                      stylist['name'].toLowerCase().contains(_searchQuery) ||
                      stylist['specialty'].toLowerCase().contains(_searchQuery),
                )
                .toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final stylist = filteredItems[index];
        return Card(
          child: InkWell(
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
                        imageUrl: stylist['image'] ?? '',
                      ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stylist['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stylist['specialty'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
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
            subtitle: Text(
              hasSubServices
                  ? 'Tap to view options'
                  : 'Service description goes here',
            ),
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
}
