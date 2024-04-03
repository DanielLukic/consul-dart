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
      final buffer = decorated.redrawBuffer();
      if (buffer != null) {
        AbsolutePosition p;
        if (window.isMaximized) {
          p = Position.topLeft;
        } else {
          p = decorated.position.toAbsolute(desktop, window.size.current);
        }
        _buffer.drawBuffer(p.x, p.y, buffer);
      }
    }
  }

  void _layoutWindow(Window window) {
    var size = window.size.current;
    if (size == Size.autoFill) {
      window.resize(_buffer.width, _buffer.height);
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
