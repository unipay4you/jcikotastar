import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/jci_logo.dart';
import 'add_new_member_screen.dart';

class ManageMembersScreen extends StatefulWidget {
  const ManageMembersScreen({Key? key}) : super(key: key);

  @override
  _ManageMembersScreenState createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Members',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                'Member Management',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Add New Member Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddNewMemberScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: Text(
                  'Add New Member',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Add Members in Bulk Button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to bulk add members screen
                },
                icon: const Icon(Icons.group_add),
                label: Text(
                  'Add Members in Bulk',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Member List Section
              Text(
                'Existing Members',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // TODO: Add member list here
            ],
          ),
        ),
      ),
    );
  }
}
