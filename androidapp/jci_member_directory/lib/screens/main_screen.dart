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
import 'package:jci_member_directory/screens/member_list_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'user/user_programs_screen.dart';

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
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  List<Map<String, dynamic>> _carouselItems = [];

  // Sample quick action buttons
  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.people, 'label': 'Members', 'color': Colors.blue},
    {
      'icon': Icons.event,
      'label': 'Upcoming Events',
      'color': Colors.green,
      'onTap': (context) => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const UserProgramsScreen()))
    },
    {
      'icon': Icons.photo_library,
      'label': 'Gallery',
      'color': Colors.orange,
      'onTap': (context) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const UserProgramImagesScreen()))
    },
    {'icon': Icons.message, 'label': 'Greetings', 'color': Colors.purple},
    {'icon': Icons.contact_phone, 'label': 'Contact', 'color': Colors.red},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _requestPermissions();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterMembers);
    _searchController.dispose();
    super.dispose();
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = List.from(_members)
          ..sort((a, b) {
            String nameA = (a['jcName'] ?? '').toString().trim().toLowerCase();
            String nameB = (b['jcName'] ?? '').toString().trim().toLowerCase();
            return nameA.compareTo(nameB);
          });
      } else {
        // Special case for LGB filter (showing all members except general/new members)
        if (query == 'lgb') {
          _filteredMembers = _members.where((member) {
            final position = member['jcpost']?.toString().toLowerCase() ?? '';
            return !position.contains('general member') &&
                !position.contains('new member');
          }).toList()
            ..sort((a, b) {
              String nameA =
                  (a['jcName'] ?? '').toString().trim().toLowerCase();
              String nameB =
                  (b['jcName'] ?? '').toString().trim().toLowerCase();
              return nameA.compareTo(nameB);
            });
        }
        // Special case for EB members (PP, IPP, President, Secretary, Treasurer)
        else if (query == 'eb') {
          _filteredMembers = _members.where((member) {
            final position = member['jcpost']?.toString().toLowerCase() ?? '';
            return position.contains('pp') ||
                position.contains('ipp') ||
                position.contains('president') ||
                position.contains('secretary') ||
                position.contains('treasurer');
          }).toList()
            ..sort((a, b) {
              String nameA =
                  (a['jcName'] ?? '').toString().trim().toLowerCase();
              String nameB =
                  (b['jcName'] ?? '').toString().trim().toLowerCase();
              return nameA.compareTo(nameB);
            });
        }
        // Show all members
        else if (query == 'all') {
          _filteredMembers = List.from(_members)
            ..sort((a, b) {
              String nameA =
                  (a['jcName'] ?? '').toString().trim().toLowerCase();
              String nameB =
                  (b['jcName'] ?? '').toString().trim().toLowerCase();
              return nameA.compareTo(nameB);
            });
        }
        // Regular search across all fields
        else {
          _filteredMembers = _members.where((member) {
            // Search in all relevant fields
            final name = member['jcName']?.toString().toLowerCase() ?? '';
            final position = member['jcpost']?.toString().toLowerCase() ?? '';
            final email = member['jcEmail']?.toString().toLowerCase() ?? '';
            final phone =
                member['jcMobile']?['phone_number']?.toString().toLowerCase() ??
                    '';
            final bloodGroup =
                member['jcBloodGroup']?.toString().toLowerCase() ?? '';
            final qualification =
                member['jcQualification']?.toString().toLowerCase() ?? '';
            final occupation =
                member['jcOccupation']?.toString().toLowerCase() ?? '';
            final firmName =
                member['jcFirmName']?.toString().toLowerCase() ?? '';
            final address =
                member['jcHomeAddress']?.toString().toLowerCase() ?? '';

            // Search in JCRT fields if available
            final jcrtName = member['jcrtName']?.toString().toLowerCase() ?? '';
            final jcrtPosition =
                member['jcrtpost']?.toString().toLowerCase() ?? '';
            final jcrtEmail =
                member['jcrtEmail']?.toString().toLowerCase() ?? '';
            final jcrtPhone = member['jcrtMobile']?['phone_number']
                    ?.toString()
                    .toLowerCase() ??
                '';

            return name.contains(query) ||
                position.contains(query) ||
                email.contains(query) ||
                phone.contains(query) ||
                bloodGroup.contains(query) ||
                qualification.contains(query) ||
                occupation.contains(query) ||
                firmName.contains(query) ||
                address.contains(query) ||
                jcrtName.contains(query) ||
                jcrtPosition.contains(query) ||
                jcrtEmail.contains(query) ||
                jcrtPhone.contains(query);
          }).toList()
            ..sort((a, b) {
              String nameA =
                  (a['jcName'] ?? '').toString().trim().toLowerCase();
              String nameB =
                  (b['jcName'] ?? '').toString().trim().toLowerCase();
              return nameA.compareTo(nameB);
            });
        }
      }
    });
  }

  // Add helper method to show filter options
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Members',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.people),
                title: Text(
                  'LGB Members (Except General/New Members)',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  _searchController.text = 'lgb';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: Text(
                  'All Members',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  _searchController.text = 'all';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(
                  'EB Members (PP, IPP, President, Secretary, Treasurer)',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  _searchController.text = 'eb';
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clear),
                title: Text(
                  'Clear Filter',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  _searchController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadInitialData() async {
    print('Loading initial data...');
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
          // Extract members data from the response
          _members = response['members'] ?? [];
          _filteredMembers = _members;

          // Extract program images for carousel
          if (response['programs'] != null) {
            _carouselItems = (response['programs'] as List).map((program) {
              return {
                'image': program['prog_image'] != null
                    ? '${ApiConfig.baseUrl}${program['prog_image']}'
                    : 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1471&q=80',
                'title': program['prog_name'] ?? 'Program',
                'description':
                    program['prog_description'] ?? 'No description available',
                'prog_date': program['prog_date'],
                'prog_time': program['prog_time'],
                'prog_venue': program['prog_venue'],
                'prog_organizer': program['prog_organizer'],
                'prog_contact': program['prog_contact'],
                'prog_id': program['id'],
                'prog_status': program['prog_status'],
                'prog_type': program['prog_type'],
                'prog_category': program['prog_category'],
                'prog_target_audience': program['prog_target_audience'],
                'prog_objectives': program['prog_objectives'],
                'prog_outcomes': program['prog_outcomes'],
                'prog_budget': program['prog_budget'],
                'prog_sponsors': program['prog_sponsors'],
                'prog_partners': program['prog_partners'],
                'prog_created_at': program['created_at'],
                'prog_updated_at': program['updated_at'],
              };
            }).toList();
          }

          // If no programs found, use default carousel items
          if (_carouselItems.isEmpty) {
            _carouselItems = [
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
          }

          // Print detailed members data
          print('=== Members Data from Profile Response ===');
          print('Total members: ${_members.length}');
          for (var i = 0; i < _members.length; i++) {
            final member = _members[i];
            print('\nMember ${i + 1}:');
            print('JC Name: ${member['jcName']}');
            print('JC Position: ${member['jcpost'] ?? 'General Member'}');
            print('JC Image: ${member['jcImage']}');
            print('JC Mobile: ${member['jcMobile']?['phone_number']}');
            print('JC Email: ${member['jcEmail']}');
            print('JC Address: ${member['jcHomeAddress']}');
            print('JC Occupation: ${member['jcOccupation']}');
            print('JC Firm: ${member['jcFirmName']}');
            print('JC Qualification: ${member['jcQualification']}');
            print('JC Blood Group: ${member['jcBloodGroup']}');

            if (member['jcrtName']?.isNotEmpty == true) {
              print('\nJCRT Details:');
              print('JCRT Name: ${member['jcrtName']}');
              print('JCRT Position: ${member['jcrtpost'] ?? 'General Member'}');
              print('JCRT Image: ${member['jcrtImage']}');
              print('JCRT Mobile: ${member['jcrtMobile']?['phone_number']}');
              print('JCRT Email: ${member['jcrtEmail']}');
              print('JCRT Occupation: ${member['jcrtOccupation']}');
              print('JCRT Blood Group: ${member['jcrtBloodGroup']}');
            }
            print('----------------------------------------');
          }
          print('=== End of Members Data ===');
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

  Future<void> _launchWhatsApp(String? phoneNumber) async {
    print('\n=== WhatsApp Launch Process Started ===');
    print('Original phone number: $phoneNumber');

    if (phoneNumber == null || phoneNumber.isEmpty) {
      print('Error: Phone number is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    String cleanNumber = '';
    try {
      // Clean the phone number - only remove non-digits
      cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      print('After removing non-digits: $cleanNumber');

      // Remove leading '0' if present
      if (cleanNumber.startsWith('0')) {
        cleanNumber = cleanNumber.substring(1);
        print('After removing leading 0: $cleanNumber');
      }

      // Try WhatsApp Business first
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'whatsapp://send?phone=$cleanNumber',
          package: 'com.whatsapp.w4b',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );

        print('Attempting to launch WhatsApp Business');
        await intent.launch();
        print('Successfully launched WhatsApp Business');
        return;
      } catch (businessError) {
        print('WhatsApp Business not available, trying regular WhatsApp');
      }

      // Try regular WhatsApp
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'whatsapp://send?phone=$cleanNumber',
          package: 'com.whatsapp',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );

        print('Attempting to launch regular WhatsApp');
        await intent.launch();
        print('Successfully launched regular WhatsApp');
        return;
      } catch (regularError) {
        print('Regular WhatsApp not available, trying web URL');
      }

      // Fallback to web URL if both apps fail
      final Uri webUrl =
          Uri.parse('https://api.whatsapp.com/send?phone=$cleanNumber');
      print('Attempting to launch WhatsApp via web URL: $webUrl');

      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('Successfully launched WhatsApp via web URL');
        return;
      }

      throw Exception('Could not launch WhatsApp through any method');
    } catch (e) {
      print('Error launching WhatsApp: $e');
      print('Error stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('=== WhatsApp Launch Process Ended ===\n');
  }

  Future<void> _launchPhoneCall(String? phoneNumber) async {
    print('\n=== Phone Call Launch Process Started ===');
    print('Original phone number: $phoneNumber');

    if (phoneNumber == null || phoneNumber.isEmpty) {
      print('Error: Phone number is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Request phone call permission first
    final status = await Permission.phone.request();
    print('Phone permission status: $status');

    if (status.isDenied) {
      print('Phone permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone call permission is required to make calls'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Clean the phone number - only remove non-digits
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      print('After removing non-digits: $cleanNumber');

      // Create Android Intent for phone call
      final intent = AndroidIntent(
        action: 'android.intent.action.CALL',
        data: 'tel:$cleanNumber',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      print('Attempting to launch phone call with number: $cleanNumber');
      await intent.launch();
      print('Successfully launched phone call intent');
    } catch (e) {
      print('Error launching phone call: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('=== Phone Call Launch Process Ended ===\n');
  }

  Widget _buildWhatsAppIcon() {
    return Image.asset(
      'assets/media/logo/whatsup.png',
      width: 24,
      height: 24,
    );
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
                Text(
                  '${_filteredMembers.length} Members',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MemberListScreen(),
                  ),
                );
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
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgramDetailsScreen(
                              program: item,
                            ),
                          ),
                        );
                      },
                      child: Container(
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
                    child: GestureDetector(
                      onTap: _showFilterOptions,
                      child: const Icon(Icons.filter_list),
                    ),
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
                itemCount: _filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = _filteredMembers[index];
                  print('Building member tile for: ${member['jcName']}');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: member['jcImage'] != null
                            ? NetworkImage(
                                '${ApiConfig.baseUrl}${member['jcImage']}')
                            : null,
                        child: member['jcImage'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        member['jcName'] != null
                            ? member['jcName']
                                .toString()
                                .split(' ')
                                .map((word) => word.isNotEmpty
                                    ? word[0].toUpperCase() +
                                        word.substring(1).toLowerCase()
                                    : '')
                                .join(' ')
                            : 'N/A',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['jcpost'] ?? 'General Member',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (member['jcMobile']?['phone_number'] != null)
                            Text(
                              member['jcMobile']?['phone_number'] ?? '',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (member['jcMobile']?['phone_number'] != null)
                            IconButton(
                              icon: _buildWhatsAppIcon(),
                              onPressed: () => _launchWhatsApp(
                                  member['jcMobile']?['phone_number']),
                              tooltip: 'Open WhatsApp',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.phone),
                            onPressed: () {
                              print(
                                  'Phone button pressed for: ${member['jcName']}');
                              _launchPhoneCall(
                                  member['jcMobile']?['phone_number']);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        print('Member tile tapped: ${member['jcName']}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MemberDetailsScreen(
                              member: member,
                            ),
                          ),
                        );
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

  Future<void> _refreshData() async {
    print('Refreshing data...'); // Debug print
    await _loadProfileData();
    print('Refresh complete'); // Debug print
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

class ProgramDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> program;

  const ProgramDetailsScreen({
    Key? key,
    required this.program,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Program Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program Image
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(program['image']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program Title
                  Text(
                    program['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Program Status
                  if (program['prog_status'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(program['prog_status'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        program['prog_status'].toString().toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _getStatusColor(program['prog_status']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Program Description
                  Text(
                    program['description'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Basic Information Section
                  _buildSectionHeader('Basic Information'),
                  if (program['prog_date'] != null) ...[
                    _buildDetailRow('Date', program['prog_date']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_time'] != null) ...[
                    _buildDetailRow('Time', program['prog_time']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_venue'] != null) ...[
                    _buildDetailRow('Venue', program['prog_venue']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_type'] != null) ...[
                    _buildDetailRow('Type', program['prog_type']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_category'] != null) ...[
                    _buildDetailRow('Category', program['prog_category']),
                    const SizedBox(height: 12),
                  ],
                  // Organizer Information Section
                  _buildSectionHeader('Organizer Information'),
                  if (program['prog_organizer'] != null) ...[
                    _buildDetailRow('Organizer', program['prog_organizer']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_contact'] != null) ...[
                    _buildDetailRow('Contact', program['prog_contact']),
                    const SizedBox(height: 12),
                  ],
                  // Program Details Section
                  _buildSectionHeader('Program Details'),
                  if (program['prog_target_audience'] != null) ...[
                    _buildDetailRow(
                        'Target Audience', program['prog_target_audience']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_objectives'] != null) ...[
                    _buildDetailRow('Objectives', program['prog_objectives']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_outcomes'] != null) ...[
                    _buildDetailRow(
                        'Expected Outcomes', program['prog_outcomes']),
                    const SizedBox(height: 12),
                  ],
                  // Financial Information Section
                  _buildSectionHeader('Financial Information'),
                  if (program['prog_budget'] != null) ...[
                    _buildDetailRow('Budget', program['prog_budget']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_sponsors'] != null) ...[
                    _buildDetailRow('Sponsors', program['prog_sponsors']),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_partners'] != null) ...[
                    _buildDetailRow('Partners', program['prog_partners']),
                    const SizedBox(height: 12),
                  ],
                  // Additional Information Section
                  _buildSectionHeader('Additional Information'),
                  if (program['prog_created_at'] != null) ...[
                    _buildDetailRow(
                        'Created', _formatDate(program['prog_created_at'])),
                    const SizedBox(height: 12),
                  ],
                  if (program['prog_updated_at'] != null) ...[
                    _buildDetailRow('Last Updated',
                        _formatDate(program['prog_updated_at'])),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}
