import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/vault_file.dart';
import 'crypto_service.dart';

class VaultRepository {
  VaultRepository._();
  static final VaultRepository instance = VaultRepository._();

  final _uuid = const Uuid();

  Future<Directory> _ensureVaultDir() async {
    final dir = await getApplicationSupportDirectory();
    final vault = Directory('${dir.path}/vault');
    if (!await vault.exists()) {
      await vault.create(recursive: true);
    }
    return vault;
  }

  Future<File> _metaFile(String id) async {
    final vault = await _ensureVaultDir();
    return File('${vault.path}/$id.json');
  }

  Future<File> _dataFile(String id) async {
    final vault = await _ensureVaultDir();
    return File('${vault.path}/$id.enc');
  }

  Future<List<VaultFileMeta>> listAll() async {
    try {
      final vault = await _ensureVaultDir();
      final files = (await vault.list().toList()).whereType<File>();

      final out = <VaultFileMeta>[];
      for (final metaFile in files.where((f) => f.path.endsWith('.json'))) {
        try {
          final content = await metaFile.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          out.add(VaultFileMeta.fromJson(json));
        } catch (e) {
          print('Error reading file ${metaFile.path}: $e');
        }
      }
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } catch (e) {
      print('Error listing vault files: $e');
      return [];
    }
  }

  Future<VaultFileMeta> importFile({
    required File source,
    required String mimeType,
    required Uint8List kek,
  }) async {
    final id = _uuid.v4();
    final bytes = await source.readAsBytes();
    final bundle = await CryptoService.instance.encryptWithWrappedKey(
      data: bytes,
      kek: kek,
    );

    final meta = VaultFileMeta(
      id: id,
      originalName: source.uri.pathSegments.last,
      mimeType: mimeType,
      originalSize: bytes.length,
      createdAt: DateTime.now(),
      dekWrappedB64: CryptoService.b64(bundle['dekWrapped']!),
      dekWrapIvB64: CryptoService.b64(bundle['dekWrapIv']!),
      fileIvB64: CryptoService.b64(bundle['fileIv']!),
    );

    final dataFile = await _dataFile(id);
    final metaFile = await _metaFile(id);

    await dataFile.writeAsBytes(bundle['cipher']!, flush: true);
    await metaFile.writeAsString(jsonEncode(meta.toJson()), flush: true);

    return meta;
  }

  Future<Uint8List> exportClear({
    required String id,
    required Uint8List kek,
  }) async {
    final metaFile = await _metaFile(id);
    if (!await metaFile.exists()) {
      throw Exception('Archivo no encontrado');
    }

    final meta = VaultFileMeta.fromJson(
      jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>,
    );

    final dataFile = await _dataFile(id);
    final cipher = await dataFile.readAsBytes();

    return await CryptoService.instance.decryptWithWrappedKey(
      cipherWithTag: cipher,
      fileIv: CryptoService.b64d(meta.fileIvB64),
      dekWrappedWithTag: CryptoService.b64d(meta.dekWrappedB64),
      dekWrapIv: CryptoService.b64d(meta.dekWrapIvB64),
      kek: kek,
    );
  }

  Future<void> deleteById(String id) async {
    try {
      final metaFile = await _metaFile(id);
      final dataFile = await _dataFile(id);
      if (await metaFile.exists()) await metaFile.delete();
      if (await dataFile.exists()) await dataFile.delete();
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> wipeAll() async {
    try {
      final vault = await _ensureVaultDir();
      if (await vault.exists()) {
        final contents = await vault.list().toList();
        for (final entity in contents) {
          try {
            if (entity is File) await entity.delete();
          } catch (e) {
            print('Error deleting ${entity.path}: $e');
          }
        }
      }
    } catch (e) {
      print('Error wiping vault: $e');
    }
  }
}