part of 'desktop.dart';

class _WindowResizing with KeyHandling implements WindowOverlay {
  final Window _window;
  final Function _onDone;

  _WindowResizing(this._window, this._onDone) {
    onKey("<Enter>", description: "Finish window resizing", action: done);
    onKey("<Escape>", description: "Finish window resizing", action: done);
    onKey("<Return>", description: "Finish window resizing", action: done);
    onKey("q", description: "Finish window resizing", action: done);

    onKey("<Down>", description: "Extend down", action: () => resize(0, 1));
    onKey("<Left>", description: "Extend left", action: () => resize(-1, 0));
    onKey("<Right>", description: "Extend right", action: () => resize(1, 0));
    onKey("<Up>", description: "Extend up", action: () => resize(0, -1));

    onKey("<S-h>", description: "Extend left", action: () => resize(-10, 0));
    onKey("<S-j>", description: "Extend down", action: () => resize(0, 5));
    onKey("<S-k>", description: "Extend up", action: () => resize(0, -5));
    onKey("<S-l>", description: "Extend right", action: () => resize(10, 0));
    onKey("h", description: "Extend left", action: () => resize(-1, 0));
    onKey("j", description: "Extend down", action: () => resize(0, 1));
    onKey("k", description: "Extend up", action: () => resize(0, -1));
    onKey("l", description: "Extend right", action: () => resize(1, 0));

    _window.addOverlay(this);
  }

  resize(int dx, int dy) {
    eventDebugLog.clear();
    eventDebugLog.add("resize: $dx $dy");
    eventDebugLog.add("current: ${_window.size.current}");
    eventDebugLog.add("min: ${_window.size.min}");
    eventDebugLog.add("max: ${_window.size.max}");

    final current = _window.size.current;
    _window.fixPosition();
    _window._resizeClamped(current.width + dx, current.height + dy);
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
