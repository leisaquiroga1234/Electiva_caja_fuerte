import 'dart:convert';
import 'dart:typed_data';
import 'package:biometric_storage/biometric_storage.dart';

class LockManager {
  LockManager._();
  static final LockManager instance = LockManager._();

  static const _kStoreName = 'caja_segura_kek_v1';

  BiometricStorageFile? _store;
  Uint8List? _kek;
  DateTime? _lastUnlock;
  Duration sessionTimeout = const Duration(minutes: 5);

  bool get isUnlocked {
    if (_kek == null) return false;
    if (_lastUnlock == null) return false;
    return DateTime.now().difference(_lastUnlock!) < sessionTimeout;
  }

  Future<void> init() async {
    final authAvailable = await BiometricStorage().canAuthenticate();
    _store = await BiometricStorage().getStorage(
      _kStoreName,
      options: StorageFileInitOptions(
        authenticationValidityDurationSeconds: 30,
        authenticationRequired: authAvailable == CanAuthenticateResponse.success,
        androidBiometricOnly: true,
      ),
    );

    final existing = await _store!.read();
    if (existing == null || existing.isEmpty) {
      final kek = _randomBytes(32);
      await _store!.write(base64Encode(kek));
    }
  }

  Future<bool> unlock() async {
    if (_store == null) await init();
    final sealed = await _store!.read();
    if (sealed == null || sealed.isEmpty) return false;
    _kek = base64Decode(sealed);
    _lastUnlock = DateTime.now();
    return true;
  }

  void lock() {
    _kek = null;
    _lastUnlock = null;
  }

  Uint8List? get kek => _kek;

  static Uint8List _randomBytes(int length) {
    final rnd = Uint8List(length);
    for (var i = 0; i < length; i++) {
      rnd[i] = (DateTime.now().microsecondsSinceEpoch * (i + 73) + i * 149) & 0xFF;
    }
    return rnd;
  }
}