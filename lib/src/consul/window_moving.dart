part of 'desktop.dart';

class _WindowMoving with KeyHandling implements WindowOverlay {
  final Window _window;
  final Function _onStopMoving;

  _WindowMoving(this._window, this._onStopMoving) {
    onKey("<Enter>", description: "Finish moving window", action: stopMoving);
    onKey("<Escape>", description: "Finish moving window", action: stopMoving);
    onKey("<Return>", description: "Finish moving window", action: stopMoving);
    onKey("q", description: "Finish moving window", action: stopMoving);

    onKey("<Down>", description: "Move down", action: () => moveWindow(0, 1));
    onKey("<Left>", description: "Move left", action: () => moveWindow(-1, 0));
    onKey("<Right>", description: "Move right", action: () => moveWindow(1, 0));
    onKey("<Up>", description: "Move up", action: () => moveWindow(0, -1));

    onKey("<S-h>", description: "Jump left", action: () => moveWindow(-10, 0));
    onKey("<S-j>", description: "Jump down", action: () => moveWindow(0, 5));
    onKey("<S-k>", description: "Jump up", action: () => moveWindow(0, -5));
    onKey("<S-l>", description: "Jump right", action: () => moveWindow(10, 0));
    onKey("h", description: "Move left", action: () => moveWindow(-1, 0));
    onKey("j", description: "Move down", action: () => moveWindow(0, 1));
    onKey("k", description: "Move up", action: () => moveWindow(0, -1));
    onKey("l", description: "Move right", action: () => moveWindow(1, 0));

    _window.addOverlay(this);
    _window.requestRedraw();
  }

  moveWindow(int dx, int dy) {
    final moved = _window.position.moved(dx, dy);
    _window.position = moved;
    _window.requestRedraw();
  }

  stopMoving() {
    _window.removeOverlay(this);
    _window.requestRedraw();
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
