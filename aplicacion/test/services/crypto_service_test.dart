import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/crypto_service.dart';

/// ## Pruebas Unitarias para CryptoService
///
/// Este archivo contiene las pruebas unitarias para el servicio de criptografía.
/// Las pruebas verifican que el cifrado y descifrado de datos funcionen correctamente.
///
/// ### Objetivos de las Pruebas:
/// - Verificar que el cifrado produzca datos diferentes a los originales
/// - Verificar que el descifrado recupere los datos originales correctamente
/// - Verificar que se generen vectores aleatorios diferentes
/// - Verificar que el formato de base64 funcione correctamente
void main() {
  group('CryptoService - Pruebas de Cifrado y Descifrado', () {
    late CryptoService cryptoService;

    setUp(() {
      cryptoService = CryptoService.instance;
    });

    test(
      'debería cifrar y descifrar datos correctamente',
      () async {
        // Arrange: Datos de prueba y KEK (Key Encryption Key)
        final originalData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
        final kek = Uint8List(32); // KEK de 32 bytes (256 bits)
        for (int i = 0; i < 32; i++) {
          kek[i] = i;
        }

        // Act: Cifrar los datos
        final encrypted = await cryptoService.encryptWithWrappedKey(
          data: originalData,
          kek: kek,
        );

        // Assert: Verificar que el resultado contiene los campos esperados
        expect(encrypted['cipher'], isNotNull);
        expect(encrypted['fileIv'], isNotNull);
        expect(encrypted['dekWrapped'], isNotNull);
        expect(encrypted['dekWrapIv'], isNotNull);

        // Act: Descifrar los datos
        final decryptedData = await cryptoService.decryptWithWrappedKey(
          cipherWithTag: encrypted['cipher']!,
          fileIv: encrypted['fileIv']!,
          dekWrappedWithTag: encrypted['dekWrapped']!,
          dekWrapIv: encrypted['dekWrapIv']!,
          kek: kek,
        );

        // Assert: Los datos descifrados deben ser iguales a los originales
        expect(decryptedData, equals(originalData));
      },
    );

    test(
      'el cifrado debe producir datos diferentes a los originales',
      () async {
        // Arrange
        final originalData = Uint8List.fromList([10, 20, 30, 40, 50]);
        final kek = cryptoService.randomBytes(32);

        // Act
        final encrypted = await cryptoService.encryptWithWrappedKey(
          data: originalData,
          kek: kek,
        );

        // Assert: Los datos cifrados deben ser diferentes a los originales
        expect(encrypted['cipher'], isNot(equals(originalData)));

        // El tamaño del cifrado debe ser mayor debido al tag MAC (16 bytes adicionales)
        expect(encrypted['cipher']!.length, greaterThan(originalData.length));
      },
    );

    test(
      'debe generar vectores de inicialización únicos en cada cifrado',
      () async {
        // Arrange
        final data = Uint8List.fromList([1, 2, 3]);
        final kek = cryptoService.randomBytes(32);

        // Act: Cifrar dos veces el mismo dato
        final encrypt1 = await cryptoService.encryptWithWrappedKey(
          data: data,
          kek: kek,
        );
        final encrypt2 = await cryptoService.encryptWithWrappedKey(
          data: data,
          kek: kek,
        );

        // Assert: Los IVs deben ser diferentes (cifrados aleatorios)
        expect(encrypt1['fileIv'], isNot(equals(encrypt2['fileIv'])));
        expect(encrypt1['dekWrapIv'], isNot(equals(encrypt2['dekWrapIv'])));

        // Los datos cifrados deben ser diferentes
        expect(encrypt1['cipher'], isNot(equals(encrypt2['cipher'])));
      },
    );

    test(
      'debe funcionar con archivos grandes',
      () async {
        // Arrange: Crear datos de tamaño considerable
        final largeData = Uint8List(1024 * 100); // 100 KB
        for (int i = 0; i < largeData.length; i++) {
          largeData[i] = i % 256;
        }
        final kek = cryptoService.randomBytes(32);

        // Act
        final encrypted = await cryptoService.encryptWithWrappedKey(
          data: largeData,
          kek: kek,
        );

        final decrypted = await cryptoService.decryptWithWrappedKey(
          cipherWithTag: encrypted['cipher']!,
          fileIv: encrypted['fileIv']!,
          dekWrappedWithTag: encrypted['dekWrapped']!,
          dekWrapIv: encrypted['dekWrapIv']!,
          kek: kek,
        );

        // Assert
        expect(decrypted, equals(largeData));
      },
    );

    test(
      'la función de conversión base64 debe funcionar correctamente',
      () {
        // Arrange
        final originalData = Uint8List.fromList([65, 66, 67, 68]); // "ABCD"

        // Act
        final base64String = CryptoService.b64(originalData);
        final decodedData = CryptoService.b64d(base64String);

        // Assert
        expect(decodedData, equals(originalData));
        expect(base64String, isA<String>());
      },
    );

    test(
      'randomBytes debe generar bytes diferentes en cada llamada',
      () {
        // Arrange & Act
        final bytes1 = cryptoService.randomBytes(32);
        final bytes2 = cryptoService.randomBytes(32);

        // Assert: Dos llamadas consecutivas deben producir resultados diferentes
        // (con alta probabilidad debido a la aleatoriedad)
        expect(bytes1.length, equals(32));
        expect(bytes2.length, equals(32));
        expect(bytes1, isNot(equals(bytes2)));
      },
    );
  });
}
