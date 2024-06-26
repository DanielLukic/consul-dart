part of 'desktop.dart';

class _WindowResizing with KeyHandling implements WindowOverlay {
  final Window _window;
  final Function _onDone;

  _WindowResizing(this._window, this._onDone) {
    onKey("q",
        aliases: ['<Return>', '<Escape>'],
        description: "Finish window resizing",
        action: done);

    onKey("<S-h>",
        aliases: ['<S-Left>'],
        description: "Extend left",
        action: () => resize(-10, 0));
    onKey("<S-j>",
        aliases: ['<S-Down>'],
        description: "Extend down",
        action: () => resize(0, 5));
    onKey("<S-k>",
        aliases: ['<S-Up>'],
        description: "Extend up",
        action: () => resize(0, -5));
    onKey("<S-l>",
        aliases: ['<S-Right'],
        description: "Extend right",
        action: () => resize(10, 0));

    onKey("h",
        aliases: ['<Left>'],
        description: "Extend left",
        action: () => resize(-1, 0));
    onKey("j",
        aliases: ['<Down>'],
        description: "Extend down",
        action: () => resize(0, 1));
    onKey("k",
        aliases: ['<Up>'],
        description: "Extend up",
        action: () => resize(0, -1));
    onKey("l",
        aliases: ['<Right>'],
        description: "Extend right",
        action: () => resize(1, 0));

    _window.addOverlay(this);
  }

  resize(int dx, int dy) {
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
