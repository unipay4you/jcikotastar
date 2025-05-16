import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';

class AddNewMemberScreen extends StatefulWidget {
  const AddNewMemberScreen({Key? key}) : super(key: key);

  @override
  _AddNewMemberScreenState createState() => _AddNewMemberScreenState();
}

class _AddNewMemberScreenState extends State<AddNewMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

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

  // Helper function to validate anniversary date
  bool _isValidAnniversaryDate(
      DateTime date, DateTime jcDob, DateTime jcrtDob) {
    final jc18thBirthday = DateTime(jcDob.year + 18, jcDob.month, jcDob.day);
    final jcrt18thBirthday =
        DateTime(jcrtDob.year + 18, jcrtDob.month, jcrtDob.day);
    final later18thBirthday =
        jcDob.isAfter(jcrtDob) ? jc18thBirthday : jcrt18thBirthday;
    return date.isAfter(later18thBirthday);
  }

  // Helper method to capitalize first letter of each word
  String _capitalizeFirstLetterOfEachWord(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Member',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
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
                    onTap: () {
                      // TODO: Implement image picker for JC
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _jcImagePath != null
                          ? ClipOval(
                              child: Image.network(
                                _jcImagePath!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Add JC Photo',
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            ),
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
                  decoration: InputDecoration(
                    labelText: 'JC Mobile *',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _eighteenYearsAgo,
                      firstDate: _hundredYearsAgo,
                      lastDate: _eighteenYearsAgo,
                    );
                    if (picked != null) {
                      setState(() {
                        _jcDobController.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                      });
                    }
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
                    setState(() {
                      _selectedJCOccupation = newValue;
                    });
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
                const SizedBox(height: 16),
                // JC Post
                DropdownButtonFormField<String>(
                  value: _selectedJCPost,
                  decoration: InputDecoration(
                    labelText: 'JC Post',
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
                    setState(() {
                      _selectedJCPost = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select JC post';
                    }
                    return null;
                  },
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
                    onTap: () {
                      // TODO: Implement image picker for JCRT
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _jcrtImagePath != null
                          ? ClipOval(
                              child: Image.network(
                                _jcrtImagePath!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Add JCRT Photo',
                                  style: GoogleFonts.poppins(),
                                ),
                              ],
                            ),
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
                  decoration: InputDecoration(
                    labelText: 'JCRT Mobile',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  ),
                  readOnly: true,
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _eighteenYearsAgo,
                      firstDate: _hundredYearsAgo,
                      lastDate: _eighteenYearsAgo,
                    );
                    if (picked != null) {
                      setState(() {
                        _jcrtDobController.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                      });
                    }
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
                    setState(() {
                      _selectedJCRTOccupation = newValue;
                    });
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
                    setState(() {
                      _selectedJCRTPost = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select JCRT post';
                    }
                    return null;
                  },
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
                  ),
                  readOnly: true,
                  onTap: () async {
                    if (_jcDobController.text.isEmpty ||
                        _jcrtDobController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please select both JC and JCRT dates of birth first'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    // Parse DOB dates
                    final jcDobParts = _jcDobController.text.split('/');
                    final jcrtDobParts = _jcrtDobController.text.split('/');

                    final jcDob = DateTime(
                      int.parse(jcDobParts[2]),
                      int.parse(jcDobParts[1]),
                      int.parse(jcDobParts[0]),
                    );

                    final jcrtDob = DateTime(
                      int.parse(jcrtDobParts[2]),
                      int.parse(jcrtDobParts[1]),
                      int.parse(jcrtDobParts[0]),
                    );

                    // Calculate the later 18th birthday
                    final jc18thBirthday =
                        DateTime(jcDob.year + 18, jcDob.month, jcDob.day);
                    final jcrt18thBirthday =
                        DateTime(jcrtDob.year + 18, jcrtDob.month, jcrtDob.day);
                    final later18thBirthday = jcDob.isAfter(jcrtDob)
                        ? jc18thBirthday
                        : jcrt18thBirthday;

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: later18thBirthday,
                      firstDate: later18thBirthday,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _anniversaryDateController.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                      });
                    }
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
                          'Add Member',
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

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get auth token
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

        // Format dates
        String formatDate(String? dateStr) {
          if (dateStr == null || dateStr.isEmpty) return "1950-01-01";
          try {
            // Split the date string by '/'
            final parts = dateStr.split('/');
            if (parts.length != 3) return "1950-01-01";

            // Create DateTime object from parts
            final date = DateTime(
              int.parse(parts[2]), // year
              int.parse(parts[1]), // month
              int.parse(parts[0]), // day
            );

            // Format to YYYY-MM-DD
            return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          } catch (e) {
            print('Error formatting date: $e');
            return "1950-01-01";
          }
        }

        final response = await ApiService.post(
          endpoint: 'jks/api/admin/addmember/',
          body: {
            "jcName": _jcNameController.text.isEmpty
                ? ""
                : _capitalizeFirstLetterOfEachWord(_jcNameController.text),
            "jcMobile": _jcMobileController.text.isEmpty
                ? ""
                : _jcMobileController.text,
            "jcrtName": _jcrtNameController.text.isEmpty
                ? ""
                : _capitalizeFirstLetterOfEachWord(_jcrtNameController.text),
            "jcrtMobile": _jcrtMobileController.text.isEmpty
                ? ""
                : _jcrtMobileController.text,
            "anniversaryDate": formatDate(_anniversaryDateController.text),
            "jcDob": formatDate(_jcDobController.text),
            "jcrtDob": formatDate(_jcrtDobController.text),
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
            "jcrtOccupationAddress":
                _jcrtOccupationAddressController.text.isEmpty
                    ? ""
                    : _jcrtOccupationAddressController.text,
            "jcPost": _selectedJCPost ?? "",
            "jcrtPost": _selectedJCRTPost ?? "",
            "jcImage": _jcImagePath ?? "",
            "jcrtImage": _jcrtImagePath ?? "",
            "searchteg": ""
          },
          token: token,
        );

        if (!mounted) return;

        if (response['status'] == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Add Member successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Something went wrong'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add member: ${e.toString()}'),
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
