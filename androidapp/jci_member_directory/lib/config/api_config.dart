class ApiConfig {
  // Environment flag - set to false for development, true for production
  static const bool isProduction = true;

  // Base URLs
  static const String devBaseUrl = 'http://192.168.1.2:8000/';
  static const String prodBaseUrl = 'https://mylegaldiary.in/';

  // Get base URL based on environment
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;

  // API Endpoints
  static const String login = 'jks/api/auth/login/';
  //static const String register = 'jks/api/auth/register/';
  static const String verifyOtp = 'jks/api/auth/verify-otp/';
  static const String forgotPassword = 'jks/api/auth/forgot-password/';
  static const String resetPassword = 'jks/api/auth/reset-password/';
  static const String resendOtp = 'jks/api/auth/resend-otp/';
  static const String userProfile = 'jks/api/auth/user/';
  static const String profile = 'jks/api/user/profile/';
  static const String updateProfile = 'jks/api/user/update-profile/';
  static const String members = 'jks/api/members/';
  static const String memberDetails = 'jks/api/members/';
  static const String adminDashboard = 'jks/api/admin/dashboard/';
  static const String programImages = 'jks/api/program-images/';
  static const String uploadProgramImage = 'jks/api/program-images/upload/';

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
