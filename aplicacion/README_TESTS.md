# 📚 Guía de Pruebas Unitarias - Proyecto Caja Fuerte

## 📋 Índice
1. [Introducción](#introducción)
2. [¿Qué son las Pruebas Unitarias?](#qué-son-las-pruebas-unitarias)
3. [Estructura del Proyecto de Pruebas](#estructura-del-proyecto-de-pruebas)
4. [Cómo Ejecutar las Pruebas](#cómo-ejecutar-las-pruebas)
5. [Cómo Escribir Pruebas Unitarias](#cómo-escribir-pruebas-unitarias)
6. [Ejemplos Prácticos](#ejemplos-prácticos)
7. [Mejores Prácticas](#mejores-prácticas)
8. [Glosario de Términos](#glosario-de-términos)

---

## 🎯 Introducción

Esta guía te enseñará cómo crear y ejecutar pruebas unitarias para la aplicación **Caja Fuerte**. Las pruebas unitarias son una práctica fundamental en el desarrollo de software que garantiza la calidad y confiabilidad de tu código.

### ¿Por qué son importantes las pruebas unitarias?

- ✅ **Detectan errores temprano**: Encuentran bugs antes de que lleguen a producción
- ✅ **Facilitan el mantenimiento**: Te permiten refactorizar con confianza
- ✅ **Documentan el código**: Sirven como documentación viva de cómo debe funcionar el código
- ✅ **Aceleran el desarrollo**: Permiten desarrollar con más agilidad y seguridad

---

## 📖 ¿Qué son las Pruebas Unitarias?

Una **prueba unitaria** es una pieza de código que verifica que una unidad específica de código (función, método o clase) funcione correctamente.

### Características de una buena prueba unitaria:

1. **Aislada**: Cada prueba es independiente de las demás
2. **Repetible**: Siempre produce el mismo resultado
3. **Rápida**: Se ejecuta en milisegundos
4. **Automática**: No requiere intervención manual

---

## 📁 Estructura del Proyecto de Pruebas

En Flutter, las pruebas unitarias se colocan en el directorio `test/`, replicando la estructura de `lib/`:

```
aplicacion/
├── lib/
│   ├── models/
│   │   └── vault_file.dart
│   └── services/
│       ├── crypto_service.dart
│       └── vault_repository.dart
└── test/
    ├── models/
    │   └── vault_file_meta_test.dart
    └── services/
        └── crypto_service_test.dart
```

---

## 🚀 Cómo Ejecutar las Pruebas

### 1. Ejecutar todas las pruebas

```bash
cd aplicacion
flutter test
```

### 2. Ejecutar un archivo de pruebas específico

```bash
flutter test test/services/crypto_service_test.dart
```

### 3. Ejecutar pruebas con cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Esto generará un reporte HTML en `coverage/html/` que puedes abrir en tu navegador.

### 4. Ejecutar pruebas en modo verbose (más información)

```bash
flutter test --verbose
```

### 5. Ejecutar pruebas continuamente (watch mode)

```bash
flutter test --watch
```

---

## ✍️ Cómo Escribir Pruebas Unitarias

### Anatomía de una Prueba Unitaria en Flutter

Cada archivo de prueba sigue esta estructura básica:

```dart
import 'package:flutter_test/flutter_test.dart';

// Tu código a probar
import 'package:flutter_application_1/services/mi_servicio.dart';

/// Documentación del conjunto de pruebas
void main() {
  // Agrupa pruebas relacionadas
  group('NombreDelGrupo', () {

    setUp(() {
      // Código que se ejecuta ANTES de cada prueba
    });

    tearDown(() {
      // Código que se ejecuta DESPUÉS de cada prueba
    });

    // Una prueba individual
    test('debe hacer algo específico', () {
      // Arrange: Preparar los datos necesarios
      final esperado = 10;
      final actual = 5 + 5;

      // Act: Ejecutar la operación a probar
      // (En este caso ya lo calculamos arriba)

      // Assert: Verificar el resultado
      expect(actual, equals(esperado));
    });
  });
}
```

### Partes de una Prueba:

#### 1. **Arrange (Preparar)**
Preparar los datos y el entorno necesario para la prueba.

```dart
// Arrange
final cryptoService = CryptoService.instance;
final datosOriginales = Uint8List.fromList([1, 2, 3, 4, 5]);
final kek = Uint8List(32);
```

#### 2. **Act (Actuar)**
Ejecutar la operación que queremos probar.

```dart
// Act
final resultado = await cryptoService.encryptWithWrappedKey(
  data: datosOriginales,
  kek: kek,
);
```

#### 3. **Assert (Verificar)**
Comprobar que el resultado sea el esperado.

```dart
// Assert
expect(resultado['cipher'], isNotNull);
expect(resultado['cipher'], isNot(equals(datosOriginales)));
```

---

## 💡 Ejemplos Prácticos

### Ejemplo 1: Prueba Simple

```dart
test('2 + 2 debe ser igual a 4', () {
  // Arrange
  final numero1 = 2;
  final numero2 = 2;

  // Act
  final resultado = numero1 + numero2;

  // Assert
  expect(resultado, equals(4));
});
```

### Ejemplo 2: Prueba de Cifrado (CryptoService)

```dart
test('debería cifrar y descifrar datos correctamente', () async {
  // Arrange: Preparamos los datos de prueba
  final datosOriginales = Uint8List.fromList([1, 2, 3, 4, 5]);
  final kek = Uint8List(32);

  // Act: Ciframos los datos
  final cifrado = await cryptoService.encryptWithWrappedKey(
    data: datosOriginales,
    kek: kek,
  );

  // Desciframos los datos
  final descifrado = await cryptoService.decryptWithWrappedKey(
    cipherWithTag: cifrado['cipher']!,
    fileIv: cifrado['fileIv']!,
    dekWrappedWithTag: cifrado['dekWrapped']!,
    dekWrapIv: cifrado['dekWrapIv']!,
    kek: kek,
  );

  // Assert: Los datos descifrados deben ser iguales a los originales
  expect(descifrado, equals(datosOriginales));
});
```

### Ejemplo 3: Prueba de Serialización (VaultFileMeta)

```dart
test('debe convertir a JSON correctamente', () {
  // Arrange: Creamos un objeto
  final archivo = VaultFileMeta(
    id: 'test-123',
    originalName: 'documento.pdf',
    mimeType: 'application/pdf',
    originalSize: 1024,
    createdAt: DateTime.now(),
    dekWrappedB64: 'abc123',
    dekWrapIvB64: 'def456',
    fileIvB64: 'ghi789',
  );

  // Act: Convertimos a JSON
  final json = archivo.toJson();

  // Assert: Verificamos que todos los campos estén presentes
  expect(json['id'], equals('test-123'));
  expect(json['originalName'], equals('documento.pdf'));
  expect(json['mimeType'], equals('application/pdf'));
});
```

---

## 🎯 Mejores Prácticas

### 1. Nombre tus pruebas de manera descriptiva

✅ **Bueno:**
```dart
test('debería cifrar y descifrar datos correctamente', () { ... });
```

❌ **Malo:**
```dart
test('test1', () { ... });
```

### 2. Usa el patrón AAA (Arrange, Act, Assert)

```dart
test('ejemplo de patrón AAA', () {
  // Arrange: Prepara los datos
  final dato = 5;

  // Act: Ejecuta la operación
  final resultado = dato * 2;

  // Assert: Verifica el resultado
  expect(resultado, equals(10));
});
```

### 3. Agrupa pruebas relacionadas con `group()`

```dart
group('CryptoService - Cifrado', () {
  test('prueba de cifrado 1', () { ... });
  test('prueba de cifrado 2', () { ... });
});

group('CryptoService - Descifrado', () {
  test('prueba de descifrado 1', () { ... });
});
```

### 4. Prueba casos extremos

```dart
test('debe manejar archivos vacíos', () async {
  final datosVacios = Uint8List(0);
  // ... prueba
});

test('debe manejar archivos grandes', () async {
  final datosGrandes = Uint8List(1024 * 1024); // 1 MB
  // ... prueba
});
```

### 5. Mantén las pruebas independientes

```dart
group('Pruebas Independientes', () {
  test('prueba 1', () { ... });
  test('prueba 2', () { ... }); // No depende de prueba 1
});
```

### 6. Verifica que los errores se lancen cuando corresponde

```dart
test('debe lanzar excepción cuando los datos son inválidos', () {
  expect(
    () => miFuncion(null),
    throwsA(isA<ArgumentError>()),
  );
});
```

---

## 📚 Glosario de Términos

| Término | Significado |
|---------|-------------|
| **Test** | Una prueba individual que verifica un comportamiento específico |
| **Group** | Agrupación de pruebas relacionadas |
| **SetUp** | Código que se ejecuta antes de cada prueba |
| **TearDown** | Código que se ejecuta después de cada prueba |
| **Assert** | Verificación de que el resultado es el esperado |
| **Expect** | Método para verificar condiciones en Flutter |
| **Mock** | Objeto simulado que imita el comportamiento de objetos reales |
| **Coverage** | Porcentaje de código ejecutado por las pruebas |
| **Unit Test** | Prueba que verifica una unidad de código aislada |
| **Integration Test** | Prueba que verifica la integración entre múltiples componentes |

---

## 🛠️ Comandos Útiles de Flutter Test

```bash
# Ejecutar todas las pruebas
flutter test

# Ejecutar con información de cobertura
flutter test --coverage

# Ejecutar pruebas en modo watch (se re-ejecutan automáticamente)
flutter test --watch

# Ejecutar solo pruebas que contengan un nombre específico
flutter test --name "cifrado"

# Ejecutar pruebas de forma aleatoria
flutter test --test-randomize-ordering-seed=12345
```

---

## 📝 Tareas Prácticas

Para practicar lo aprendido, intenta crear pruebas para:

1. ✅ **CryptoService** - Ya están creadas en `test/services/crypto_service_test.dart`
2. ✅ **VaultFileMeta** - Ya están creadas en `test/models/vault_file_meta_test.dart`
3. 🔨 **VaultRepository** - Crea pruebas para los métodos:
   - `listAll()`
   - `importFile()`
   - `exportClear()`
   - `deleteById()`
4. 🔨 **LockManager** - Crea pruebas para:
   - `unlock()`
   - `lock()`
   - `isUnlocked`

---

## 🎓 Recursos Adicionales

- [Documentación oficial de Flutter Testing](https://docs.flutter.dev/testing)
- [Pruebas en Flutter - Codelab](https://codelabs.developers.google.com/codelabs/flutter-app-testing)
- [Guía de Testing de Dart](https://dart.dev/guides/testing)

---

## ❓ Preguntas Frecuentes

### ¿Qué porcentaje de cobertura debo tener?

**R:** Idealmente, intenta tener más del 80% de cobertura de código. Sin embargo, la calidad de las pruebas es más importante que el porcentaje.

### ¿Debo probar métodos privados?

**R:** No directamente. En su lugar, prueba el comportamiento público de la clase que utiliza esos métodos privados.

### ¿Cuántas pruebas debo escribir por método?

**R:** Lo suficiente para cubrir todos los casos: happy path (caso exitoso), casos extremos y casos de error.

---

## 👨‍🏫 Conclusión

Las pruebas unitarias son una herramienta esencial para el desarrollo de software de calidad. Al aprender a escribir pruebas efectivas, podrás:

- Desarrollar con más confianza
- Detectar errores más temprano
- Refactorizar sin miedo
- Documentar tu código de manera viva

¡Ahora estás listo para empezar a escribir tus propias pruebas unitarias! 🚀

---

**Autor:** Guía creada para el proyecto Caja Fuerte - Electiva
**Fecha:** 2024
