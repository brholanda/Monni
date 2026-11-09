import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockSettings extends ChangeNotifier {
  AppLockSettings._();

  static final AppLockSettings instance = AppLockSettings._();

  static const _pinHashKey = 'app_lock_pin_hash';
  static const _biometricsEnabledKey = 'app_lock_biometrics_enabled';

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  bool _hasPin = false;
  bool _biometricsEnabled = false;
  bool _biometricsAvailable = false;

  bool get hasPin => _hasPin;
  bool get biometricsEnabled => _biometricsEnabled;
  bool get biometricsAvailable => _biometricsAvailable;
  bool get isLockEnabled => _hasPin;

  Future<void> load() async {
    _hasPin = await _storage.containsKey(key: _pinHashKey);
    _biometricsEnabled =
        await _storage.read(key: _biometricsEnabledKey) == 'true';
    _biometricsAvailable = await _checkBiometricsAvailability();
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinHashKey, value: _hashPin(pin));
    _hasPin = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final savedHash = await _storage.read(key: _pinHashKey);
    return savedHash != null && savedHash == _hashPin(pin);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    if (enabled && !_biometricsAvailable) return;
    _biometricsEnabled = enabled;
    await _storage.write(
      key: _biometricsEnabledKey,
      value: enabled.toString(),
    );
    notifyListeners();
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!_biometricsEnabled || !_biometricsAvailable) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Desbloqueie o Monni para continuar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> disable() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _biometricsEnabledKey);
    _hasPin = false;
    _biometricsEnabled = false;
    notifyListeners();
  }

  Future<bool> _checkBiometricsAvailability() async {
    if (kIsWeb) return false;
    try {
      return await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();
}
