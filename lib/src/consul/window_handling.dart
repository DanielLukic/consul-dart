part of 'desktop.dart';

abstract mixin class _WindowHandling {
  final _windows = <Window>[];
  final _buffer = Buffer(0, 0);
  final _differ = Buffer(0, 0);

  final _restoreSizes = <Window, Size>{};

  Cell _background = Cell('░'.codeUnits.first);

  abstract Window? _focused;

  Window? get _dialog;

  void _updateRow(int row, String data);

  _removeWindow(Window window) {
    _windows.remove(window);
    _restoreSizes.remove(window);
  }

  _redrawDesktop({required int columns, required int rows}) {
    _buffer.update(columns, rows);
    _differ.update(columns, rows);
    _drawBackground();
    _drawWindows(columns, rows, _windows);
    _drawDialog(columns, rows);
    _updateOutput();
  }

  _drawBackground() => _buffer.fillWithCell(_background);

  void _drawDialog(int columns, int rows) {
    final dialog = _dialog;
    if (dialog != null) {
      final background = _buffer.frame().split('\n');
      final dimmed = background.map((e) => e.stripped().dim().gray());
      _buffer.drawRows(0, 0, dimmed);
      _drawWindows(columns, rows, [dialog]);
    }
  }

  _drawWindows(int columns, int rows, List<Window> windows) {
    for (var window in windows) {
      if (window.state == WindowState.minimized) continue;
      _layoutWindow(window);

      final decoratedPosition = window.decoratedPosition();
      final buffer = window._decorateBuffer(window);
      if (buffer != null) {
        _buffer.drawBuffer(decoratedPosition.x, decoratedPosition.y, buffer);
      }

      for (final overlay in window._overlays) {
        final inside = VirtualBuffer(
          _buffer,
          decoratedPosition,
          window.size.current,
        );
        overlay.decorate(inside);
      }
    }
  }

  void _layoutWindow(Window window) {
    var size = window.size.current;
    if (size == Size.autoFill) window._resize(_buffer.width, _buffer.height);
    if (size.height == Size.autoSize) {
      window._resize(window.width, _buffer.height);
    }
    if (size.width == Size.autoSize) {
      window._resize(_buffer.width, window.height);
    }
    if (window.position == Position.unsetInitially) {
      window.position = RelativePosition.autoCentered();
    }
  }

  void _updateOutput() {
    for (final (index, line) in _differ._buffer.indexed) {
      final now = _buffer._buffer[index];
      final same =
          now.indexed.every((element) => line[element.$1] == element.$2);
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

  String get background => String.fromCharCode(_background.charCode);

  @override
  Window? get _dialog => null;

  void drawFrame() {
    _redrawDesktop(columns: 40, rows: 10);
    dump();
  }

  void addWindow(Window it) {
    _windows.add(it);
    it._desktopSize = () => Size(40, 10);
  }

  @override
  void _updateRow(int row, String data) => lines[row] = data;

  @override
  Window? _focused;

  String line(int row) => ansiStripped(lines[row]!);

  void dump() {
    print(lines.values.join("\n"));
    print("");
  }
}
