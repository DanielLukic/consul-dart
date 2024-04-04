part of 'desktop.dart';

abstract mixin class _WindowHandling {
  final _windows = <Window>[];
  final _buffer = Buffer(0, 0);
  final _differ = Buffer(0, 0);

  final _decorators = <Window, DecoratedWindow>{};
  final _restoreSizes = <Window, Size>{};

  int _background = '░'.codeUnits.first;

  abstract Window? _focused;

  void _updateRow(int row, String data);

  _removeWindow(Window window) {
    _windows.remove(window);
    _decorators.remove(window);
    _restoreSizes.remove(window);
  }

  _redrawDesktop({required int columns, required int rows}) {
    _buffer.update(columns, rows);
    _differ.update(columns, rows);
    _drawBackground();
    _drawWindows(columns, rows);
    _updateOutput();
  }

  _drawBackground() => _buffer.fill(_background);

  _drawWindows(int columns, int rows) {
    final desktop = Size(columns, rows);
    for (var window in _windows) {
      if (window.state == WindowState.minimized) continue;
      _layoutWindow(window);

      final decorated = _decorators.putIfAbsent(window, () => DecoratedWindow.decorate(window));
      final decoratedPosition = decorated.decoratedPosition(desktop);
      final buffer = decorated.redrawBuffer();
      if (buffer != null) _buffer.drawBuffer(decoratedPosition.x, decoratedPosition.y, buffer);

      for (final overlay in window._overlays) {
        final inside = VirtualBuffer(_buffer, decoratedPosition, decorated.size.current);
        overlay.decorate(inside);
      }
    }
  }

  void _layoutWindow(Window window) {
    var size = window.size.current;
    if (size == Size.autoFill) {
      window._resize(_buffer.width, _buffer.height);
    }
    if (window.position == Position.unsetInitially) {
      window.position = RelativePosition.autoCentered();
    }
  }

  void _updateOutput() {
    for (final (index, line) in _differ._buffer.indexed) {
      final now = _buffer._buffer[index];
      final same = now.indexed.every((element) => line[element.$1] == element.$2);
      if (same) continue;
      for (var x = 0; x < now.length; x++) {
        line[x] = now[x];
      }
      _updateRow(index, now.join());
    }
  }
}

// TODO Is there a better way to make the somewhat internal WindowHandling testable?
// TODO What would be the Dart equivalent of Kotlin `internal`?
class MockWindowHandling with _WindowHandling {
  final lines = <int, String>{};

  String get background => String.fromCharCode(_background);

  void drawFrame() => _redrawDesktop(columns: 40, rows: 10);

  void addWindow(Window it) => _windows.add(it);

  @override
  void _updateRow(int row, String data) => lines[row] = data;

  @override
  Window? _focused;
}
