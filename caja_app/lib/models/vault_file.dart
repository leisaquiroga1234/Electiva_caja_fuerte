import 'dart:convert';

class VaultFileMeta {
  final String id;
  final String originalName;
  final String mimeType;
  final int originalSize;
  final DateTime createdAt;
  final String dekWrappedB64; // DEK encrypted with KEK (AES-GCM)
  final String dekWrapIvB64; // IV used to wrap DEK (AES-GCM)
  final String fileIvB64; // IV used to encrypt file content (AES-GCM)

  const VaultFileMeta({
    required this.id,
    required this.originalName,
    required this.mimeType,
    required this.originalSize,
    required this.createdAt,
    required this.dekWrappedB64,
    required this.dekWrapIvB64,
    required this.fileIvB64,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalName': originalName,
        'mimeType': mimeType,
        'originalSize': originalSize,
        'createdAt': createdAt.toIso8601String(),
        'dekWrappedB64': dekWrappedB64,
        'dekWrapIvB64': dekWrapIvB64,
        'fileIvB64': fileIvB64,
      };

  factory VaultFileMeta.fromJson(Map<String, dynamic> j) => VaultFileMeta(
        id: j['id'] as String,
        originalName: j['originalName'] as String,
        mimeType: j['mimeType'] as String,
        originalSize: (j['originalSize'] as num).toInt(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        dekWrappedB64: j['dekWrappedB64'] as String,
        dekWrapIvB64: j['dekWrapIvB64'] as String,
        fileIvB64: j['fileIvB64'] as String,
      );

  String toPrettyString() => const JsonEncoder.withIndent('  ').convert(toJson());
}