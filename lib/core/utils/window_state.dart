import 'dart:async';
import 'dart:convert';

import 'package:zedu/core/core.dart';

class WindowState {
  const WindowState({required this.bounds, required this.isMaximized});

  final Rect bounds;
  final bool isMaximized;

  static const double minWidth = 400;
  static const double minHeight = 300;
  static const double maxExtent = 20000;

  String encode() => jsonEncode({
    'left': bounds.left,
    'top': bounds.top,
    'width': bounds.width,
    'height': bounds.height,
    'maximized': isMaximized,
  });

  static WindowState? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final left = (decoded['left'] as num?)?.toDouble();
      final top = (decoded['top'] as num?)?.toDouble();
      final width = (decoded['width'] as num?)?.toDouble();
      final height = (decoded['height'] as num?)?.toDouble();
      if (left == null || top == null || width == null || height == null) {
        return null;
      }
      if (![left, top, width, height].every((value) => value.isFinite)) {
        return null;
      }
      if (width < minWidth ||
          height < minHeight ||
          width > maxExtent ||
          height > maxExtent ||
          left.abs() > maxExtent ||
          top.abs() > maxExtent) {
        return null;
      }
      return WindowState(
        bounds: Rect.fromLTWH(left, top, width, height),
        isMaximized: decoded['maximized'] == true,
      );
    } on FormatException {
      return null;
    }
  }
}

class WindowStateStore {
  WindowStateStore(this._storage);

  final SecureStorageService _storage;

  static const _storageKey = 'desktop_window_state';

  Future<void> restore() async {
    try {
      final state = WindowState.tryParse(await _storage.readData(_storageKey));
      if (state == null) return;
      if (state.isMaximized) {
        await windowManager.maximize();
      } else {
        await windowManager.setBounds(state.bounds);
      }
    } catch (error, stackTrace) {
      AppLogger.w(
        'Failed to restore window state',
        tag: 'WindowStateStore',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> save() async {
    try {
      final isMaximized = await windowManager.isMaximized();
      final bounds = await windowManager.getBounds();
      final state = WindowState(bounds: bounds, isMaximized: isMaximized);
      await _storage.writeData(_storageKey, state.encode());
    } catch (error, stackTrace) {
      AppLogger.w(
        'Failed to save window state',
        tag: 'WindowStateStore',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class WindowStateTracker with WindowListener {
  WindowStateTracker(this._store);

  final WindowStateStore _store;
  Timer? _saveTimer;

  void attach() => windowManager.addListener(this);

  void detach() {
    _saveTimer?.cancel();
    windowManager.removeListener(this);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _store.save);
  }

  @override
  void onWindowResize() => _scheduleSave();

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMove() => _scheduleSave();

  @override
  void onWindowMoved() => _scheduleSave();

  @override
  void onWindowMaximize() => _scheduleSave();

  @override
  void onWindowUnmaximize() => _scheduleSave();
}
