class UserResponse {
  final int status;
  final List<UserData> payload;

  UserResponse({
    required this.status,
    required this.payload,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      status: json['status'] ?? 0,
      payload: (json['payload'] as List?)
              ?.map((user) => UserData.fromJson(user))
              .toList() ??
          [],
    );
  }
}

class UserData {
  final int id;
  final String lastLogin;
  final bool isSuperuser;
  final String firstName;
  final String lastName;
  final bool isStaff;
  final bool isActive;
  final String dateJoined;
  final String createdAt;
  final String updatedAt;
  final String phoneNumber;
  final String? userProfileImage;
  final String email;
  final String userType;
  final String? userName;
  final String? userDob;
  final String? userAddress1;
  final String? userAddress2;
  final String? userAddress3;
  final String? userState;
  final String? userDistrict;
  final String? userDistrictPincode;
  final List<dynamic> groups;
  final List<dynamic> userPermissions;

  UserData({
    required this.id,
    required this.lastLogin,
    required this.isSuperuser,
    required this.firstName,
    required this.lastName,
    required this.isStaff,
    required this.isActive,
    required this.dateJoined,
    required this.createdAt,
    required this.updatedAt,
    required this.phoneNumber,
    this.userProfileImage,
    required this.email,
    required this.userType,
    this.userName,
    this.userDob,
    this.userAddress1,
    this.userAddress2,
    this.userAddress3,
    this.userState,
    this.userDistrict,
    this.userDistrictPincode,
    required this.groups,
    required this.userPermissions,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      lastLogin: json['last_login'] ?? '',
      isSuperuser: json['is_superuser'] ?? false,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      isStaff: json['is_staff'] ?? false,
      isActive: json['is_active'] ?? false,
      dateJoined: json['date_joined'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      userProfileImage: json['user_profile_image'],
      email: json['email'] ?? '',
      userType: json['user_type'] ?? '',
      userName: json['user_name'],
      userDob: json['user_dob'],
      userAddress1: json['user_address1'],
      userAddress2: json['user_address2'],
      userAddress3: json['user_address3'],
      userState: json['user_state'],
      userDistrict: json['user_district'],
      userDistrictPincode: json['user_district_pincode'],
      groups: json['groups'] ?? [],
      userPermissions: json['user_permissions'] ?? [],
    );
  }
}
