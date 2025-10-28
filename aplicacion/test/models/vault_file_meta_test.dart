import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/vault_file.dart';

/// ## Pruebas Unitarias para VaultFileMeta
///
/// Este archivo contiene las pruebas unitarias para el modelo VaultFileMeta.
/// Las pruebas verifican la serialización y deserialización de archivos en la caja fuerte.
///
/// ### Objetivos de las Pruebas:
/// - Verificar serialización a JSON correcta
/// - Verificar deserialización desde JSON correcta
/// - Verificar que round-trip (JSON -> Objeto -> JSON) mantenga los datos
/// - Verificar que todos los campos se mapeen correctamente
void main() {
  group('VaultFileMeta - Pruebas de Serialización', () {
    final exampleDate = DateTime(2024, 1, 15, 10, 30, 0);

    test(
      'debe crear una instancia con todos los campos requeridos',
      () {
        // Arrange & Act
        final meta = VaultFileMeta(
          id: 'test-id-123',
          originalName: 'documento.pdf',
          mimeType: 'application/pdf',
          originalSize: 1024,
          createdAt: exampleDate,
          dekWrappedB64: 'wrapped_key_base64',
          dekWrapIvB64: 'wrap_iv_base64',
          fileIvB64: 'file_iv_base64',
        );

        // Assert
        expect(meta.id, equals('test-id-123'));
        expect(meta.originalName, equals('documento.pdf'));
        expect(meta.mimeType, equals('application/pdf'));
        expect(meta.originalSize, equals(1024));
        expect(meta.createdAt, equals(exampleDate));
        expect(meta.dekWrappedB64, equals('wrapped_key_base64'));
        expect(meta.dekWrapIvB64, equals('wrap_iv_base64'));
        expect(meta.fileIvB64, equals('file_iv_base64'));
      },
    );

    test(
      'debe convertir a JSON correctamente',
      () {
        // Arrange
        final meta = VaultFileMeta(
          id: 'test-id-456',
          originalName: 'imagen.jpg',
          mimeType: 'image/jpeg',
          originalSize: 2048,
          createdAt: exampleDate,
          dekWrappedB64: 'abc123',
          dekWrapIvB64: 'def456',
          fileIvB64: 'ghi789',
        );

        // Act
        final json = meta.toJson();

        // Assert
        expect(json['id'], equals('test-id-456'));
        expect(json['originalName'], equals('imagen.jpg'));
        expect(json['mimeType'], equals('image/jpeg'));
        expect(json['originalSize'], equals(2048));
        expect(json['createdAt'], equals(exampleDate.toIso8601String()));
        expect(json['dekWrappedB64'], equals('abc123'));
        expect(json['dekWrapIvB64'], equals('def456'));
        expect(json['fileIvB64'], equals('ghi789'));
      },
    );

    test(
      'debe deserializar desde JSON correctamente',
      () {
        // Arrange
        final json = {
          'id': 'test-id-789',
          'originalName': 'video.mp4',
          'mimeType': 'video/mp4',
          'originalSize': 4096,
          'createdAt': '2024-01-15T10:30:00.000',
          'dekWrappedB64': 'wrapped_key',
          'dekWrapIvB64': 'wrap_iv',
          'fileIvB64': 'file_iv',
        };

        // Act
        final meta = VaultFileMeta.fromJson(json);

        // Assert
        expect(meta.id, equals('test-id-789'));
        expect(meta.originalName, equals('video.mp4'));
        expect(meta.mimeType, equals('video/mp4'));
        expect(meta.originalSize, equals(4096));
        expect(meta.createdAt, equals(exampleDate));
        expect(meta.dekWrappedB64, equals('wrapped_key'));
        expect(meta.dekWrapIvB64, equals('wrap_iv'));
        expect(meta.fileIvB64, equals('file_iv'));
      },
    );

    test(
      'debe hacer round-trip correctamente (JSON -> Objeto -> JSON)',
      () {
        // Arrange
        final originalMeta = VaultFileMeta(
          id: 'test-id-roundtrip',
          originalName: 'documento.docx',
          mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          originalSize: 8192,
          createdAt: exampleDate,
          dekWrappedB64: 'very_long_wrapped_key_abc123',
          dekWrapIvB64: 'very_long_wrap_iv_def456',
          fileIvB64: 'very_long_file_iv_ghi789',
        );

        // Act: Serializar y deserializar
        final json = originalMeta.toJson();
        final reconstructed = VaultFileMeta.fromJson(json);

        // Assert: Todos los campos deben ser iguales
        expect(reconstructed.id, equals(originalMeta.id));
        expect(reconstructed.originalName, equals(originalMeta.originalName));
        expect(reconstructed.mimeType, equals(originalMeta.mimeType));
        expect(reconstructed.originalSize, equals(originalMeta.originalSize));
        expect(reconstructed.createdAt, equals(originalMeta.createdAt));
        expect(reconstructed.dekWrappedB64, equals(originalMeta.dekWrappedB64));
        expect(reconstructed.dekWrapIvB64, equals(originalMeta.dekWrapIvB64));
        expect(reconstructed.fileIvB64, equals(originalMeta.fileIvB64));
      },
    );

    test(
      'debe convertir correctamente cuando originalSize es num (double)',
      () {
        // Arrange: JSON con número decimal
        final json = {
          'id': 'test-id',
          'originalName': 'file.txt',
          'mimeType': 'text/plain',
          'originalSize': 512.0, // Num como double
          'createdAt': '2024-01-15T10:30:00.000',
          'dekWrappedB64': 'key',
          'dekWrapIvB64': 'iv1',
          'fileIvB64': 'iv2',
        };

        // Act
        final meta = VaultFileMeta.fromJson(json);

        // Assert: Debe convertir correctamente
        expect(meta.originalSize, equals(512));
        expect(meta.originalSize, isA<int>());
      },
    );

    test(
      'toPrettyString debe generar JSON formateado',
      () {
        // Arrange
        final meta = VaultFileMeta(
          id: 'pretty-test',
          originalName: 'documento.pdf',
          mimeType: 'application/pdf',
          originalSize: 1024,
          createdAt: exampleDate,
          dekWrappedB64: 'key',
          dekWrapIvB64: 'iv1',
          fileIvB64: 'iv2',
        );

        // Act
        final prettyString = meta.toPrettyString();

        // Assert
        expect(prettyString, isA<String>());
        expect(prettyString, contains('pretty-test'));
        expect(prettyString, contains('\n')); // Debe tener saltos de línea
      },
    );
  });
}
