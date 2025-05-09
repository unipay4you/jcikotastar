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
import 'admin/edit_member_screen.dart';

class AdminMemberListScreen extends StatefulWidget {
  const AdminMemberListScreen({
    Key? key,
  }) : super(key: key);

  @override
  _AdminMemberListScreenState createState() => _AdminMemberListScreenState();
}

class _AdminMemberListScreenState extends State<AdminMemberListScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  bool _showActiveOnly = true;
  bool _isLoading = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== Loading Members List ===');
      final token = await AuthService.getAccessToken();
      print(
          'Auth Token retrieved: ${token != null ? 'Token exists' : 'No token'}');

      final response = await ApiService.get(
        endpoint: 'api/admin/members/list/',
        token: token,
      );

      print('API Response:');
      print('Status: ${response['status']}');
      print('Has members: ${response['members'] != null}');
      print('Response structure: ${json.encode(response)}');

      if (response['status'] == 200) {
        print('Successfully loaded members data');
        setState(() {
          _profile = response['profile'];
          _members = response['members'] ?? [];
          // Apply initial filter for active members
          _filteredMembers = _members
              .where((member) => !(member['is_deleted'] ?? false))
              .toList();
          print('Total members: ${_members.length}');
          print('Active members: ${_filteredMembers.length}');
        });
      } else {
        print('Failed to load members data');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load members'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error loading members: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading members: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('=== Members List Loading Completed ===\n');
    }
  }

  void _toggleFilter() {
    setState(() {
      _showActiveOnly = !_showActiveOnly;
      if (_showActiveOnly) {
        _filteredMembers =
            _members.where((member) => member['is_active'] == true).toList();
      } else {
        _filteredMembers = _members;
      }
      // Reapply search filter if there's any search text
      if (_searchController.text.isNotEmpty) {
        _filterMembers(_searchController.text);
      }
    });
  }

  void _filterMembers(String query) {
    setState(() {
      final baseList = _showActiveOnly
          ? _members.where((member) => member['is_active'] == true).toList()
          : _members;

      _filteredMembers = baseList.where((member) {
        final searchQuery = query.toLowerCase();

        // Search in all relevant fields
        final name = member['jcName']?.toString().toLowerCase() ?? '';
        final position = member['jcpost']?.toString().toLowerCase() ?? '';
        final email = member['jcEmail']?.toString().toLowerCase() ?? '';
        final phone =
            member['jcMobile']?['phone_number']?.toString().toLowerCase() ?? '';
        final bloodGroup =
            member['jcBloodGroup']?.toString().toLowerCase() ?? '';
        final qualification =
            member['jcQualification']?.toString().toLowerCase() ?? '';
        final occupation =
            member['jcOccupation']?.toString().toLowerCase() ?? '';
        final firmName = member['jcFirmName']?.toString().toLowerCase() ?? '';
        final address = member['jcHomeAddress']?.toString().toLowerCase() ?? '';

        // Search in JCRT fields if available
        final jcrtName = member['jcrtName']?.toString().toLowerCase() ?? '';
        final jcrtPosition = member['jcrtpost']?.toString().toLowerCase() ?? '';
        final jcrtEmail = member['jcrtEmail']?.toString().toLowerCase() ?? '';
        final jcrtPhone =
            member['jcrtMobile']?['phone_number']?.toString().toLowerCase() ??
                '';

        return name.contains(searchQuery) ||
            position.contains(searchQuery) ||
            email.contains(searchQuery) ||
            phone.contains(searchQuery) ||
            bloodGroup.contains(searchQuery) ||
            qualification.contains(searchQuery) ||
            occupation.contains(searchQuery) ||
            firmName.contains(searchQuery) ||
            address.contains(searchQuery) ||
            jcrtName.contains(searchQuery) ||
            jcrtPosition.contains(searchQuery) ||
            jcrtEmail.contains(searchQuery) ||
            jcrtPhone.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate counts
    final totalMembers = _members.length;
    final activeMembers =
        _members.where((member) => member['is_active'] == true).length;
    final displayedMembers = _filteredMembers.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member List',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _showActiveOnly
                  ? '$activeMembers Active Members'
                  : '$totalMembers Total Members',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _showActiveOnly ? Colors.green : Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.filter_list : Icons.filter_list_off,
              color: _showActiveOnly ? Colors.blue : Colors.grey,
            ),
            onPressed: _toggleFilter,
            tooltip: _showActiveOnly
                ? 'Show All Members'
                : 'Show Active Members Only',
          ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMembers,
              child: Column(
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: ListView.builder(
                        key: ValueKey<bool>(_showActiveOnly),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          return AnimatedSlide(
                            duration: const Duration(milliseconds: 300),
                            offset: Offset.zero,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: 1.0,
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      minVerticalPadding: 12,
                                      leading: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.grey[200],
                                        backgroundImage: member['jcImage'] !=
                                                null
                                            ? NetworkImage(
                                                '${ApiConfig.baseUrl}${member['jcImage']}')
                                            : null,
                                        child: member['jcImage'] == null
                                            ? const Icon(Icons.person, size: 30)
                                            : null,
                                      ),
                                      title: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Text(
                                                    member['jcName'] ?? 'N/A',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  if (member['jcMobile']
                                                          ?['user_type'] ==
                                                      'admin')
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 8),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Text(
                                                        'Admin',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 4, bottom: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member['jcpost'] ??
                                                  'General Member',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                              ),
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  member['jcMobile']
                                                          ?['phone_number'] ??
                                                      'No Phone',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    member['jcMobile']?[
                                                                'user_type'] ==
                                                            'admin'
                                                        ? Icons
                                                            .admin_panel_settings_outlined
                                                        : Icons
                                                            .admin_panel_settings,
                                                    size: 20,
                                                    color: member['jcMobile']?[
                                                                'user_type'] ==
                                                            'admin'
                                                        ? Colors.red
                                                        : Colors.blue,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () async {
                                                    final bool isAdmin = member[
                                                                'jcMobile']
                                                            ?['user_type'] ==
                                                        'admin';

                                                    // Show confirmation dialog
                                                    final bool? confirm =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return AlertDialog(
                                                          title: Text(
                                                            isAdmin
                                                                ? 'Remove Admin'
                                                                : 'Make Admin',
                                                            style: GoogleFonts
                                                                .poppins(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                          ),
                                                          content: Text(
                                                            isAdmin
                                                                ? 'Are you sure you want to remove admin privileges from ${member['jcName']}?'
                                                                : 'Are you sure you want to make ${member['jcName']} an admin?',
                                                            style: GoogleFonts
                                                                .poppins(),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          false),
                                                              child: Text(
                                                                'Cancel',
                                                                style: GoogleFonts.poppins(
                                                                    color: Colors
                                                                            .grey[
                                                                        600]),
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          true),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    isAdmin
                                                                        ? Colors
                                                                            .red
                                                                        : Colors
                                                                            .blue,
                                                              ),
                                                              child: Text(
                                                                isAdmin
                                                                    ? 'Remove Admin'
                                                                    : 'Make Admin',
                                                                style: GoogleFonts
                                                                    .poppins(
                                                                        color: Colors
                                                                            .white),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );

                                                    if (confirm != true) return;

                                                    try {
                                                      print(
                                                          '\n=== ${isAdmin ? "Removing" : "Making"} Member Admin ===');
                                                      print(
                                                          'Member ID: ${member['id']}');
                                                      print(
                                                          'Member Name: ${member['jcName']}');
                                                      print(
                                                          'Current Status: ${isAdmin ? "Admin" : "Not Admin"}');

                                                      final token =
                                                          await AuthService
                                                              .getAccessToken();
                                                      final response =
                                                          await ApiService.post(
                                                        endpoint:
                                                            'api/admin/members/make-admin/',
                                                        body: {
                                                          'member_id':
                                                              member['id'],
                                                          'is_admin':
                                                              !isAdmin, // Send the new desired state
                                                        },
                                                        token: token,
                                                      );

                                                      print('API Response:');
                                                      print(
                                                          'Status: ${response['status']}');
                                                      print(
                                                          'Message: ${response['message']}');

                                                      if (response['status'] ==
                                                          200) {
                                                        print(
                                                            'Admin status updated successfully');
                                                        await _loadMembers(); // Reload the list
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(isAdmin
                                                                ? 'Admin privileges removed from ${member['jcName']}'
                                                                : '${member['jcName']} is now an admin'),
                                                            backgroundColor:
                                                                isAdmin
                                                                    ? Colors
                                                                        .orange
                                                                    : Colors
                                                                        .green,
                                                          ),
                                                        );
                                                      } else {
                                                        print(
                                                            'Failed to update admin status');
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(response[
                                                                    'message'] ??
                                                                'Failed to update admin status'),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      print(
                                                          'Error updating admin status: $e');
                                                      if (!mounted) return;
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                              'Error: ${e.toString()}'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                    print(
                                                        '=== Admin Status Update Completed ===\n');
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminMemberDetailsScreen(
                                              member: member,
                                            ),
                                          ),
                                        ).then((result) {
                                          if (result == true) {
                                            _loadMembers(); // Reload members when returning from details
                                          }
                                        });
                                      },
                                    ),
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 16, bottom: 8, top: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          // Post Update Dropdown with Label
                                          Row(
                                            children: [
                                              Text(
                                                'New Post:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                width: 150,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.grey[300]!),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: DropdownButton<String>(
                                                  value: _getValidPostValue(
                                                      member['jcpost']),
                                                  underline: const SizedBox(),
                                                  isDense: true,
                                                  isExpanded: true,
                                                  items: const [
                                                    'General Member',
                                                    'LGB Member',
                                                    'President',
                                                    'Vice President',
                                                    'Secretary',
                                                    'Treasurer',
                                                    'Director',
                                                    'Chairman',
                                                    'Vice Chairman',
                                                    'Executive Member',
                                                  ].map((String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(
                                                        value,
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged:
                                                      (String? newValue) async {
                                                    if (newValue != null) {
                                                      // Show confirmation dialog
                                                      final bool? confirm =
                                                          await showDialog<
                                                              bool>(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                              'Update Member Post',
                                                              style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600),
                                                            ),
                                                            content: Text(
                                                              'Are you sure you want to change the post to "$newValue"?',
                                                              style: GoogleFonts
                                                                  .poppins(),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            false),
                                                                child: Text(
                                                                  'Cancel',
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                          color:
                                                                              Colors.grey[600]),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            true),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                                child: Text(
                                                                  'Update',
                                                                  style: GoogleFonts
                                                                      .poppins(
                                                                          color:
                                                                              Colors.white),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );

                                                      if (confirm != true)
                                                        return;

                                                      try {
                                                        print(
                                                            '\n=== Updating Member Post ===');
                                                        print(
                                                            'Member ID: ${member['id']}');
                                                        print(
                                                            'Current Post: ${member['jcpost']}');
                                                        print(
                                                            'New Post: $newValue');

                                                        final token =
                                                            await AuthService
                                                                .getAccessToken();
                                                        final response =
                                                            await ApiService
                                                                .post(
                                                          endpoint:
                                                              'api/admin/members/update-post/',
                                                          body: {
                                                            'member_id':
                                                                member['id'],
                                                            'new_post':
                                                                newValue,
                                                          },
                                                          token: token,
                                                        );

                                                        print('API Response:');
                                                        print(
                                                            'Status: ${response['status']}');
                                                        print(
                                                            'Message: ${response['message']}');

                                                        if (response[
                                                                'status'] ==
                                                            200) {
                                                          print(
                                                              'Post updated successfully');
                                                          await _loadMembers(); // Reload the list
                                                          if (!mounted) return;
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  'Post updated to $newValue'),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );
                                                        } else {
                                                          print(
                                                              'Failed to update post');
                                                          if (!mounted) return;

                                                          // Check for unauthorized message
                                                          if (response[
                                                                      'message']
                                                                  ?.toString()
                                                                  .contains(
                                                                      'You are not authorized to access this page') ==
                                                              true) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                    'Session expired. Please login again.'),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                            // Navigate to main screen
                                                            Navigator
                                                                .pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const MainScreen(),
                                                              ),
                                                              (route) => false,
                                                            );
                                                            return;
                                                          }

                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(response[
                                                                      'message'] ??
                                                                  'Failed to update post'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        print(
                                                            'Error updating post: $e');
                                                        if (!mounted) return;
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Error: ${e.toString()}'),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                      print(
                                                          '=== Post Update Completed ===\n');
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              print(
                                                  '\n=== Navigating to Edit Member Screen ===');
                                              print(
                                                  'Member ID: ${member['id']}');
                                              print(
                                                  'Member Name: ${member['jcName']}');
                                              print(
                                                  'Member Data: ${json.encode(member)}');

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      EditMemberScreen(
                                                    member: member,
                                                  ),
                                                ),
                                              ).then((result) {
                                                print(
                                                    '\n=== Edit Member Screen Result ===');
                                                print('Result: $result');
                                                if (result == true) {
                                                  print(
                                                      'Reloading members list...');
                                                  _loadMembers(); // Reload members after successful edit
                                                }
                                                print(
                                                    '=== Edit Member Screen Result End ===\n');
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Switch(
                                            value: member['is_active'] == true,
                                            onChanged: (value) {
                                              _toggleMemberStatus(
                                                  member, value);
                                            },
                                            activeColor: Colors.green,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _toggleMemberStatus(dynamic member, bool newStatus) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            newStatus ? 'Activate Member' : 'Deactivate Member',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            newStatus
                ? 'Are you sure you want to activate this member?'
                : 'Are you sure you want to deactivate this member?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? Colors.green : Colors.red,
              ),
              child: Text(
                newStatus ? 'Activate' : 'Deactivate',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      print('\n=== Toggling Member Status ===');
      print('Member ID: ${member['id']}');
      print('Current Status: ${member['is_active']}');
      print('New Status: ${newStatus ? 'Active' : 'Inactive'}');

      final token = await AuthService.getAccessToken();
      final response = await ApiService.post(
        endpoint: 'api/admin/members/change-status/',
        body: {
          'member_id': member['id'],
        },
        token: token,
      );

      print('API Response:');
      print('Status: ${response['status']}');
      print('Message: ${response['message']}');

      if (response['status'] == 200) {
        print('Status updated successfully');
        await _loadMembers(); // Reload the entire list
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? 'Member activated successfully'
                : 'Member deactivated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Failed to update status');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating member status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    print('=== Member Status Toggle Completed ===\n');
  }

  String _getValidPostValue(dynamic currentPost) {
    const validPosts = [
      'General Member',
      'LGB Member',
      'President',
      'Vice President',
      'Secretary',
      'Treasurer',
      'Director',
      'Chairman',
      'Vice Chairman',
      'Executive Member',
    ];

    if (currentPost == null || currentPost.toString().isEmpty) {
      return 'General Member';
    }

    final post = currentPost.toString();
    return validPosts.contains(post) ? post : 'General Member';
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
                  builder: (context) => AdminMemberListScreen(),
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
            onPressed: () async {
              print('\n=== Navigating to Edit Member Screen from Details ===');
              print('Member ID: ${widget.member['id']}');
              print('Member Name: ${widget.member['jcName']}');
              print('Member Data: ${json.encode(widget.member)}');

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMemberScreen(
                    member: widget.member,
                  ),
                ),
              );

              print('\n=== Edit Member Screen Result from Details ===');
              print('Result: $result');
              if (result == true) {
                print('Returning to member list with refresh flag');
                // Return true to refresh the member list
                Navigator.pop(context, true);
              }
              print('=== Edit Member Screen Result from Details End ===\n');
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

                // Personal Information Section
                _buildSectionHeader('Personal Information'),
                _buildDetailRow(
                    'Post', widget.member['jcpost'] ?? 'General Member'),
                _buildDetailRow('Email', widget.member['jcEmail'] ?? 'N/A'),
                _buildDetailRow('Phone',
                    widget.member['jcMobile']?['phone_number'] ?? 'N/A'),
                _buildDetailRow(
                    'Blood Group', widget.member['jcBloodGroup'] ?? 'N/A'),
                _buildDetailRow(
                    'Date of Birth', widget.member['jcDob'] ?? 'N/A'),
                _buildDetailRow('Anniversary Date',
                    widget.member['anniversaryDate'] ?? 'N/A'),

                const SizedBox(height: 24),
                // Professional Information Section
                _buildSectionHeader('Professional Information'),
                _buildDetailRow(
                    'Qualification', widget.member['jcQualification'] ?? 'N/A'),
                _buildDetailRow(
                    'Occupation', widget.member['jcOccupation'] ?? 'N/A'),
                _buildDetailRow(
                    'Firm Name', widget.member['jcFirmName'] ?? 'N/A'),
                _buildDetailRow('Occupation Address',
                    widget.member['jcOccupationAddress'] ?? 'N/A'),

                const SizedBox(height: 24),
                // Address Information Section
                _buildSectionHeader('Address Information'),
                _buildDetailRow(
                    'Home Address', widget.member['jcHomeAddress'] ?? 'N/A'),
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

                      // Personal Information Section
                      _buildSectionHeader('Personal Information',
                          color: Colors.pink),
                      _buildDetailRow('Post',
                          widget.member['jcrtpost'] ?? 'General Member'),
                      _buildDetailRow(
                          'Email', widget.member['jcrtEmail'] ?? 'N/A'),
                      _buildDetailRow(
                          'Phone',
                          widget.member['jcrtMobile']?['phone_number'] ??
                              'N/A'),
                      _buildDetailRow('Blood Group',
                          widget.member['jcrtBloodGroup'] ?? 'N/A'),
                      _buildDetailRow(
                          'Date of Birth', widget.member['jcrtDob'] ?? 'N/A'),

                      const SizedBox(height: 24),
                      // Professional Information Section
                      _buildSectionHeader('Professional Information',
                          color: Colors.pink),
                      _buildDetailRow('Occupation',
                          widget.member['jcrtOccupation'] ?? 'N/A'),
                      _buildDetailRow('Occupation Address',
                          widget.member['jcrtOccupationAddress'] ?? 'N/A'),
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

  Widget _buildSectionHeader(String title, {Color color = Colors.blue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
