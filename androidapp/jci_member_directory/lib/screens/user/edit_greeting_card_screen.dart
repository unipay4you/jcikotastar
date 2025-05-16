import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditGreetingCardScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const EditGreetingCardScreen({
    Key? key,
    this.profileData,
  }) : super(key: key);

  @override
  _EditGreetingCardScreenState createState() => _EditGreetingCardScreenState();
}

class _EditGreetingCardScreenState extends State<EditGreetingCardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Greeting Card',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Edit Greeting Card Screen',
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }
}
