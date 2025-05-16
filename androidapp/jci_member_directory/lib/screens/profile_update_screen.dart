import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:math' show min;

class ProfileUpdateScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final Map<String, dynamic>? userData;

  const ProfileUpdateScreen({Key? key, this.profileData, this.userData})
      : super(key: key);

  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _userData;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestsController = TextEditingController();
  final _skillsController = TextEditingController();
  final _educationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _awardsController = TextEditingController();
  final _publicationsController = TextEditingController();
  final _patentsController = TextEditingController();
  final _projectsController = TextEditingController();
  final _socialMediaController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _notesController = TextEditingController();

  // Form controllers
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
  String? _selectedJCPost = 'General Member';
  String? _selectedJCRTPost = 'General Member';
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
      // If parsed date is valid and within allowed range, use it
      if (parsedDate.isBefore(defaultDate)) {
        return parsedDate;
      }
    }
    return defaultDate;
  }

  // Add this helper function at the top of the class
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

    // Check if the image path is a network URL
    if (imagePath.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading ${isJC ? "JC" : "JCRT"} image: $error');
            print('${isJC ? "JC" : "JCRT"} Image Path: $imagePath');
            return const Icon(Icons.error, size: 40);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const CircularProgressIndicator();
          },
        ),
      );
    }

    // Handle local file path
    try {
      return ClipOval(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading ${isJC ? "JC" : "JCRT"} image: $error');
            print('${isJC ? "JC" : "JCRT"} Image Path: $imagePath');
            return const Icon(Icons.error, size: 40);
          },
        ),
      );
    } catch (e) {
      print('Error displaying ${isJC ? "JC" : "JCRT"} image: $e');
      return const Icon(Icons.error, size: 40);
    }
  }

  // Add this helper function at the top of the class
  String _formatDateInput(String input) {
    // Remove any non-digit characters
    String digits = input.replaceAll(RegExp(r'[^\d]'), '');

    // Format the date as DD/MM/YYYY
    if (digits.length <= 2) {
      return digits;
    } else if (digits.length <= 4) {
      return '${digits.substring(0, 2)}/${digits.substring(2)}';
    } else {
      return '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4, min(8, digits.length))}';
    }
  }

  // Add this helper function to validate date format
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

      // Check if the date is valid (e.g., February 30th is invalid)
      final date = DateTime(year, month, day);
      return date.year == year && date.month == month && date.day == day;
    } catch (e) {
      return false;
    }
  }

  // Add this helper function at the top of the class
  bool _isSameImage(String? path1, String? path2) {
    if (path1 == null || path2 == null) return false;

    // Extract the filename from the paths
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
    print('ProfileUpdateScreen - initState called');
    _profileData = widget.profileData;
    _userData = widget.userData;
    print('ProfileUpdateScreen - Profile Data: $_profileData');
    print('ProfileUpdateScreen - User Data: $_userData');

    if (_userData != null) {
      print('ProfileUpdateScreen - Setting initial values from user data');

      // Log raw image data from user data
      print('Raw JC Image from user data: ${_userData!['jcImage']}');
      print('Raw JCRT Image from user data: ${_userData!['jcrtImage']}');

      _jcNameController.text = _userData!['jcName'] ?? '';
      _jcrtNameController.text = _userData!['jcrtName'] ?? '';

      // Format anniversary date from YYYY-MM-DD to DD/MM/YYYY
      if (_userData!['anniversaryDate'] != null &&
          _userData!['anniversaryDate'].toString().isNotEmpty) {
        try {
          final parts = _userData!['anniversaryDate'].toString().split('-');
          if (parts.length == 3) {
            _anniversaryDateController.text =
                "${parts[2]}/${parts[1]}/${parts[0]}";
          }
        } catch (e) {
          print('Error formatting anniversary date: $e');
        }
      }

      // Format JC DOB from YYYY-MM-DD to DD/MM/YYYY
      if (_userData!['jcDob'] != null &&
          _userData!['jcDob'].toString().isNotEmpty) {
        try {
          final parts = _userData!['jcDob'].toString().split('-');
          if (parts.length == 3) {
            _jcDobController.text = "${parts[2]}/${parts[1]}/${parts[0]}";
          }
        } catch (e) {
          print('Error formatting JC DOB: $e');
        }
      }

      // Format JCRT DOB from YYYY-MM-DD to DD/MM/YYYY
      if (_userData!['jcrtDob'] != null &&
          _userData!['jcrtDob'].toString().isNotEmpty) {
        try {
          final parts = _userData!['jcrtDob'].toString().split('-');
          if (parts.length == 3) {
            _jcrtDobController.text = "${parts[2]}/${parts[1]}/${parts[0]}";
          }
        } catch (e) {
          print('Error formatting JCRT DOB: $e');
        }
      }

      _jcQualificationController.text = _userData!['jcQualification'] ?? '';
      _jcBloodGroupController.text = _userData!['jcBloodGroup'] ?? '';
      _jcEmailController.text = _userData!['jcEmail'] ?? '';
      _jcHomeAddressController.text = _userData!['jcHomeAddress'] ?? '';

      // Set mobile numbers from nested structure
      if (_userData!['jcMobile'] != null) {
        _jcMobileController.text =
            _userData!['jcMobile']['phone_number']?.toString() ?? '';
      }
      if (_userData!['jcrtMobile'] != null) {
        _jcrtMobileController.text =
            _userData!['jcrtMobile']['phone_number']?.toString() ?? '';
      }

      // Set occupation values only if they exist in the options list
      final jcOccupation = _userData!['jcOccupation']?.toString() ?? 'Business';
      _selectedJCOccupation = _jcOccupationOptions.contains(jcOccupation)
          ? jcOccupation
          : 'Business';

      final jcrtOccupation =
          _userData!['jcrtOccupation']?.toString() ?? 'Business';
      _selectedJCRTOccupation = _jcrtOccupationOptions.contains(jcrtOccupation)
          ? jcrtOccupation
          : 'Business';

      _jcFirmNameController.text = _userData!['jcFirmName'] ?? '';
      _jcOccupationAddressController.text =
          _userData!['jcOccupationAddress'] ?? '';
      _jcrtBloodGroupController.text = _userData!['jcrtBloodGroup'] ?? '';
      _jcrtEmailController.text = _userData!['jcrtEmail'] ?? '';
      _jcrtOccupationAddressController.text =
          _userData!['jcrtOccupationAddress'] ?? '';

      // Set post values only if they exist in the options list
      final jcPost = _userData!['jcpost']?.toString() ?? 'General Member';
      _selectedJCPost =
          _postOptions.contains(jcPost) ? jcPost : 'General Member';

      final jcrtPost = _userData!['jcrtpost']?.toString() ?? 'General Member';
      _selectedJCRTPost =
          _postOptions.contains(jcrtPost) ? jcrtPost : 'General Member';

      // Set image paths with base URL
      if (_userData!['jcImage'] != null) {
        String imagePath = _userData!['jcImage'].toString();
        print('Processing JC Image Path:');
        print('Original path: $imagePath');

        // Remove file:/// prefix if present
        if (imagePath.startsWith('file:///')) {
          imagePath = imagePath.replaceFirst('file:///', '');
          print('After removing file:/// prefix: $imagePath');
        }

        // Remove leading slash if present
        if (imagePath.startsWith('/')) {
          imagePath = imagePath.substring(1);
          print('After removing leading slash: $imagePath');
        }

        // Add base URL if not already a full URL
        _jcImagePath = imagePath.startsWith('http')
            ? imagePath
            : '${ApiConfig.baseUrl}$imagePath';
        print('Final JC Image Path: $_jcImagePath');
      } else {
        print('JC Image is null in user data');
      }

      if (_userData!['jcrtImage'] != null) {
        String imagePath = _userData!['jcrtImage'].toString();
        print('Processing JCRT Image Path:');
        print('Original path: $imagePath');

        // Remove file:/// prefix if present
        if (imagePath.startsWith('file:///')) {
          imagePath = imagePath.replaceFirst('file:///', '');
          print('After removing file:/// prefix: $imagePath');
        }

        // Remove leading slash if present
        if (imagePath.startsWith('/')) {
          imagePath = imagePath.substring(1);
          print('After removing leading slash: $imagePath');
        }

        // Add base URL if not already a full URL
        _jcrtImagePath = imagePath.startsWith('http')
            ? imagePath
            : '${ApiConfig.baseUrl}$imagePath';
        print('Final JCRT Image Path: $_jcrtImagePath');
      } else {
        print('JCRT Image is null in user data');
      }

      print('ProfileUpdateScreen - JC Mobile: ${_jcMobileController.text}');
      print('ProfileUpdateScreen - JCRT Mobile: ${_jcrtMobileController.text}');
      print('ProfileUpdateScreen - JC Post: $_selectedJCPost');
      print('ProfileUpdateScreen - JCRT Post: $_selectedJCRTPost');
      print('ProfileUpdateScreen - JC Occupation: $_selectedJCOccupation');
      print('ProfileUpdateScreen - JCRT Occupation: $_selectedJCRTOccupation');
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final token = await AuthService.getAccessToken();
        if (token == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Authentication token not found. Please login again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Format dates to YYYY-MM-DD, preserving existing dates if no changes
        String formatDate(String inputDate, String? existingDate) {
          if (inputDate.isEmpty) {
            return "1950-01-01";
          }

          try {
            final parts = inputDate.split('/');
            if (parts.length != 3) {
              // If date format is invalid, return default date
              return "1950-01-01";
            }

            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);

            // Validate date components
            if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
              return "1950-01-01";
            }

            return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
          } catch (e) {
            print('Error formatting date: $e');
            return "1950-01-01";
          }
        }

        print('Formatted dates:');
        print(
            'Anniversary: ${formatDate(_anniversaryDateController.text, _userData?['anniversaryDate'])}');
        print(
            'JC DOB: ${formatDate(_jcDobController.text, _userData?['jcDob'])}');
        print(
            'JCRT DOB: ${formatDate(_jcrtDobController.text, _userData?['jcrtDob'])}');

        // Prepare image data
        String? jcImageData;
        String? jcrtImageData;

        // Handle JC image
        if (_jcImagePath != null) {
          // Check if the image is different from the original
          if (!_isSameImage(_jcImagePath, _userData?['jcImage'])) {
            if (_jcImagePath!.startsWith('data:image')) {
              // If it's already a data URI, extract the base64 part
              jcImageData = _jcImagePath!.split(',')[1];
            } else if (_jcImagePath!.startsWith('http')) {
              // If it's a network URL, keep it as is
              jcImageData = _jcImagePath;
            } else {
              // If it's a local file, read and convert to base64
              try {
                final file = File(_jcImagePath!);
                final bytes = await file.readAsBytes();
                jcImageData = base64Encode(bytes);
              } catch (e) {
                print('Error reading JC image file: $e');
              }
            }
          } else {
            // If the image is the same as original, pass empty string
            jcImageData = "";
          }
        } else {
          // If no image path is set, pass empty string
          jcImageData = "";
        }

        // Handle JCRT image
        if (_jcrtImagePath != null) {
          // Check if the image is different from the original
          if (!_isSameImage(_jcrtImagePath, _userData?['jcrtImage'])) {
            if (_jcrtImagePath!.startsWith('data:image')) {
              // If it's already a data URI, extract the base64 part
              jcrtImageData = _jcrtImagePath!.split(',')[1];
            } else if (_jcrtImagePath!.startsWith('http')) {
              // If it's a network URL, keep it as is
              jcrtImageData = _jcrtImagePath;
            } else {
              // If it's a local file, read and convert to base64
              try {
                final file = File(_jcrtImagePath!);
                final bytes = await file.readAsBytes();
                jcrtImageData = base64Encode(bytes);
              } catch (e) {
                print('Error reading JCRT image file: $e');
              }
            }
          } else {
            // If the image is the same as original, pass empty string
            jcrtImageData = "";
          }
        } else {
          // If no image path is set, pass empty string
          jcrtImageData = "";
        }

        print('JC Image Data Length: ${jcImageData?.length ?? 0}');
        print('JCRT Image Data Length: ${jcrtImageData?.length ?? 0}');

        // Prepare request body
        final requestBody = {
          "jcName":
              _jcNameController.text.isEmpty ? "" : _jcNameController.text,
          "jcMobile":
              _jcMobileController.text.isEmpty ? "" : _jcMobileController.text,
          "jcrtName":
              _jcrtNameController.text.isEmpty ? "" : _jcrtNameController.text,
          "jcrtMobile": _jcrtMobileController.text.isEmpty
              ? ""
              : _jcrtMobileController.text,
          "anniversaryDate": formatDate(
              _anniversaryDateController.text, _userData?['anniversaryDate']),
          "jcDob": formatDate(_jcDobController.text, _userData?['jcDob']),
          "jcrtDob": formatDate(_jcrtDobController.text, _userData?['jcrtDob']),
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

        print('Request body: $requestBody');

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfile}'),
          headers: ApiConfig.getHeaders(token: token),
          body: json.encode(requestBody),
        );

        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        final responseData = json.decode(response.body);

        if (!mounted) return;

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  responseData['message'] ?? 'Profile updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Something went wrong'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error in _handleSubmit: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
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
  }

  // Update the _pickImage method to handle both local and network images
  Future<void> _pickImage(bool isJC) async {
    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus.isDenied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to take photos'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Show bottom sheet for image source selection
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

      // Pick the image
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (image != null) {
        // Convert image to base64
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Add data URI prefix
        final imageData = 'data:image/jpeg;base64,$base64Image';

        setState(() {
          if (isJC) {
            _jcImagePath = image.path; // Store the file path for preview
            _jcImageData = imageData; // Store the base64 data for API
          } else {
            _jcrtImagePath = image.path; // Store the file path for preview
            _jcrtImageData = imageData; // Store the base64 data for API
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ProfileUpdateScreen - Building with JC Post: $_selectedJCPost');
    print('ProfileUpdateScreen - Building with JCRT Post: $_selectedJCRTPost');
    print(
        'ProfileUpdateScreen - Building with JC Occupation: $_selectedJCOccupation');
    print(
        'ProfileUpdateScreen - Building with JCRT Occupation: $_selectedJCRTOccupation');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Update Profile',
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
                        'Profile Information',
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
                      // JC Mobile
                      TextFormField(
                        controller: _jcMobileController,
                        keyboardType: TextInputType.phone,
                        readOnly: _userData?['jcMobile'] != null,
                        decoration: InputDecoration(
                          labelText: 'JC Mobile *',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: _userData?['jcMobile'] != null
                              ? 'Mobile number cannot be edited'
                              : null,
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
                      // JCRT Mobile
                      TextFormField(
                        controller: _jcrtMobileController,
                        keyboardType: TextInputType.phone,
                        readOnly: _userData?['jcrtMobile'] != null,
                        decoration: InputDecoration(
                          labelText: 'JCRT Mobile',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: _userData?['jcrtMobile'] != null
                              ? 'Mobile number cannot be edited'
                              : null,
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
                              // Parse DOB dates if they exist
                              DateTime? jcDob =
                                  _parseDate(_jcDobController.text);
                              DateTime? jcrtDob =
                                  _parseDate(_jcrtDobController.text);

                              // Calculate the later 18th birthday if both DOBs exist
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

                              // Get initial date for picker
                              DateTime initialDate;
                              if (_anniversaryDateController.text.isNotEmpty) {
                                try {
                                  final parts = _anniversaryDateController.text
                                      .split('/');
                                  if (parts.length == 3) {
                                    initialDate = DateTime(
                                      int.parse(parts[2]), // year
                                      int.parse(parts[1]), // month
                                      int.parse(parts[0]), // day
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

                              // Ensure initial date is within valid range
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
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Theme.of(context).primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                                'Update Profile',
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
