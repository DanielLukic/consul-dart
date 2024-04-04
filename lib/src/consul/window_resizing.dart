part of 'desktop.dart';

class _WindowResizing with KeyHandling implements WindowOverlay {
  final Size _desktop;
  final Window _window;
  final Function _onDone;

  _WindowResizing(this._desktop, this._window, this._onDone) {
    onKey("<Enter>", done);
    onKey("<Escape>", done);
    onKey("<Return>", done);
    onKey("q", done);

    onKey("<Down>", () => resize(0, 1));
    onKey("<Left>", () => resize(-1, 0));
    onKey("<Right>", () => resize(1, 0));
    onKey("<Up>", () => resize(0, -1));
    onKey("h", () => resize(-1, 0));
    onKey("j", () => resize(0, 1));
    onKey("k", () => resize(0, -1));
    onKey("l", () => resize(1, 0));

    _window.addOverlay(this);
  }

  resize(int dx, int dy) {
    eventDebugLog.clear();
    eventDebugLog.add("resize: $dx $dy");
    eventDebugLog.add("current: ${_window.size.current}");
    eventDebugLog.add("min: ${_window.size.min}");
    eventDebugLog.add("max: ${_window.size.max}");

    final fixPosition = _window.position.toAbsolute(_desktop, _window.size.current);
    _window.position = fixPosition;

    final current = _window.size.current;
    final w = current.width + dx;
    final h = current.height + dy;
    final minSize = _window.size.min.ifAutoFill(_desktop);
    final maxSize = _window.size.max.ifAutoFill(_desktop);
    final ww = w.clamp(minSize.width, maxSize.width);
    final hh = h.clamp(minSize.height, maxSize.height);
    _window._resize(max(16, ww), max(2, hh)); // 16 for titlebar, 2 for titlebar + resize control
  }

  done() {
    _window.removeOverlay(this);
    _onDone();
  }

  @override
  void decorate(OverlayBuffer buffer) {
    if (_window.height < 8) return;
    final x = buffer.width ~/ 2;
    final y = (buffer.height ~/ 2 - 0.5).round();
    buffer.draw(x - 3, y - 3, cross);
  }

  final cross = ""
      "░░░░░░░\n"
      "░░░▼░░░\n"
      "░░░ ░░░\n"
      "░▶ ? ◀░\n"
      "░░░ ░░░\n"
      "░░░▲░░░\n"
      "░░░░░░░\n";
}

extension on Size {
  Size ifAutoFill(Size alt) => this == Size.autoFill ? alt : this;
}
