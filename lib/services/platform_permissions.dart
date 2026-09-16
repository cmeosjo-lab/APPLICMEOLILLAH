import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class LocalNetworkPermissionResult {
  final bool mayProceed;
  final bool permanentlyDenied;
  final String message;

  const LocalNetworkPermissionResult({required this.mayProceed, required this.permanentlyDenied, required this.message});
}

class PlatformPermissions {
  const PlatformPermissions._();

  /// Android 17 (SDK 37+) protège le LAN avec ACCESS_LOCAL_NETWORK.
  /// Sur iOS, la première connexion locale déclenche le dialogue système à partir
  /// de NSLocalNetworkUsageDescription. Sur Android antérieur, l'appel est non bloquant.
  static Future<LocalNetworkPermissionResult> ensureLocalNetwork() async {
    if (!Platform.isAndroid) {
      return const LocalNetworkPermissionResult(mayProceed: true, permanentlyDenied: false, message: 'Autorisation réseau local gérée par le système.');
    }
    try {
      final result = await Permission.accessLocalNetwork.request();
      if (result.isGranted || result.isLimited) {
        return const LocalNetworkPermissionResult(mayProceed: true, permanentlyDenied: false, message: 'Réseau local autorisé.');
      }
      if (result.isPermanentlyDenied) {
        return const LocalNetworkPermissionResult(mayProceed: false, permanentlyDenied: true, message: 'Accès au réseau local refusé dans les réglages Android.');
      }
      // Sur Android antérieur à l'application obligatoire de cette permission,
      // on tente quand même la connexion LAN afin de ne pas bloquer inutilement.
      return const LocalNetworkPermissionResult(mayProceed: true, permanentlyDenied: false, message: 'Connexion locale à tester.');
    } catch (_) {
      return const LocalNetworkPermissionResult(mayProceed: true, permanentlyDenied: false, message: 'Connexion locale à tester.');
    }
  }
}
