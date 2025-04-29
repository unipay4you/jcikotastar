class ApiConfig {
  // Base URL for development
  // Use 10.0.2.2 for Android emulator to access host machine's localhost
  // Use actual IP address for real devices
  static const String baseUrl =
      'http://192.168.1.6:8000/'; // Replace with your computer's IP address

  // API Endpoints
  static const String login = 'api/auth/login/';
  static const String register = 'api/auth/register/';
  static const String verifyOtp = 'api/auth/verify-otp/';
  static const String forgotPassword = 'api/auth/forgot-password/';
  static const String resetPassword = 'api/auth/reset-password/';
  static const String resendOtp = 'api/auth/resend-otp/';
  static const String userProfile = 'api/auth/user/';
  static const String profile = 'api/user/profile/';
  static const String updateProfile = 'api/user/update-profile/';
  static const String members = 'api/members/';
  static const String memberDetails = 'api/members/';
  static const String adminDashboard = 'api/admin/dashboard/';
  static const String programImages = '/api/program-images/';
  static const String uploadProgramImage = '/api/program-images/upload/';

  // API Headers
  static Map<String, String> getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // API Response Status Codes
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;

  // API Error Messages
  static const String networkError =
      'Network error occurred. Please check your internet connection.';
  static const String serverErrorMessage =
      'Server error occurred. Please try again later.';
  static const String unauthorizedMessage =
      'Unauthorized access. Please login again.';
  static const String notFoundMessage = 'Resource not found.';
  static const String badRequestMessage =
      'Invalid request. Please check your input.';
}
