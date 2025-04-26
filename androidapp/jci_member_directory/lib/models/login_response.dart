class LoginResponse {
  final int status;
  final String message;
  final LoginData? data;

  LoginResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String message;
  final String usertype;
  final String refreshToken;
  final String accessToken;

  LoginData({
    required this.message,
    required this.usertype,
    required this.refreshToken,
    required this.accessToken,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      message: json['massage'] ?? '',
      usertype: json['usertype'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      accessToken: json['access_token'] ?? '',
    );
  }
}
