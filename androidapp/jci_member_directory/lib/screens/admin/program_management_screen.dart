import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ProgramManagementScreen extends StatefulWidget {
  const ProgramManagementScreen({Key? key}) : super(key: key);

  @override
  _ProgramManagementScreenState createState() =>
      _ProgramManagementScreenState();
}

class _ProgramManagementScreenState extends State<ProgramManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _upcomingPrograms = [];
  List<dynamic> _expiredPrograms = [];
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  String? _selectedImageData;

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
        endpoint: 'api/admin/programs/',
        token: token,
      );

      print('\n=== Program Management API Response ===');
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
            // If start date not available, use end date or default to old date
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
            // If start date not available, use end date or default to old date
            dateB = b['prog_start_date'] != null
                ? DateTime.parse(b['prog_start_date'])
                : (b['prog_expire_date'] != null
                    ? DateTime.parse(b['prog_expire_date'])
                    : DateTime(1900));
          } catch (e) {
            print('Error parsing date B: $e');
            dateB = DateTime(1900);
          }

          // Sort in ascending order (earliest first)
          return dateA.compareTo(dateB);
        });

        print('\nSorted Programs by Start Date:');
        for (var program in programsList) {
          final startDate = program['prog_start_date'] != null
              ? _formatDate(program['prog_start_date'])
              : 'No Start Date';
          final endDate = program['prog_expire_date'] != null
              ? _formatDate(program['prog_expire_date'])
              : 'No End Date';
          print('${program['programName']} - Start: $startDate, End: $endDate');
        }

        // Split into upcoming and expired based on end date
        _upcomingPrograms = programsList.where((program) {
          DateTime? endDate;

          // Determine end date based on available dates
          if (program['prog_expire_date'] != null) {
            try {
              endDate = DateTime.parse(program['prog_expire_date']);
            } catch (e) {
              print(
                  'Error parsing end date for program ${program['programName']}: $e');
            }
          } else if (program['prog_start_date'] != null) {
            try {
              // If no end date, use start date as end date
              endDate = DateTime.parse(program['prog_start_date']);
            } catch (e) {
              print(
                  'Error parsing start date for program ${program['programName']}: $e');
            }
          }

          // If no dates available, move to expired
          if (endDate == null) {
            print(
                'Program ${program['programName']} has no dates - moving to expired');
            return false;
          }

          // Set time to start of day for accurate date comparison
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

          // Determine end date based on available dates
          if (program['prog_expire_date'] != null) {
            try {
              endDate = DateTime.parse(program['prog_expire_date']);
            } catch (e) {
              print(
                  'Error parsing end date for program ${program['programName']}: $e');
            }
          } else if (program['prog_start_date'] != null) {
            try {
              // If no end date, use start date as end date
              endDate = DateTime.parse(program['prog_start_date']);
            } catch (e) {
              print(
                  'Error parsing start date for program ${program['programName']}: $e');
            }
          }

          // If no dates available, move to expired
          if (endDate == null) {
            print(
                'Program ${program['programName']} has no dates - adding to expired');
            return true;
          }

          // Set time to start of day for accurate date comparison
          final programEndDate =
              DateTime(endDate.year, endDate.month, endDate.day);
          final isExpired = programEndDate.isBefore(today);
          print(
              'Program ${program['programName']} - End Date: $programEndDate, Is Expired: $isExpired');
          return isExpired;
        }).toList();

        // Sort upcoming programs by start date in ascending order
        _upcomingPrograms.sort((a, b) {
          DateTime dateA;
          DateTime dateB;

          try {
            dateA = a['prog_start_date'] != null
                ? DateTime.parse(a['prog_start_date'])
                : DateTime.parse(a['prog_expire_date'] ?? '1900-01-01');
          } catch (e) {
            dateA = DateTime(1900);
          }

          try {
            dateB = b['prog_start_date'] != null
                ? DateTime.parse(b['prog_start_date'])
                : DateTime.parse(b['prog_expire_date'] ?? '1900-01-01');
          } catch (e) {
            dateB = DateTime(1900);
          }

          return dateA.compareTo(dateB);
        });

        // Sort expired programs by end date in ascending order
        _expiredPrograms.sort((a, b) {
          DateTime dateA;
          DateTime dateB;

          try {
            dateA = a['prog_expire_date'] != null
                ? DateTime.parse(a['prog_expire_date'])
                : (a['prog_start_date'] != null
                    ? DateTime.parse(a['prog_start_date'])
                    : DateTime(1900));
          } catch (e) {
            dateA = DateTime(1900);
          }

          try {
            dateB = b['prog_expire_date'] != null
                ? DateTime.parse(b['prog_expire_date'])
                : (b['prog_start_date'] != null
                    ? DateTime.parse(b['prog_start_date'])
                    : DateTime(1900));
          } catch (e) {
            dateB = DateTime(1900);
          }

          return dateA.compareTo(dateB);
        });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Program Management',
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
                'Expired Programs',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProgramDialog(context);
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Program',
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
                _showEditProgramDialog(context, program);
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  program['programName'] ?? 'Untitled Program',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showEditProgramDialog(context, program);
                                },
                                tooltip: 'Edit Program',
                              ),
                            ],
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

  void _showEditProgramDialog(
      BuildContext context, Map<String, dynamic> program) {
    final TextEditingController nameController =
        TextEditingController(text: program['programName']);
    final TextEditingController startDateController = TextEditingController(
        text: _formatDateForInput(program['prog_start_date']));
    final TextEditingController endDateController = TextEditingController(
        text: _formatDateForInput(program['prog_expire_date']));
    String? currentImage = program['prog_image'];
    String? selectedImagePath;
    String? selectedImageData;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> pickImage() async {
              try {
                final cameraStatus = await Permission.camera.request();
                if (cameraStatus.isDenied) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Camera permission is required to take photos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                final source = await showModalBottomSheet<ImageSource>(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Wrap(
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Take Photo'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from Gallery'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.gallery),
                          ),
                        ],
                      ),
                    );
                  },
                );

                if (source == null) return;

                final XFile? image = await _picker.pickImage(
                  source: source,
                  imageQuality: 70,
                  maxWidth: 1000,
                  maxHeight: 1000,
                );

                if (image != null) {
                  final bytes = await image.readAsBytes();
                  final base64Image = base64Encode(bytes);
                  final imageData = 'data:image/jpeg;base64,$base64Image';

                  setDialogState(() {
                    selectedImagePath = image.path;
                    selectedImageData = imageData;
                  });
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to pick image: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                'Edit Program',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Program Image with Change Button
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: selectedImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(selectedImagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Icon(
                                        Icons.image_not_supported,
                                        size: 48,
                                        color: Colors.grey[400],
                                      );
                                    },
                                  ),
                                )
                              : currentImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        '${ApiConfig.baseUrl}/$currentImage',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          print('Error loading image: $error');
                                          return Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: Colors.grey[400],
                                          );
                                        },
                                      ),
                                    )
                                  : Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: Icon(Icons.edit),
                            label: Text('Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.9),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Program Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Program Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Start Date
                    TextField(
                      controller: startDateController,
                      decoration: InputDecoration(
                        labelText: 'Start Date (DD-MM-YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          startDateController.text =
                              _formatDateForInput(picked.toString());
                        }
                      },
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    // End Date
                    TextField(
                      controller: endDateController,
                      decoration: InputDecoration(
                        labelText: 'End Date (DD-MM-YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.stop),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          endDateController.text =
                              _formatDateForInput(picked.toString());
                        }
                      },
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      print('\n=== Updating Program ===');
                      print('Program ID: ${program['id']}');
                      print('Current Data: ${json.encode(program)}');

                      // Convert dates back to YYYY-MM-DD format for API
                      final startDate =
                          _convertToApiDateFormat(startDateController.text);
                      final endDate =
                          _convertToApiDateFormat(endDateController.text);

                      // Validate dates
                      if (startDate.isNotEmpty && endDate.isNotEmpty) {
                        final start = DateTime.parse(startDate);
                        final end = DateTime.parse(endDate);
                        if (end.isBefore(start)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('End date cannot be before start date'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      }

                      print('\n=== Program Update Response ===');
                      print('Request Body:');
                      print(json.encode({
                        'program_id': program['id'],
                        'programName': nameController.text.toUpperCase(),
                        'year':
                            program['year'] ?? DateTime.now().year.toString(),
                        'prog_start_date': startDate,
                        'prog_expire_date': endDate,
                        'image': selectedImageData != null
                            ? 'Image Data Present'
                            : 'Empty String',
                        'change_image': selectedImageData != null,
                      }));

                      final token = await AuthService.getAccessToken();
                      final response = await ApiService.post(
                        endpoint: 'api/admin/members/programs/update/',
                        body: {
                          'program_id': program['id'],
                          'programName': nameController.text.toUpperCase(),
                          'year':
                              program['year'] ?? DateTime.now().year.toString(),
                          'prog_start_date': startDate,
                          'prog_expire_date': endDate,
                          'image': selectedImageData ??
                              "", // Only send new image data or empty string
                          'change_image': selectedImageData != null,
                        },
                        token: token,
                      );

                      print('\nResponse Data:');
                      print('Status: ${response['status']}');
                      print('Message: ${response['message']}');
                      print('Full Response:');
                      print(json.encode(response));
                      print('=== End Program Update Response ===\n');

                      if (response['status'] == 200) {
                        print('Program updated successfully');
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        await _loadPrograms(); // Reload the list
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Program updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        print('Failed to update program');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response['message'] ??
                                'Failed to update program'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error updating program: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Update',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddProgramDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    String? selectedImagePath;
    String? selectedImageData;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> pickImage() async {
              try {
                final cameraStatus = await Permission.camera.request();
                if (cameraStatus.isDenied) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Camera permission is required to take photos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                final source = await showModalBottomSheet<ImageSource>(
                  context: context,
                  builder: (BuildContext context) {
                    return SafeArea(
                      child: Wrap(
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Take Photo'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Choose from Gallery'),
                            onTap: () =>
                                Navigator.pop(context, ImageSource.gallery),
                          ),
                        ],
                      ),
                    );
                  },
                );

                if (source == null) return;

                final XFile? image = await _picker.pickImage(
                  source: source,
                  imageQuality: 70,
                  maxWidth: 1000,
                  maxHeight: 1000,
                );

                if (image != null) {
                  final bytes = await image.readAsBytes();
                  final base64Image = base64Encode(bytes);
                  final imageData = 'data:image/jpeg;base64,$base64Image';

                  setDialogState(() {
                    selectedImagePath = image.path;
                    selectedImageData = imageData;
                  });
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to pick image: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                'Add New Program',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Program Image with Change Button
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: selectedImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(selectedImagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading image: $error');
                                      return Icon(
                                        Icons.image_not_supported,
                                        size: 48,
                                        color: Colors.grey[400],
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: Icon(Icons.edit),
                            label: Text('Add Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.9),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Program Name
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Program Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Start Date
                    TextField(
                      controller: startDateController,
                      decoration: InputDecoration(
                        labelText: 'Start Date (DD-MM-YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          startDateController.text =
                              _formatDateForInput(picked.toString());
                        }
                      },
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    // End Date
                    TextField(
                      controller: endDateController,
                      decoration: InputDecoration(
                        labelText: 'End Date (DD-MM-YYYY)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.stop),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          endDateController.text =
                              _formatDateForInput(picked.toString());
                        }
                      },
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      print('\n=== Adding New Program ===');

                      // Validate required fields
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Program name is required'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Convert dates back to YYYY-MM-DD format for API
                      final startDate =
                          _convertToApiDateFormat(startDateController.text);
                      final endDate =
                          _convertToApiDateFormat(endDateController.text);

                      // Validate dates
                      if (startDate.isNotEmpty && endDate.isNotEmpty) {
                        final start = DateTime.parse(startDate);
                        final end = DateTime.parse(endDate);
                        if (end.isBefore(start)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('End date cannot be before start date'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                      }

                      print('Request Body:');
                      print(json.encode({
                        'programName': nameController.text.toUpperCase(),
                        'year': DateTime.now().year.toString(),
                        'prog_start_date': startDate,
                        'prog_expire_date': endDate,
                        'image': selectedImageData != null
                            ? 'Image Data Present'
                            : 'Empty String',
                      }));

                      final token = await AuthService.getAccessToken();
                      final response = await ApiService.post(
                        endpoint: 'api/admin/members/programs/add/',
                        body: {
                          'programName': nameController.text.toUpperCase(),
                          'year': DateTime.now().year.toString(),
                          'prog_start_date': startDate,
                          'prog_expire_date': endDate,
                          'image': selectedImageData ?? "",
                        },
                        token: token,
                      );

                      print('\nResponse Data:');
                      print('Status: ${response['status']}');
                      print('Message: ${response['message']}');
                      print('Full Response:');
                      print(json.encode(response));
                      print('=== End Add Program Response ===\n');

                      if (response['status'] == 200) {
                        print('Program added successfully');
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        await _loadPrograms(); // Reload the list
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Program added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        print('Failed to add program');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                response['message'] ?? 'Failed to add program'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error adding program: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to format date for input field (DD-MM-YYYY)
  String _formatDateForInput(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      print('Error formatting date for input: $e');
      return dateStr;
    }
  }

  // Helper method to convert date back to API format (YYYY-MM-DD)
  String _convertToApiDateFormat(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      return dateStr;
    } catch (e) {
      print('Error converting date format: $e');
      return dateStr;
    }
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
