import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/jci_logo.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import 'main_screen.dart';
import 'manage_members_screen.dart';
import 'program_images_screen.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import 'member_list_screen.dart';

class AdminMemberListScreen extends StatefulWidget {
  final List<dynamic> members;

  const AdminMemberListScreen({
    Key? key,
    required this.members,
  }) : super(key: key);

  @override
  _AdminMemberListScreenState createState() => _AdminMemberListScreenState();
}

class _AdminMemberListScreenState extends State<AdminMemberListScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _filteredMembers = [];

  @override
  void initState() {
    super.initState();
    _filteredMembers = widget.members;
  }

  void _filterMembers(String query) {
    setState(() {
      _filteredMembers = widget.members.where((member) {
        final name = member['jcName']?.toString().toLowerCase() ?? '';
        final position = member['jcpost']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || position.contains(searchQuery);
      }).toList();
    });
  }

  void _showMemberDetails(dynamic member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with image and name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: member['jcImage'] != null
                          ? NetworkImage(
                              '${ApiConfig.baseUrl}${member['jcImage']}')
                          : null,
                      child: member['jcImage'] == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['jcName'] ?? 'N/A',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member['jcpost'] ?? 'General Member',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // JC Details Section
                Text(
                  'JC Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Email', member['jcEmail'] ?? 'N/A'),
                _buildDetailRow(
                    'Phone', member['jcMobile']?['phone_number'] ?? 'N/A'),
                _buildDetailRow('Blood Group', member['jcBloodGroup'] ?? 'N/A'),
                _buildDetailRow(
                    'Qualification', member['jcQualification'] ?? 'N/A'),
                _buildDetailRow('Occupation', member['jcOccupation'] ?? 'N/A'),
                _buildDetailRow('Firm Name', member['jcFirmName'] ?? 'N/A'),
                _buildDetailRow('Address', member['jcHomeAddress'] ?? 'N/A'),
                _buildDetailRow('Occupation Address',
                    member['jcOccupationAddress'] ?? 'N/A'),
                _buildDetailRow('Date of Birth', member['jcDob'] ?? 'N/A'),

                if (member['jcrtName']?.isNotEmpty == true) ...[
                  const SizedBox(height: 24),
                  // JCRT Details Section
                  Text(
                    'JCRT Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Name', member['jcrtName'] ?? 'N/A'),
                  _buildDetailRow('Email', member['jcrtEmail'] ?? 'N/A'),
                  _buildDetailRow(
                      'Phone', member['jcrtMobile']?['phone_number'] ?? 'N/A'),
                  _buildDetailRow(
                      'Blood Group', member['jcrtBloodGroup'] ?? 'N/A'),
                  _buildDetailRow(
                      'Occupation', member['jcrtOccupation'] ?? 'N/A'),
                  _buildDetailRow('Occupation Address',
                      member['jcrtOccupationAddress'] ?? 'N/A'),
                  _buildDetailRow('Date of Birth', member['jcrtDob'] ?? 'N/A'),
                  _buildDetailRow('Position', member['jcrtpost'] ?? 'N/A'),
                ],

                const SizedBox(height: 24),
                // Anniversary Date
                _buildDetailRow(
                    'Anniversary Date', member['anniversaryDate'] ?? 'N/A'),

                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Navigate to edit member screen
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
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
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Member List',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageMembersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
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
              onChanged: _filterMembers,
            ),
          ),
          // Member List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredMembers.length,
              itemBuilder: (context, index) {
                final member = _filteredMembers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 24,
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
                      member['jcName'] ?? 'N/A',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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
                        ),
                        if (member['jcEmail']?.isNotEmpty == true)
                          Text(
                            member['jcEmail'],
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            // TODO: Navigate to edit member screen
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            // TODO: Show delete confirmation dialog
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminMemberDetailsScreen(
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
    );
  }
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _adminData;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== Loading Admin Dashboard Data ===');
      print('1. Starting to load admin data...');

      final token = await AuthService.getAccessToken();
      print(
          '2. Auth Token retrieved: ${token != null ? 'Token exists' : 'No token'}');

      print('3. Making API call to dashboard endpoint...');
      final response = await ApiService.get(
        endpoint: 'api/admin/dashboard/',
        token: token,
      );

      print('4. API Response received:');
      print('   Status: ${response['status']}');
      print('   Has data: ${response['data'] != null}');
      print('   Has members: ${response['data']?['members'] != null}');

      if (response['status'] == 200) {
        print('5. Successfully loaded admin data');
        setState(() {
          _adminData = response;
          // Count total members from members array
          if (_adminData != null && _adminData!['members'] != null) {
            final membersCount = (_adminData!['members'] as List).length;
            _adminData!['total_members'] = membersCount.toString();
            print('6. Member Statistics:');
            print('   - Total Members: $membersCount');
            print(
                '   - Members Array Length: ${(_adminData!['members'] as List).length}');

            // Count active members
            final activeMembers = (_adminData!['members'] as List)
                .where((member) => member['is_deleted'] == false)
                .length;
            print('   - Active Members: $activeMembers');

            // Count members with profile images
            final membersWithImages = (_adminData!['members'] as List)
                .where((member) =>
                    member['jcImage'] != null || member['jcrtImage'] != null)
                .length;
            print('   - Members with Profile Images: $membersWithImages');
          } else {
            print('6. No members data available');
            print('   Response structure: ${json.encode(response)}');
          }
        });
      } else {
        print('5. Failed to load admin data: ${response['message']}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load admin data'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('=== Admin Dashboard Data Loading Completed ===\n');
    } catch (e) {
      print('Error loading admin data: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load admin data: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('7. Loading state set to false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAdminData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const JCILogo(
                        size: 120,
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.all(8.0),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Welcome to Admin Panel',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Admin Dashboard Cards
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildDashboardCard(
                            title: 'Total Members',
                            value: _adminData?['members'] != null
                                ? (_adminData!['members'] as List)
                                    .length
                                    .toString()
                                : '0',
                            icon: Icons.people,
                            color: Colors.blue,
                          ),
                          _buildDashboardCard(
                            title: 'Active Members',
                            value: _adminData?['active_members']?.toString() ??
                                '0',
                            icon: Icons.person,
                            color: Colors.green,
                          ),
                          _buildDashboardCard(
                            title: 'Pending Approvals',
                            value:
                                _adminData?['pending_approvals']?.toString() ??
                                    '0',
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          ),
                          _buildDashboardCard(
                            title: 'Total Chapters',
                            value: _adminData?['total_chapters']?.toString() ??
                                '0',
                            icon: Icons.business,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Quick Actions
                      Text(
                        'Quick Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        title: 'Manage Members',
                        icon: Icons.people,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageMembersScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        title: 'Program Images',
                        icon: Icons.business,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProgramImagesScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        title: 'View Reports',
                        icon: Icons.assessment,
                        onTap: () {
                          // TODO: Navigate to reports
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GestureDetector(
      onTap: title == 'Total Members'
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminMemberListScreen(
                    members: _adminData?['members'] ?? [],
                  ),
                ),
              );
            }
          : null,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminMemberDetailsScreen extends StatefulWidget {
  final dynamic member;

  const AdminMemberDetailsScreen({
    Key? key,
    required this.member,
  }) : super(key: key);

  @override
  _AdminMemberDetailsScreenState createState() =>
      _AdminMemberDetailsScreenState();
}

class _AdminMemberDetailsScreenState extends State<AdminMemberDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Member Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'JC Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Tab(
              child: Text(
                'JCRT Details',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit member screen
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // JC Details Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image and Name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: widget.member['jcImage'] != null
                            ? NetworkImage(
                                '${ApiConfig.baseUrl}${widget.member['jcImage']}')
                            : null,
                        child: widget.member['jcImage'] == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.member['jcName'] ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.member['jcpost'] ?? 'General Member',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // JC Details
                _buildDetailRow('Email', widget.member['jcEmail'] ?? 'N/A'),
                _buildDetailRow('Phone',
                    widget.member['jcMobile']?['phone_number'] ?? 'N/A'),
                _buildDetailRow(
                    'Blood Group', widget.member['jcBloodGroup'] ?? 'N/A'),
                _buildDetailRow(
                    'Qualification', widget.member['jcQualification'] ?? 'N/A'),
                _buildDetailRow(
                    'Occupation', widget.member['jcOccupation'] ?? 'N/A'),
                _buildDetailRow(
                    'Firm Name', widget.member['jcFirmName'] ?? 'N/A'),
                _buildDetailRow(
                    'Address', widget.member['jcHomeAddress'] ?? 'N/A'),
                _buildDetailRow('Occupation Address',
                    widget.member['jcOccupationAddress'] ?? 'N/A'),
                _buildDetailRow(
                    'Date of Birth', widget.member['jcDob'] ?? 'N/A'),
                _buildDetailRow('Anniversary Date',
                    widget.member['anniversaryDate'] ?? 'N/A'),
              ],
            ),
          ),
          // JCRT Details Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: widget.member['jcrtName']?.isNotEmpty == true
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image and Name
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: widget.member['jcrtImage'] !=
                                      null
                                  ? NetworkImage(
                                      '${ApiConfig.baseUrl}${widget.member['jcrtImage']}')
                                  : null,
                              child: widget.member['jcrtImage'] == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.member['jcrtName'] ?? 'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.member['jcrtpost'] ?? 'General Member',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // JCRT Details
                      _buildDetailRow(
                          'Email', widget.member['jcrtEmail'] ?? 'N/A'),
                      _buildDetailRow(
                          'Phone',
                          widget.member['jcrtMobile']?['phone_number'] ??
                              'N/A'),
                      _buildDetailRow('Blood Group',
                          widget.member['jcrtBloodGroup'] ?? 'N/A'),
                      _buildDetailRow('Occupation',
                          widget.member['jcrtOccupation'] ?? 'N/A'),
                      _buildDetailRow('Occupation Address',
                          widget.member['jcrtOccupationAddress'] ?? 'N/A'),
                      _buildDetailRow(
                          'Date of Birth', widget.member['jcrtDob'] ?? 'N/A'),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No JCRT Details Available',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
