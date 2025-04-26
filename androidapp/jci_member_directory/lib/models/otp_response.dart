class OTPResponse {
  final int status;
  final String message;
  final OTPData? data;

  OTPResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory OTPResponse.fromJson(Map<String, dynamic> json) {
    return OTPResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? OTPData.fromJson(json['data']) : null,
    );
  }
}

class OTPData {
  final bool isFirstLogin;
  final String userType;

  OTPData({
    required this.isFirstLogin,
    required this.userType,
  });

  factory OTPData.fromJson(Map<String, dynamic> json) {
    return OTPData(
      isFirstLogin: json['is_first_login'] ?? false,
      userType: json['usertype'] ?? '',
    );
  }
}
