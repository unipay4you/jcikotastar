import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/jci_logo.dart';
import '../config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class MemberDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const MemberDetailsScreen({
    Key? key,
    required this.member,
  }) : super(key: key);

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Future<void> _launchWhatsApp(String phoneNumber) async {
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

    // Remove any non-digit characters from the phone number
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    print('After removing non-digits: $cleanNumber');

    // Remove leading '0' if present
    if (cleanNumber.startsWith('0')) {
      cleanNumber = cleanNumber.substring(1);
      print('After removing leading 0: $cleanNumber');
    }

    // Add country code if not present
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+91$cleanNumber'; // Adding India country code
      print('After adding country code: $cleanNumber');
    }

    // Remove the '+' from the number for the URL
    final numberForUrl = cleanNumber.replaceFirst('+', '');
    print('Final number for URL: $numberForUrl');

    try {
      final Uri whatsappUrl = Uri.parse(
          "https://wa.me/$numberForUrl?text=${Uri.encodeComponent('')}");

      print('Attempting to launch WhatsApp with URL: $whatsappUrl');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
        print('Successfully launched WhatsApp');
      } else {
        print('Error: Could not launch WhatsApp');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not launch WhatsApp. Please make sure WhatsApp is installed.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.member['jcrtName']?.isNotEmpty == true ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                'JC Profile',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (widget.member['jcrtName']?.isNotEmpty == true)
              Tab(
                child: Text(
                  'JCRT Profile',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // JC Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // JC Profile Section
                _buildProfileSection(
                  imageUrl: widget.member['jcImage'],
                  name: widget.member['jcName'],
                  position: widget.member['jcpost'] ?? 'General Member',
                ),
                const SizedBox(height: 24),

                // JC Contact Information
                _buildSection(
                  'Contact Information',
                  [
                    _buildInfoItem(
                      Icons.phone,
                      'Phone',
                      widget.member['jcMobile']?['phone_number'] ?? 'N/A',
                      isPhone: true,
                    ),
                    _buildInfoItem(Icons.email, 'Email',
                        widget.member['jcEmail'] ?? 'N/A'),
                    _buildInfoItem(Icons.location_on, 'Home Address',
                        widget.member['jcHomeAddress'] ?? 'N/A'),
                    _buildInfoItem(Icons.business, 'Firm Name',
                        widget.member['jcFirmName'] ?? 'N/A'),
                    _buildInfoItem(Icons.work, 'Occupation Address',
                        widget.member['jcOccupationAddress'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 24),

                // JC Personal Information
                _buildSection(
                  'Personal Information',
                  [
                    _buildInfoItem(Icons.cake, 'Date of Birth',
                        widget.member['jcDob'] ?? 'N/A'),
                    _buildInfoItem(Icons.work, 'Occupation',
                        widget.member['jcOccupation'] ?? 'N/A'),
                    _buildInfoItem(Icons.school, 'Qualification',
                        widget.member['jcQualification'] ?? 'N/A'),
                    _buildInfoItem(Icons.bloodtype, 'Blood Group',
                        widget.member['jcBloodGroup'] ?? 'N/A'),
                  ],
                ),

                // Common Information
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                _buildSection(
                  'Common Information',
                  [
                    _buildInfoItem(Icons.calendar_today, 'Anniversary Date',
                        widget.member['anniversaryDate'] ?? 'N/A'),
                    _buildInfoItem(Icons.fingerprint, 'Member ID',
                        widget.member['uid'] ?? 'N/A'),
                    _buildInfoItem(Icons.update, 'Last Updated',
                        widget.member['updated_at'] ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),

          // JCRT Tab (if available)
          if (widget.member['jcrtName']?.isNotEmpty == true)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // JCRT Profile Section
                  _buildProfileSection(
                    imageUrl: widget.member['jcrtImage'],
                    name: widget.member['jcrtName'],
                    position: widget.member['jcrtpost'] ?? 'General Member',
                  ),
                  const SizedBox(height: 24),

                  // JCRT Contact Information
                  _buildSection(
                    'Contact Information',
                    [
                      _buildInfoItem(
                        Icons.phone,
                        'Phone',
                        widget.member['jcrtMobile']?['phone_number'] ?? 'N/A',
                        isPhone: true,
                      ),
                      _buildInfoItem(Icons.email, 'Email',
                          widget.member['jcrtEmail'] ?? 'N/A'),
                      _buildInfoItem(Icons.work, 'Occupation Address',
                          widget.member['jcrtOccupationAddress'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // JCRT Personal Information
                  _buildSection(
                    'Personal Information',
                    [
                      _buildInfoItem(Icons.cake, 'Date of Birth',
                          widget.member['jcrtDob'] ?? 'N/A'),
                      _buildInfoItem(Icons.work, 'Occupation',
                          widget.member['jcrtOccupation'] ?? 'N/A'),
                      _buildInfoItem(Icons.bloodtype, 'Blood Group',
                          widget.member['jcrtBloodGroup'] ?? 'N/A'),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSection({
    required String? imageUrl,
    required String? name,
    required String? position,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Profile Image
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: imageUrl != null
                ? NetworkImage('${ApiConfig.baseUrl}$imageUrl')
                : null,
            child: imageUrl == null ? const JCILogo(size: 80) : null,
          ),
          const SizedBox(height: 16),
          // Name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              name ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          // Position
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              position ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildInfoItem(IconData icon, String label, String value,
      {bool isPhone = false}) {
    // Capitalize first letter for specific fields
    String displayValue = value;
    if (value != 'N/A') {
      switch (label) {
        case 'Firm Name':
        case 'Occupation':
        case 'Qualification':
          displayValue = _capitalizeFirstLetter(value);
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayValue,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isPhone && value != 'N/A') ...[
                      IconButton(
                        icon: _buildWhatsAppIcon(),
                        onPressed: () => _launchWhatsApp(value),
                        tooltip: 'Open WhatsApp',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () => _launchPhoneCall(value),
                        tooltip: 'Make Phone Call',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
