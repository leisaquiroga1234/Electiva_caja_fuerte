import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vault_file.dart';
import '../services/lock_manager.dart';
import '../services/vault_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<VaultFileMeta> _items = [];
  bool _busy = false;
  String? _error;
  final _fmt = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final all = await VaultRepository.instance.listAll();
      setState(() => _items = all);
    } catch (e) {
      setState(() => _error = 'Error cargando: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (!LockManager.instance.isUnlocked) {
      final ok = await LockManager.instance.unlock();
      if (!ok) return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      for (final f in result.files) {
        if (f.path == null) continue;
        final file = File(f.path!);
        await VaultRepository.instance.importFile(
          source: file,
          mimeType: f.extension ?? 'application/octet-stream',
          kek: LockManager.instance.kek!,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Importación completa')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Error importando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(VaultFileMeta meta) async {
    if (!LockManager.instance.isUnlocked) {
      final ok = await LockManager.instance.unlock();
      if (!ok) return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final bytes = await VaultRepository.instance.exportClear(
        id: meta.id,
        kek: LockManager.instance.kek!,
      );
      final xFile = XFile.fromData(
        bytes,
        name: meta.originalName,
        mimeType: meta.mimeType,
      );
      await Share.shareXFiles([xFile], text: 'Exportado desde Caja Segura');
    } catch (e) {
      setState(() => _error = 'Error exportando: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(VaultFileMeta meta) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar definitivamente "${meta.originalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await VaultRepository.instance.deleteById(meta.id);
      await _load();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      LockManager.instance.lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja Segura'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _import,
        icon: const Icon(Icons.add),
        label: const Text('Importar'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_busy) const LinearProgressIndicator(),
              Expanded(
                child: _items.isEmpty
                    ? const Center(
                        child: Text('No hay archivos. Usa "Importar" para agregar.'),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final m = _items[i];
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file_outlined),
                            title: Text(
                              m.originalName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${m.mimeType} • ${_fmt.format(m.createdAt)} • '
                              '${(m.originalSize / 1024).toStringAsFixed(1)} KB',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'export') await _export(m);
                                if (v == 'delete') await _delete(m);
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'export',
                                  child: Text('Exportar (descifrado)'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}