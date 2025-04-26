import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/jci_logo.dart';

class MemberDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> member;

  const MemberDetailsScreen({
    Key? key,
    required this.member,
  }) : super(key: key);

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image
            Center(
              child: member['profile_image'] != null
                  ? ClipOval(
                      child: Image.network(
                        member['profile_image'],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const JCILogo(size: 120),
            ),
            const SizedBox(height: 24),
            // Member Name
            Text(
              member['name'] ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Position
            Text(
              member['position'] ?? 'N/A',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Contact Information
            _buildSection(
              'Contact Information',
              [
                _buildInfoItem(Icons.phone, 'Phone', member['phone'] ?? 'N/A'),
                _buildInfoItem(Icons.email, 'Email', member['email'] ?? 'N/A'),
                _buildInfoItem(
                    Icons.location_on, 'Address', member['address'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 24),
            // Personal Information
            _buildSection(
              'Personal Information',
              [
                _buildInfoItem(
                    Icons.cake, 'Date of Birth', member['dob'] ?? 'N/A'),
                _buildInfoItem(
                    Icons.work, 'Occupation', member['occupation'] ?? 'N/A'),
                _buildInfoItem(
                    Icons.school, 'Education', member['education'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 24),
            // JCI Information
            _buildSection(
              'JCI Information',
              [
                _buildInfoItem(
                    Icons.badge, 'Member ID', member['member_id'] ?? 'N/A'),
                _buildInfoItem(Icons.calendar_today, 'Join Date',
                    member['join_date'] ?? 'N/A'),
                _buildInfoItem(
                    Icons.group, 'Chapter', member['chapter'] ?? 'N/A'),
              ],
            ),
          ],
        ),
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

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
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
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
