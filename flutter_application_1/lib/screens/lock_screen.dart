import 'package:flutter/material.dart';  // Paquete externo (azul)
import '../services/lock_manager.dart';  // Archivo local (amarillo con m) - NORMAL


class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _unlock() async {
    setState(() { _busy = true; _error = null; });
    try {
      // 🟡 IMPORTANTE: Inicialización del gestor de bloqueo
      await LockManager.instance.init();
      final ok = await LockManager.instance.unlock();

      // 🟡 Navegación condicional
      if (ok && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        setState(() { _error = 'Autenticación fallida o cancelada'; });
      }
    } catch (e) {
      // 🟡 Manejo de errores
      setState(() { _error = 'Error: $e'; });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🟡 Elementos de UI clave
                const Icon(Icons.lock_outline, size: 96),
                const SizedBox(height: 16),
                const Text('Caja Segura',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),

                // 🟡 Botón principal con estado
                ElevatedButton.icon(
                  onPressed: _busy ? null : _unlock,
                  icon: const Icon(Icons.fingerprint),
                  label: _busy ? const Text('Desbloqueando...') : const Text('Desbloquear'),
                ),

                // 🟡 Mensaje de error condicional
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}