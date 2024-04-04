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

    final current = _window.size.current;
    _window._resizeClamped(current.width + dx, current.height + dy, _desktop);
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
