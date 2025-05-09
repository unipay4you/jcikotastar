import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:math' show min;

class EditMemberScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const EditMemberScreen({
    Key? key,
    required this.member,
  }) : super(key: key);

  @override
  _EditMemberScreenState createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _jcNameController = TextEditingController();
  final _jcMobileController = TextEditingController();
  final _jcrtNameController = TextEditingController();
  final _jcrtMobileController = TextEditingController();
  final _anniversaryDateController = TextEditingController();
  final _jcDobController = TextEditingController();
  final _jcrtDobController = TextEditingController();
  final _jcQualificationController = TextEditingController();
  final _jcBloodGroupController = TextEditingController();
  final _jcEmailController = TextEditingController();
  final _jcHomeAddressController = TextEditingController();
  final _jcOccupationController = TextEditingController();
  final _jcFirmNameController = TextEditingController();
  final _jcOccupationAddressController = TextEditingController();
  final _jcrtBloodGroupController = TextEditingController();
  final _jcrtEmailController = TextEditingController();
  final _jcrtOccupationController = TextEditingController();
  final _jcrtOccupationAddressController = TextEditingController();
  String? _selectedJCPost;
  String? _selectedJCRTPost;
  String? _selectedJCOccupation;
  String? _selectedJCRTOccupation;
  String? _jcImagePath;
  String? _jcrtImagePath;
  String? _jcImageData;
  String? _jcrtImageData;

  final List<String> _postOptions = [
    'President',
    'Vice President',
    'Chairperson',
    'Secretary',
    'Lady Secretary',
    'Treasurer',
    'LGB Member',
    'Past President',
    'IPP',
    'General Member',
  ];

  final List<String> _bloodGroupOptions = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _jcOccupationOptions = [
    'Business',
    'Service',
    'Profession',
    'Other',
  ];

  final List<String> _jcrtOccupationOptions = [
    'Business',
    'Service',
    'Profession',
    'House Wife',
    'Other',
  ];

  final ImagePicker _picker = ImagePicker();

  // Helper function to calculate date 18 years ago
  DateTime get _eighteenYearsAgo {
    final now = DateTime.now();
    return DateTime(now.year - 18, now.month, now.day);
  }

  // Helper function to calculate date 100 years ago
  DateTime get _hundredYearsAgo {
    final now = DateTime.now();
    return DateTime(now.year - 100, now.month, now.day);
  }

  // Helper function to parse date from string
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]), // year
        int.parse(parts[1]), // month
        int.parse(parts[0]), // day
      );
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  // Helper function to get initial date for picker
  DateTime _getInitialDate(String dateStr, DateTime defaultDate) {
    final parsedDate = _parseDate(dateStr);
    if (parsedDate != null) {
      if (parsedDate.isBefore(defaultDate)) {
        return parsedDate;
      }
    }
    return defaultDate;
  }

  Widget _buildProfileImage(String? imagePath, bool isJC) {
    if (imagePath == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo, size: 40),
          const SizedBox(height: 8),
          Text(
            isJC ? 'Add JC Photo' : 'Add JCRT Photo',
            style: GoogleFonts.poppins(),
          ),
        ],
      );
    }

    if (imagePath.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading ${isJC ? "JC" : "JCRT"} image: $error');
            return const Icon(Icons.error, size: 40);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const CircularProgressIndicator();
          },
        ),
      );
    }

    try {
      return ClipOval(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading ${isJC ? "JC" : "JCRT"} image: $error');
            return const Icon(Icons.error, size: 40);
          },
        ),
      );
    } catch (e) {
      print('Error displaying ${isJC ? "JC" : "JCRT"} image: $e');
      return const Icon(Icons.error, size: 40);
    }
  }

  String _formatDateInput(String input) {
    String digits = input.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length <= 2) {
      return digits;
    } else if (digits.length <= 4) {
      return '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else {
      return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4, min(8, digits.length))}';
    }
  }

  bool _isValidDate(String dateStr) {
    if (dateStr.isEmpty) return false;
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
        return false;
      }

      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (e) {
      return false;
    }
  }

  bool _isSameImage(String? path1, String? path2) {
    if (path1 == null || path2 == null) return false;

    String getFilename(String path) {
      if (path.startsWith('http')) {
        return path.split('/').last;
      } else if (path.startsWith('data:image')) {
        return path.split(',').last;
      } else {
        return path.split('/').last;
      }
    }

    String filename1 = getFilename(path1);
    String filename2 = getFilename(path2);

    return filename1 == filename2;
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final member = widget.member;

    _jcNameController.text = member['jcName'] ?? '';
    _jcrtNameController.text = member['jcrtName'] ?? '';

    // Set JC Post with validation
    String jcPost = member['jcpost'] ?? 'General Member';
    if (!_postOptions.contains(jcPost)) {
      jcPost = 'General Member';
    }
    _selectedJCPost = jcPost;

    // Set JCRT Post with validation
    String jcrtPost = member['jcrtpost'] ?? 'General Member';
    if (!_postOptions.contains(jcrtPost)) {
      jcrtPost = 'General Member';
    }
    _selectedJCRTPost = jcrtPost;

    // Format dates
    if (member['anniversaryDate'] != null) {
      final parts = member['anniversaryDate'].toString().split('-');
      if (parts.length == 3) {
        _anniversaryDateController.text = "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    }

    if (member['jcDob'] != null) {
      final parts = member['jcDob'].toString().split('-');
      if (parts.length == 3) {
        _jcDobController.text = "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    }

    if (member['jcrtDob'] != null) {
      final parts = member['jcrtDob'].toString().split('-');
      if (parts.length == 3) {
        _jcrtDobController.text = "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    }

    _jcQualificationController.text = member['jcQualification'] ?? '';

    // Set JC Blood Group with validation
    String jcBloodGroup = member['jcBloodGroup'] ?? '';
    if (!_bloodGroupOptions.contains(jcBloodGroup)) {
      jcBloodGroup = '';
    }
    _jcBloodGroupController.text = jcBloodGroup;

    _jcEmailController.text = member['jcEmail'] ?? '';
    _jcHomeAddressController.text = member['jcHomeAddress'] ?? '';

    if (member['jcMobile'] != null) {
      _jcMobileController.text =
          member['jcMobile']['phone_number']?.toString() ?? '';
    }
    if (member['jcrtMobile'] != null) {
      _jcrtMobileController.text =
          member['jcrtMobile']['phone_number']?.toString() ?? '';
    }

    // Set JC Occupation with validation
    String jcOccupation = member['jcOccupation'] ?? 'Business';
    if (!_jcOccupationOptions.contains(jcOccupation)) {
      jcOccupation = 'Business';
    }
    _selectedJCOccupation = jcOccupation;

    // Set JCRT Occupation with validation
    String jcrtOccupation = member['jcrtOccupation'] ?? 'Business';
    if (!_jcrtOccupationOptions.contains(jcrtOccupation)) {
      jcrtOccupation = 'Business';
    }
    _selectedJCRTOccupation = jcrtOccupation;

    _jcFirmNameController.text = member['jcFirmName'] ?? '';
    _jcOccupationAddressController.text = member['jcOccupationAddress'] ?? '';

    // Set JCRT Blood Group with validation
    String jcrtBloodGroup = member['jcrtBloodGroup'] ?? '';
    if (!_bloodGroupOptions.contains(jcrtBloodGroup)) {
      jcrtBloodGroup = '';
    }
    _jcrtBloodGroupController.text = jcrtBloodGroup;

    _jcrtEmailController.text = member['jcrtEmail'] ?? '';
    _jcrtOccupationAddressController.text =
        member['jcrtOccupationAddress'] ?? '';

    // Set image paths
    if (member['jcImage'] != null) {
      String imagePath = member['jcImage'].toString();
      if (imagePath.startsWith('file:///')) {
        imagePath = imagePath.replaceFirst('file:///', '');
      }
      if (imagePath.startsWith('/')) {
        imagePath = imagePath.substring(1);
      }
      _jcImagePath = imagePath.startsWith('http')
          ? imagePath
          : '${ApiConfig.baseUrl}$imagePath';
    }

    if (member['jcrtImage'] != null) {
      String imagePath = member['jcrtImage'].toString();
      if (imagePath.startsWith('file:///')) {
        imagePath = imagePath.replaceFirst('file:///', '');
      }
      if (imagePath.startsWith('/')) {
        imagePath = imagePath.substring(1);
      }
      _jcrtImagePath = imagePath.startsWith('http')
          ? imagePath
          : '${ApiConfig.baseUrl}$imagePath';
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('\n=== Edit Member Screen: Starting Update ===');
        print('Member ID: ${widget.member['id']}');
        print('Member Name: ${widget.member['jcName']}');

        final token = await AuthService.getAccessToken();
        if (token == null) {
          print('Error: Authentication token not found');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Authentication token not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        print('Auth Token retrieved successfully');

        String formatDate(String dateStr, String? existingDate) {
          if (dateStr.isEmpty) {
            if (existingDate != null && existingDate.isNotEmpty) {
              return existingDate;
            }
            return "1900-01-01";
          }
          try {
            final parts = dateStr.split('/');
            if (parts.length != 3) {
              if (existingDate != null && existingDate.isNotEmpty) {
                return existingDate;
              }
              return "1900-01-01";
            }

            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);

            if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
              if (existingDate != null && existingDate.isNotEmpty) {
                return existingDate;
              }
              return "1900-01-01";
            }

            return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
          } catch (e) {
            print('Error formatting date: $e');
            if (existingDate != null && existingDate.isNotEmpty) {
              return existingDate;
            }
            return "1900-01-01";
          }
        }

        // Handle images
        String? jcImageData;
        String? jcrtImageData;

        print('\nProcessing Images:');
        if (_jcImagePath != null) {
          print('JC Image Path: $_jcImagePath');
          if (!_isSameImage(_jcImagePath, widget.member['jcImage'])) {
            if (_jcImagePath!.startsWith('data:image')) {
              jcImageData = _jcImagePath!.split(',')[1];
              print('JC Image: Using base64 data from data URL');
            } else if (_jcImagePath!.startsWith('http')) {
              jcImageData = _jcImagePath;
              print('JC Image: Using URL');
            } else {
              try {
                final file = File(_jcImagePath!);
                final bytes = await file.readAsBytes();
                jcImageData = base64Encode(bytes);
                print('JC Image: Converted file to base64');
              } catch (e) {
                print('Error reading JC image file: $e');
              }
            }
          } else {
            jcImageData = "";
            print('JC Image: No changes');
          }
        } else {
          jcImageData = "";
          print('JC Image: No image provided');
        }

        if (_jcrtImagePath != null) {
          print('JCRT Image Path: $_jcrtImagePath');
          if (!_isSameImage(_jcrtImagePath, widget.member['jcrtImage'])) {
            if (_jcrtImagePath!.startsWith('data:image')) {
              jcrtImageData = _jcrtImagePath!.split(',')[1];
              print('JCRT Image: Using base64 data from data URL');
            } else if (_jcrtImagePath!.startsWith('http')) {
              jcrtImageData = _jcrtImagePath;
              print('JCRT Image: Using URL');
            } else {
              try {
                final file = File(_jcrtImagePath!);
                final bytes = await file.readAsBytes();
                jcrtImageData = base64Encode(bytes);
                print('JCRT Image: Converted file to base64');
              } catch (e) {
                print('Error reading JCRT image file: $e');
              }
            }
          } else {
            jcrtImageData = "";
            print('JCRT Image: No changes');
          }
        } else {
          jcrtImageData = "";
          print('JCRT Image: No image provided');
        }

        final requestBody = {
          "member_id": widget.member['id'],
          "jcName":
              _jcNameController.text.isEmpty ? "" : _jcNameController.text,
          "jcMobile":
              _jcMobileController.text.isEmpty ? "" : _jcMobileController.text,
          "jcrtName":
              _jcrtNameController.text.isEmpty ? "" : _jcrtNameController.text,
          "jcrtMobile": _jcrtMobileController.text.isEmpty
              ? ""
              : _jcrtMobileController.text,
          "jcpost": _selectedJCPost ?? "General Member",
          "jcrtpost": _selectedJCRTPost ?? "General Member",
          "anniversaryDate": formatDate(_anniversaryDateController.text,
              widget.member['anniversaryDate']),
          "jcDob": formatDate(_jcDobController.text, widget.member['jcDob']),
          "jcrtDob":
              formatDate(_jcrtDobController.text, widget.member['jcrtDob']),
          "jcQualification": _jcQualificationController.text.isEmpty
              ? ""
              : _jcQualificationController.text,
          "jcBloodGroup": _jcBloodGroupController.text.isEmpty
              ? ""
              : _jcBloodGroupController.text,
          "jcEmail":
              _jcEmailController.text.isEmpty ? "" : _jcEmailController.text,
          "jcHomeAddress": _jcHomeAddressController.text.isEmpty
              ? ""
              : _jcHomeAddressController.text,
          "jcOccupation": _selectedJCOccupation ?? "",
          "jcFirmName": _jcFirmNameController.text.isEmpty
              ? ""
              : _jcFirmNameController.text,
          "jcOccupationAddress": _jcOccupationAddressController.text.isEmpty
              ? ""
              : _jcOccupationAddressController.text,
          "jcrtBloodGroup": _jcrtBloodGroupController.text.isEmpty
              ? ""
              : _jcrtBloodGroupController.text,
          "jcrtEmail": _jcrtEmailController.text.isEmpty
              ? ""
              : _jcrtEmailController.text,
          "jcrtOccupation": _selectedJCRTOccupation ?? "",
          "jcrtOccupationAddress": _jcrtOccupationAddressController.text.isEmpty
              ? ""
              : _jcrtOccupationAddressController.text,
          "jcImage": jcImageData ?? "",
          "jcrtImage": jcrtImageData ?? "",
        };

        print('\nSending Update Request:');
        print('Request URL: ${ApiConfig.baseUrl}api/admin/members/update/');
        print('Request Body: ${json.encode(requestBody)}');

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}api/admin/members/update/'),
          headers: ApiConfig.getHeaders(token: token),
          body: json.encode(requestBody),
        );

        final responseData = json.decode(response.body);
        print('\nAPI Response:');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${json.encode(responseData)}');

        if (!mounted) return;

        if (response.statusCode == 200 && responseData['status'] == 200) {
          print('Update successful');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  responseData['message'] ?? 'Member updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          print('Update failed');
          String errorMessage =
              responseData['message'] ?? 'Something went wrong';
          if (responseData['status'] != null) {
            errorMessage = 'Error ${responseData['status']}: $errorMessage';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('\nError in _handleSubmit:');
        print('Error: $e');
        print('Stack trace: ${StackTrace.current}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update member: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        print('\n=== Edit Member Screen: Update Process Completed ===\n');
      }
    }
  }

  Future<void> _pickImage(bool isJC) async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to take photos'),
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
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
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

        setState(() {
          if (isJC) {
            _jcImagePath = image.path;
            _jcImageData = imageData;
          } else {
            _jcrtImagePath = image.path;
            _jcrtImageData = imageData;
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Member',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Member Information',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // JC Information Section
                      Text(
                        'JC Information',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JC Profile Picture
                      Center(
                        child: InkWell(
                          onTap: () => _pickImage(true),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: _buildProfileImage(_jcImagePath, true),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // JC Name
                      TextFormField(
                        controller: _jcNameController,
                        decoration: InputDecoration(
                          labelText: 'JC Name *',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter JC name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // JC Post
                      DropdownButtonFormField<String>(
                        value: _selectedJCPost,
                        decoration: InputDecoration(
                          labelText: 'JC Post *',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _postOptions.map((String post) {
                          return DropdownMenuItem<String>(
                            value: post,
                            child: Text(post),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedJCPost = newValue;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select JC post';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // JC Mobile
                      TextFormField(
                        controller: _jcMobileController,
                        keyboardType: TextInputType.phone,
                        readOnly: widget.member['jcMobile'] != null,
                        decoration: InputDecoration(
                          labelText: 'JC Mobile *',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: widget.member['jcMobile'] != null
                              ? 'Mobile number cannot be changed'
                              : null,
                          helperStyle: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter JC mobile number';
                          }
                          if (value.length < 10) {
                            return 'Please enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // JC Date of Birth
                      TextFormField(
                        controller: _jcDobController,
                        decoration: InputDecoration(
                          labelText: 'JC Date of Birth',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _getInitialDate(
                                    _jcDobController.text, _eighteenYearsAgo),
                                firstDate: _hundredYearsAgo,
                                lastDate: _eighteenYearsAgo,
                              );
                              if (picked != null) {
                                setState(() {
                                  _jcDobController.text =
                                      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                });
                              }
                            },
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _jcDobController.text = _formatDateInput(value);
                            _jcDobController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _jcDobController.text.length),
                            );
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter JC date of birth';
                          }
                          if (!_isValidDate(value)) {
                            return 'Please enter a valid date (DD/MM/YYYY)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // JC Email
                      TextFormField(
                        controller: _jcEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'JC Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JC Qualification
                      TextFormField(
                        controller: _jcQualificationController,
                        decoration: InputDecoration(
                          labelText: 'JC Qualification',
                          prefixIcon: const Icon(Icons.school),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JC Blood Group
                      DropdownButtonFormField<String>(
                        value: _jcBloodGroupController.text.isEmpty
                            ? null
                            : _jcBloodGroupController.text,
                        decoration: InputDecoration(
                          labelText: 'JC Blood Group',
                          prefixIcon: const Icon(Icons.bloodtype),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _bloodGroupOptions.map((String group) {
                          return DropdownMenuItem<String>(
                            value: group,
                            child: Text(group),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _jcBloodGroupController.text = newValue ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // JC Home Address
                      TextFormField(
                        controller: _jcHomeAddressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'JC Home Address',
                          prefixIcon: const Icon(Icons.home),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JC Occupation
                      DropdownButtonFormField<String>(
                        value: _selectedJCOccupation,
                        decoration: InputDecoration(
                          labelText: 'JC Occupation',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _jcOccupationOptions.map((String occupation) {
                          return DropdownMenuItem<String>(
                            value: occupation,
                            child: Text(occupation),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedJCOccupation = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // JC Firm Name
                      TextFormField(
                        controller: _jcFirmNameController,
                        decoration: InputDecoration(
                          labelText: 'JC Firm Name',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JC Occupation Address
                      TextFormField(
                        controller: _jcOccupationAddressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'JC Occupation Address',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // JCRT Information Section
                      Text(
                        'JCRT Information',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JCRT Profile Picture
                      Center(
                        child: InkWell(
                          onTap: () => _pickImage(false),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                            ),
                            child: _buildProfileImage(_jcrtImagePath, false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // JCRT Name
                      TextFormField(
                        controller: _jcrtNameController,
                        decoration: InputDecoration(
                          labelText: 'JCRT Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JCRT Post
                      DropdownButtonFormField<String>(
                        value: _selectedJCRTPost,
                        decoration: InputDecoration(
                          labelText: 'JCRT Post',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _postOptions.map((String post) {
                          return DropdownMenuItem<String>(
                            value: post,
                            child: Text(post),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedJCRTPost = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // JCRT Mobile
                      TextFormField(
                        controller: _jcrtMobileController,
                        keyboardType: TextInputType.phone,
                        readOnly: widget.member['jcrtMobile'] != null,
                        decoration: InputDecoration(
                          labelText: 'JCRT Mobile',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          helperText: widget.member['jcrtMobile'] != null
                              ? 'Mobile number cannot be changed'
                              : null,
                          helperStyle: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JCRT Date of Birth
                      TextFormField(
                        controller: _jcrtDobController,
                        decoration: InputDecoration(
                          labelText: 'JCRT Date of Birth',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _getInitialDate(
                                    _jcrtDobController.text, _eighteenYearsAgo),
                                firstDate: _hundredYearsAgo,
                                lastDate: _eighteenYearsAgo,
                              );
                              if (picked != null) {
                                setState(() {
                                  _jcrtDobController.text =
                                      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                });
                              }
                            },
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _jcrtDobController.text = _formatDateInput(value);
                            _jcrtDobController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _jcrtDobController.text.length),
                            );
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter JCRT date of birth';
                          }
                          if (!_isValidDate(value)) {
                            return 'Please enter a valid date (DD/MM/YYYY)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // JCRT Email
                      TextFormField(
                        controller: _jcrtEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'JCRT Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // JCRT Blood Group
                      DropdownButtonFormField<String>(
                        value: _jcrtBloodGroupController.text.isEmpty
                            ? null
                            : _jcrtBloodGroupController.text,
                        decoration: InputDecoration(
                          labelText: 'JCRT Blood Group',
                          prefixIcon: const Icon(Icons.bloodtype),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _bloodGroupOptions.map((String group) {
                          return DropdownMenuItem<String>(
                            value: group,
                            child: Text(group),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _jcrtBloodGroupController.text = newValue ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // JCRT Occupation
                      DropdownButtonFormField<String>(
                        value: _selectedJCRTOccupation,
                        decoration: InputDecoration(
                          labelText: 'JCRT Occupation',
                          prefixIcon: const Icon(Icons.work),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _jcrtOccupationOptions.map((String occupation) {
                          return DropdownMenuItem<String>(
                            value: occupation,
                            child: Text(occupation),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedJCRTOccupation = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // JCRT Occupation Address
                      TextFormField(
                        controller: _jcrtOccupationAddressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'JCRT Occupation Address',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Additional Information Section
                      Text(
                        'Additional Information',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Anniversary Date
                      TextFormField(
                        controller: _anniversaryDateController,
                        decoration: InputDecoration(
                          labelText: 'Anniversary Date',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? jcDob =
                                  _parseDate(_jcDobController.text);
                              DateTime? jcrtDob =
                                  _parseDate(_jcrtDobController.text);

                              DateTime? later18thBirthday;
                              if (jcDob != null && jcrtDob != null) {
                                final jc18thBirthday = DateTime(
                                    jcDob.year + 18, jcDob.month, jcDob.day);
                                final jcrt18thBirthday = DateTime(
                                    jcrtDob.year + 18,
                                    jcrtDob.month,
                                    jcrtDob.day);
                                later18thBirthday = jcDob.isAfter(jcrtDob)
                                    ? jc18thBirthday
                                    : jcrt18thBirthday;
                              }

                              DateTime initialDate;
                              if (_anniversaryDateController.text.isNotEmpty) {
                                try {
                                  final parts = _anniversaryDateController.text
                                      .split('/');
                                  if (parts.length == 3) {
                                    initialDate = DateTime(
                                      int.parse(parts[2]),
                                      int.parse(parts[1]),
                                      int.parse(parts[0]),
                                    );
                                  } else {
                                    initialDate =
                                        later18thBirthday ?? DateTime.now();
                                  }
                                } catch (e) {
                                  print('Error parsing anniversary date: $e');
                                  initialDate =
                                      later18thBirthday ?? DateTime.now();
                                }
                              } else {
                                initialDate =
                                    later18thBirthday ?? DateTime.now();
                              }

                              if (initialDate.isBefore(
                                  later18thBirthday ?? DateTime(1900))) {
                                initialDate =
                                    later18thBirthday ?? DateTime(1900);
                              }
                              if (initialDate.isAfter(DateTime.now())) {
                                initialDate = DateTime.now();
                              }

                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: later18thBirthday ?? DateTime(1900),
                                lastDate: DateTime.now(),
                              );

                              if (picked != null) {
                                setState(() {
                                  _anniversaryDateController.text =
                                      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                });
                              }
                            },
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _anniversaryDateController.text =
                                _formatDateInput(value);
                            _anniversaryDateController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset:
                                      _anniversaryDateController.text.length),
                            );
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter anniversary date';
                          }
                          if (!_isValidDate(value)) {
                            return 'Please enter a valid date (DD/MM/YYYY)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      // Submit Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                'Update Member',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _jcNameController.dispose();
    _jcMobileController.dispose();
    _jcrtNameController.dispose();
    _jcrtMobileController.dispose();
    _anniversaryDateController.dispose();
    _jcDobController.dispose();
    _jcrtDobController.dispose();
    _jcQualificationController.dispose();
    _jcBloodGroupController.dispose();
    _jcEmailController.dispose();
    _jcHomeAddressController.dispose();
    _jcOccupationController.dispose();
    _jcFirmNameController.dispose();
    _jcOccupationAddressController.dispose();
    _jcrtBloodGroupController.dispose();
    _jcrtEmailController.dispose();
    _jcrtOccupationController.dispose();
    _jcrtOccupationAddressController.dispose();
    super.dispose();
  }
}
