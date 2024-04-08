part of 'desktop.dart';

abstract mixin class FocusHandling {
  abstract final List<Window> _windows;

  void redraw();
  Window? _focused;

  _updateFocus() {
    final current = _focused;
    _focused =
        _windows.lastWhereOrNull((it) => it.focusable && !it.isMinimized);
    if (current == _focused) return;

    current?.onStateChanged.notifyAll();
    _focused?.onStateChanged.notifyAll();
    current?.onFocusChanged.notifyAll();
    _focused?.onFocusChanged.notifyAll();
    redraw();
  }

  void focusPrevious() {
    final current = _focused;
    if (current == null) {
      _updateFocus();
      return;
    }

    final nextIndex = _windows.indexWhere((element) => element.focusable);
    if (nextIndex == -1 || _windows[nextIndex] == current) return;

    final next = _windows.removeAt(nextIndex);
    _windows.add(next);
    _updateFocus();
  }

  void focusNext() {
    final current = _focused;
    if (current == null) {
      _updateFocus();
      return;
    }

    final firstIndex = _windows.indexWhere((element) => element.focusable);
    if (firstIndex == -1 || _windows[firstIndex] == current) return;

    _windows.remove(current);
    _windows.insert(firstIndex, current);
    _updateFocus();
  }
}
