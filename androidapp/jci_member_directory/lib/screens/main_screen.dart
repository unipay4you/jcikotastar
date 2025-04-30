import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'login_screen.dart';
import 'member_details_screen.dart';
import 'admin_panel_screen.dart';
import 'profile_update_screen.dart';
import 'photo_gallery_screen.dart';
import '../widgets/jci_logo.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/permission_service.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:jci_member_directory/screens/user_program_images_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _storage = const FlutterSecureStorage();
  String _userType = '';
  final _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _userData;
  int _currentCarouselIndex = 0;

  // Sample carousel items (replace with your actual data)
  final List<Map<String, dynamic>> _carouselItems = [
    {
      'image':
          'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1471&q=80',
      'title': 'Welcome to JCI',
      'description': 'Join our community of young active citizens',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1552664730-d307ca884978?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
      'title': 'Leadership Development',
      'description': 'Grow your leadership skills with JCI',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1593113598332-cd288d649433?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80',
      'title': 'Community Service',
      'description': 'Make a difference in your community',
    },
  ];

  // Sample quick action buttons
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.people, 'label': 'Members', 'color': Colors.blue},
    {'icon': Icons.event, 'label': 'Events', 'color': Colors.green},
    {
      'icon': Icons.photo_library,
      'label': 'Gallery',
      'color': Colors.orange,
      'onTap': (context) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const UserProgramImagesScreen()))
    },
    {'icon': Icons.article, 'label': 'News', 'color': Colors.purple},
    {'icon': Icons.contact_phone, 'label': 'Contact', 'color': Colors.red},
  ];

  // Sample featured items
  final List<Map<String, dynamic>> _featuredItems = [
    {'title': 'Upcoming Events', 'icon': Icons.event, 'color': Colors.blue},
    {'title': 'Latest News', 'icon': Icons.article, 'color': Colors.green},
    {
      'title': 'Photo Gallery',
      'icon': Icons.photo_library,
      'color': Colors.orange
    },
    {
      'title': 'Achievements',
      'icon': Icons.emoji_events,
      'color': Colors.purple
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _requestPermissions();
  }

  Future<void> _loadInitialData() async {
    await _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await ApiService.get(
        endpoint: ApiConfig.profile,
        token: token,
      );

      print('Profile Response: $response'); // Debug print

      if (response['status'] == 200) {
        setState(() {
          _profileData = response['profile'];
          _userData = response['user'];
          _userType =
              response['profile']['user_type']?.toString().toUpperCase() ?? '';
        });
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (e) {
      print('Error loading profile: $e'); // Debug print
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile data: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    print('Refreshing data...'); // Debug print
    await _loadProfileData();
    print('Refresh complete'); // Debug print
  }

  Future<void> _requestPermissions() async {
    await PermissionService.requestAllPermissions();
  }

  Future<void> _handleLogout() async {
    try {
      // Clear all stored data
      await _storage.deleteAll();

      if (!mounted) return;
      // Navigate to login screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileUpdateScreen(
          profileData: _profileData,
          userData: _userData,
        ),
      ),
    );

    // Refresh profile data when returning from profile screen
    if (mounted) {
      await _loadProfileData();
    }
  }

  Future<void> _navigateToAdminPanel() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminPanelScreen(),
      ),
    );

    // Refresh profile data when returning from admin panel
    if (mounted) {
      await _loadProfileData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _profileData?['user_name']?.toString() ?? '';
    final userType = _profileData?['user_type']?.toString().toUpperCase() ?? '';
    final userProfileImage = _profileData?['user_profile_image'];
    final phoneNumber = _profileData?['phone_number']?.toString() ?? '';

    // Prepare profile image URL
    String? profileImageUrl;
    if (userProfileImage != null) {
      String imagePath = userProfileImage.toString();
      // Remove file:/// prefix if present
      if (imagePath.startsWith('file:///')) {
        imagePath = imagePath.replaceFirst('file:///', '');
      }
      // Remove leading slash if present
      if (imagePath.startsWith('/')) {
        imagePath = imagePath.substring(1);
      }
      // Add base URL if not already a full URL
      profileImageUrl = imagePath.startsWith('http')
          ? imagePath
          : '${ApiConfig.baseUrl}$imagePath';
      print('Profile Image URL: $profileImageUrl');
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                Text(
                  _profileData?['mobile_number_belongs_to']
                              ?.toString()
                              .toLowerCase() ==
                          'jcrt'
                      ? 'Lady JC '
                      : 'JC ',
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    userName
                        .split(' ')
                        .map((word) => word.isNotEmpty
                            ? word[0].toUpperCase() + word.substring(1)
                            : '')
                        .join(' '),
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: profileImageUrl != null
                        ? ClipOval(
                            child: Image.network(
                              profileImageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading profile image: $error');
                                print('Profile image URL: $profileImageUrl');
                                return const Icon(Icons.person,
                                    size: 40, color: Colors.blue);
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const CircularProgressIndicator();
                              },
                            ),
                          )
                        : const Icon(Icons.person,
                            size: 40, color: Colors.blue),
                  ),
                  const SizedBox(height: 4),
                  // Name and Type
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _profileData?['mobile_number_belongs_to']
                                        ?.toString()
                                        .toLowerCase() ==
                                    'jcrt'
                                ? 'Lady JC '
                                : 'JC ',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              userName
                                  .split(' ')
                                  .map((word) => word.isNotEmpty
                                      ? word[0].toUpperCase() +
                                          word.substring(1)
                                      : '')
                                  .join(' '),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        userType,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      if (phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          phoneNumber,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: Text(
                'Members',
                style: GoogleFonts.poppins(),
              ),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                'Profile',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.pop(context);
                _navigateToProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(
                'Settings',
                style: GoogleFonts.poppins(),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
              },
            ),
            if (userType.toLowerCase() == 'admin') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(
                  'Go to Admin Panel',
                  style: GoogleFonts.poppins(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAdminPanel();
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(
                'Logout',
                style: GoogleFonts.poppins(),
              ),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Carousel Slider
            FlutterCarousel(
              items: _carouselItems.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: NetworkImage(item['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item['description'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                viewportFraction: 0.8,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Quick Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _quickActions.map((action) {
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: action['onTap'] != null
                            ? () => action['onTap'](context)
                            : null,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: action['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action['icon'],
                            color: action['color'],
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['label'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Featured Items Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.5,
                ),
                itemCount: _featuredItems.length,
                itemBuilder: (context, index) {
                  final item = _featuredItems[index];
                  return GestureDetector(
                    onTap: () {
                      if (item['title'] == 'Photo Gallery') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const UserProgramImagesScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'],
                            color: item['color'],
                            size: 30,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item['title'],
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search members...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.filter_list),
                  ),
                ],
              ),
            ),

            // Member Tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 10, // Replace with actual member count
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[200],
                        child: const Icon(Icons.person),
                      ),
                      title: Text(
                        'Member Name ${index + 1}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Position ${index + 1}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () {
                          // Implement call functionality
                        },
                      ),
                      onTap: () {
                        // Navigate to member details
                      },
                    ),
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

class MemberDirectoryScreen extends StatelessWidget {
  const MemberDirectoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10, // Replace with actual member count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person),
            ),
            title: Text(
              'Member Name ${index + 1}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Position ${index + 1}',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () {
                // Implement call functionality
              },
            ),
            onTap: () {
              // Navigate to member details
            },
          ),
        );
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
          const SizedBox(height: 16),
          Text(
            'Your Name',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your Position',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          _buildProfileItem(Icons.email, 'your.email@example.com'),
          _buildProfileItem(Icons.phone, '+60 12-345-6789'),
          _buildProfileItem(Icons.location_on, 'Kota Star, Malaysia'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Implement edit profile
            },
            child: Text(
              'Edit Profile',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsItem(
          Icons.notifications,
          'Notifications',
          'Manage notification settings',
          () {
            // Navigate to notifications settings
          },
        ),
        _buildSettingsItem(
          Icons.lock,
          'Privacy',
          'Manage privacy settings',
          () {
            // Navigate to privacy settings
          },
        ),
        _buildSettingsItem(
          Icons.help,
          'Help & Support',
          'Get help and contact support',
          () {
            // Navigate to help & support
          },
        ),
        _buildSettingsItem(
          Icons.info,
          'About',
          'App information and version',
          () {
            // Navigate to about
          },
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            // Implement logout
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
