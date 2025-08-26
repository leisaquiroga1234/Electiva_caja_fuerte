import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  static final CryptoService instance = CryptoService._();
  CryptoService._();

  final _aesGcm = AesGcm.with256bits();
  final _random = Random.secure();

  Uint8List randomBytes(int length) {
    return Uint8List.fromList(List.generate(length, (i) => _random.nextInt(256)));
  }

  Future<Map<String, Uint8List>> encryptWithWrappedKey({
    required Uint8List data,
    required Uint8List kek,
  }) async {
    final dek = randomBytes(32);
    final fileIv = randomBytes(12);
    final dekWrapIv = randomBytes(12);

    final secretBox = await _aesGcm.encrypt(
      data,
      secretKey: SecretKey(dek),
      nonce: fileIv,
    );

    final wrapped = await _aesGcm.encrypt(
      dek,
      secretKey: SecretKey(kek),
      nonce: dekWrapIv,
    );

    return {
      'cipher': Uint8List.fromList(secretBox.cipherText + secretBox.mac.bytes),
      'fileIv': fileIv,
      'dekWrapped': Uint8List.fromList(wrapped.cipherText + wrapped.mac.bytes),
      'dekWrapIv': dekWrapIv,
    };
  }

  Future<Uint8List> decryptWithWrappedKey({
    required Uint8List cipherWithTag,
    required Uint8List fileIv,
    required Uint8List dekWrappedWithTag,
    required Uint8List dekWrapIv,
    required Uint8List kek,
  }) async {
    // 1. Desenvolver la DEK
    final wrappedMac = Mac(dekWrappedWithTag.sublist(dekWrappedWithTag.length - 16));
    final wrappedCipher = dekWrappedWithTag.sublist(0, dekWrappedWithTag.length - 16);
    
    final dek = await _aesGcm.decrypt(
      SecretBox(wrappedCipher, nonce: dekWrapIv, mac: wrappedMac),
      secretKey: SecretKey(kek),
    );

    // 2. Descifrar el archivo
    final fileMac = Mac(cipherWithTag.sublist(cipherWithTag.length - 16));
    final fileCipher = cipherWithTag.sublist(0, cipherWithTag.length - 16);
    
    final clear = await _aesGcm.decrypt(
      SecretBox(fileCipher, nonce: fileIv, mac: fileMac),
      secretKey: SecretKey(dek),
    );

    return Uint8List.fromList(clear);
  }

  static String b64(Uint8List data) => base64Encode(data);
  static Uint8List b64d(String s) => Uint8List.fromList(base64Decode(s));
}