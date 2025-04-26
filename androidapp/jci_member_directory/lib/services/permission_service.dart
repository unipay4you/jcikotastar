import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestGalleryPermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  static Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.sms,
      Permission.camera,
      Permission.storage,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  static Future<bool> checkPhonePermission() async {
    return await Permission.phone.isGranted;
  }

  static Future<bool> checkSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  static Future<bool> checkGalleryPermission() async {
    return await Permission.storage.isGranted;
  }

  static Future<bool> checkAllPermissions() async {
    return await Permission.phone.isGranted &&
        await Permission.sms.isGranted &&
        await Permission.camera.isGranted &&
        await Permission.storage.isGranted;
  }
}
