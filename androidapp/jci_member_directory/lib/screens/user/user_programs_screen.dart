import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'dart:convert';

class UserProgramsScreen extends StatefulWidget {
  const UserProgramsScreen({Key? key}) : super(key: key);

  @override
  _UserProgramsScreenState createState() => _UserProgramsScreenState();
}

class _UserProgramsScreenState extends State<UserProgramsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _upcomingPrograms = [];
  List<dynamic> _expiredPrograms = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPrograms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== Loading Programs ===');
      final token = await AuthService.getAccessToken();
      print(
          'Auth Token retrieved: ${token != null ? 'Token exists' : 'No token'}');

      final response = await ApiService.get(
        endpoint: 'api/programs/',
        token: token,
      );

      print('\n=== User Programs API Response ===');
      print('Status: ${response['status']}');
      print('Message: ${response['message']}');
      print('\nComplete Response Data:');
      print(json.encode(response));

      // Handle the response data
      List<dynamic> programsList = [];
      try {
        if (response is Map<String, dynamic> && response['programs'] is List) {
          print('Response contains programs array');
          programsList = List<dynamic>.from(response['programs']);
          print('Successfully extracted ${programsList.length} programs');
        } else {
          print('Unexpected response format');
        }
      } catch (e) {
        print('Error processing response: $e');
      }

      print('\nPrograms List Length: ${programsList.length}');
      print('\nProgram Details:');
      for (var program in programsList) {
        print('\nProgram ID: ${program['id']}');
        print('UID: ${program['uid']}');
        print('Program Name: ${program['programName']}');
        print('Year: ${program['year']}');
        print('Start Date: ${program['prog_start_date']}');
        print('Expire Date: ${program['prog_expire_date']}');
        print('Program Image: ${program['prog_image']}');
        print('----------------------------------------');
      }

      print('Successfully loaded programs data');
      setState(() {
        final now = DateTime.now();
        // Set time to start of day for accurate date comparison
        final today = DateTime(now.year, now.month, now.day);
        print('\nCategorizing programs...');

        // Sort all programs by start date in ascending order
        programsList.sort((a, b) {
          DateTime dateA;
          DateTime dateB;

          try {
            dateA = a['prog_start_date'] != null
                ? DateTime.parse(a['prog_start_date'])
                : (a['prog_expire_date'] != null
                    ? DateTime.parse(a['prog_expire_date'])
                    : DateTime(1900));
          } catch (e) {
            print('Error parsing date A: $e');
            dateA = DateTime(1900);
          }

          try {
            dateB = b['prog_start_date'] != null
                ? DateTime.parse(b['prog_start_date'])
                : (b['prog_expire_date'] != null
                    ? DateTime.parse(b['prog_expire_date'])
                    : DateTime(1900));
          } catch (e) {
            print('Error parsing date B: $e');
            dateB = DateTime(1900);
          }

          return dateA.compareTo(dateB);
        });

        // Split into upcoming and expired based on end date
        _upcomingPrograms = programsList.where((program) {
          DateTime? endDate;

          if (program['prog_expire_date'] != null) {
            try {
              endDate = DateTime.parse(program['prog_expire_date']);
            } catch (e) {
              print(
                  'Error parsing end date for program ${program['programName']}: $e');
            }
          } else if (program['prog_start_date'] != null) {
            try {
              endDate = DateTime.parse(program['prog_start_date']);
            } catch (e) {
              print(
                  'Error parsing start date for program ${program['programName']}: $e');
            }
          }

          if (endDate == null) {
            print(
                'Program ${program['programName']} has no dates - moving to expired');
            return false;
          }

          final programEndDate =
              DateTime(endDate.year, endDate.month, endDate.day);
          final isUpcoming = programEndDate.isAfter(today) ||
              programEndDate.isAtSameMomentAs(today);
          print(
              'Program ${program['programName']} - End Date: $programEndDate, Is Upcoming: $isUpcoming');
          return isUpcoming;
        }).toList();

        _expiredPrograms = programsList.where((program) {
          DateTime? endDate;

          if (program['prog_expire_date'] != null) {
            try {
              endDate = DateTime.parse(program['prog_expire_date']);
            } catch (e) {
              print(
                  'Error parsing end date for program ${program['programName']}: $e');
            }
          } else if (program['prog_start_date'] != null) {
            try {
              endDate = DateTime.parse(program['prog_start_date']);
            } catch (e) {
              print(
                  'Error parsing start date for program ${program['programName']}: $e');
            }
          }

          if (endDate == null) {
            print(
                'Program ${program['programName']} has no dates - adding to expired');
            return true;
          }

          final programEndDate =
              DateTime(endDate.year, endDate.month, endDate.day);
          final isExpired = programEndDate.isBefore(today);
          print(
              'Program ${program['programName']} - End Date: $programEndDate, Is Expired: $isExpired');
          return isExpired;
        }).toList();

        print('\nCategorization Results:');
        print('Upcoming Programs: ${_upcomingPrograms.length}');
        print('Expired Programs: ${_expiredPrograms.length}');
      });
    } catch (e) {
      print('Error loading programs: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading programs: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('=== Programs Loading Completed ===\n');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upcoming Events',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'Upcoming Programs',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Tab(
              child: Text(
                'Past Programs',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProgramList(_upcomingPrograms),
                _buildProgramList(_expiredPrograms),
              ],
            ),
    );
  }

  Widget _buildProgramList(List<dynamic> programs) {
    print('\nBuilding program list with ${programs.length} programs');
    if (programs.isEmpty) {
      print('No programs to display');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Programs Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPrograms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];
          print('Building list item for program: ${program['programName']}');
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                _showProgramDetails(context, program);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program Image
                    GestureDetector(
                      onTap: () {
                        if (program['prog_image'] != null) {
                          _showImagePopup(context, program['prog_image']);
                        }
                      },
                      child: Container(
                        width: 160,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: program['prog_image'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  '${ApiConfig.baseUrl}/${program['prog_image']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    return Icon(
                                      Icons.image_not_supported,
                                      size: 32,
                                      color: Colors.grey[400],
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.image,
                                size: 32,
                                color: Colors.grey[400],
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Program Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program['programName'] ?? 'Untitled Program',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (program['prog_start_date'] != null) ...[
                            Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Prog Date: ${_formatDate(program['prog_start_date'])}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (program['prog_expire_date'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.stop,
                                    size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'End: ${_formatDate(program['prog_expire_date'])}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  void _showProgramDetails(BuildContext context, Map<String, dynamic> program) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Program Image with Aspect Ratio
                if (program['prog_image'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        '${ApiConfig.baseUrl}/${program['prog_image']}',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // Program Name
                Text(
                  program['programName'] ?? 'Untitled Program',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Program Dates
                if (program['prog_start_date'] != null) ...[
                  _buildDetailRow(
                      'Start Date', _formatDate(program['prog_start_date'])),
                  const SizedBox(height: 8),
                ],
                if (program['prog_expire_date'] != null) ...[
                  _buildDetailRow(
                      'End Date', _formatDate(program['prog_expire_date'])),
                  const SizedBox(height: 8),
                ],
                if (program['year'] != null) ...[
                  _buildDetailRow('Year', program['year']),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                // Close Button
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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

  void _showImagePopup(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Close button
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Image
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${ApiConfig.baseUrl}/$imagePath',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error');
                      return Container(
                        width: 300,
                        height: 300,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
