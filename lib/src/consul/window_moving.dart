part of 'desktop.dart';

class _WindowMoving with KeyHandling implements WindowOverlay {
  final Window _window;
  final Function _onStopMoving;

  _WindowMoving(this._window, this._onStopMoving) {
    onKey("q",
        aliases: ['<Return>', '<Escape>'],
        description: "Finish window moving",
        action: stopMoving);

    onKey("<S-h>",
        aliases: ['<S-Left>'],
        description: "Jump left",
        action: () => moveWindow(-10, 0));
    onKey("<S-j>",
        aliases: ['<S-Down>'],
        description: "Jump down",
        action: () => moveWindow(0, 5));
    onKey("<S-k>",
        aliases: ['<S-Up>'],
        description: "Jump up",
        action: () => moveWindow(0, -5));
    onKey("<S-l>",
        aliases: ['<S-Right>'],
        description: "Jump right",
        action: () => moveWindow(10, 0));

    onKey("h",
        aliases: ['<Left>'],
        description: "Move left",
        action: () => moveWindow(-1, 0));
    onKey("j",
        aliases: ['<Down>'],
        description: "Move down",
        action: () => moveWindow(0, 1));
    onKey("k",
        aliases: ['<Up>'],
        description: "Move up",
        action: () => moveWindow(0, -1));
    onKey("l",
        aliases: ['<Right>'],
        description: "Move right",
        action: () => moveWindow(1, 0));

    _window.addOverlay(this);
  }

  moveWindow(int dx, int dy) {
    _window.fixPosition();
    _window.position = _window.position.moved(dx, dy);
  }

  stopMoving() {
    _window.removeOverlay(this);
    _onStopMoving();
  }

  @override
  void decorate(OverlayBuffer buffer) {
    if (_window.height < 8) return;
    final x = buffer.width ~/ 2;
    final y = buffer.height ~/ 2;
    buffer.draw(x - 3, y - 3, cross);
  }

  final cross = ""
      "░░░░░░░\n"
      "░░░▲░░░\n"
      "░░░║░░░\n"
      "░◀═╬═▶░\n"
      "░░░║░░░\n"
      "░░░▼░░░\n"
      "░░░░░░░n";
}
