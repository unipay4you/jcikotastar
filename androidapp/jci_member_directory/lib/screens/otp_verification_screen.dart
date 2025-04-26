import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';
import '../models/otp_response.dart';
import '../services/auth_service.dart';
import 'password_change_screen.dart';
import 'main_screen.dart';
import '../widgets/jci_logo.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({Key? key}) : super(key: key);

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _otp = '';
  final _storage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OTP Verification',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Logo Space
                  const JCILogo(),
                  const SizedBox(height: 40),
                  Text(
                    'Enter OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please enter the OTP sent to your mobile number',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // OTP Input
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    onChanged: (value) {
                      setState(() {
                        _otp = value;
                      });
                    },
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeFillColor: Colors.white,
                      activeColor: Colors.blue,
                      selectedColor: Colors.blue,
                      inactiveColor: Colors.grey[300],
                    ),
                    keyboardType: TextInputType.number,
                    enableActiveFill: false,
                    onCompleted: (value) {
                      _verifyOTP();
                    },
                  ),
                  const SizedBox(height: 24),
                  // Verify Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                            'Verify OTP',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Resend OTP
                  TextButton(
                    onPressed: _resendOTP,
                    child: Text(
                      'Resend OTP',
                      style: GoogleFonts.poppins(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get the access token from secure storage
        final accessToken = await _storage.read(key: 'access_token');
        if (accessToken == null) {
          throw Exception('Access token not found');
        }

        // Get the phone number from secure storage
        final phoneNumber = await _storage.read(key: 'phone_number');
        if (phoneNumber == null) {
          throw Exception('Phone number not found');
        }

        final response = await ApiService.post(
          endpoint: ApiConfig.verifyOtp,
          body: {
            'phone_number': phoneNumber,
            'otp': _otp,
          },
          token: accessToken,
        );

        final otpResponse = OTPResponse.fromJson(response);

        if (otpResponse.status == 200 && otpResponse.data != null) {
          // Save auth data
          await AuthService.saveAuthData(
            accessToken: accessToken,
            userType: otpResponse.data!.userType,
          );

          if (!mounted) return;

          if (otpResponse.data!.isFirstLogin) {
            // Navigate to password change screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const PasswordChangeScreen()),
            );
          } else {
            // Navigate to main screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(otpResponse.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
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

  Future<void> _resendOTP() async {
    try {
      // Get the access token from secure storage
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // Get the phone number from secure storage
      final phoneNumber = await _storage.read(key: 'phone_number');
      if (phoneNumber == null) {
        throw Exception('Phone number not found');
      }

      // TODO: Implement resend OTP API call
      // For now, just show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resend OTP: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
