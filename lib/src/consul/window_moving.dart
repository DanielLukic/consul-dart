part of 'desktop.dart';

class _WindowMoving with KeyHandling implements WindowOverlay {
  final Window _window;
  final Function _onStopMoving;

  _WindowMoving(this._window, this._onStopMoving) {
    onKey("<Enter>", stopMoving);
    onKey("<Escape>", stopMoving);
    onKey("<Return>", stopMoving);
    onKey("q", stopMoving);

    onKey("<Down>", () => moveWindow(0, 1));
    onKey("<Left>", () => moveWindow(-1, 0));
    onKey("<Right>", () => moveWindow(1, 0));
    onKey("<Up>", () => moveWindow(0, -1));
    onKey("h", () => moveWindow(-1, 0));
    onKey("j", () => moveWindow(0, 1));
    onKey("k", () => moveWindow(0, -1));
    onKey("l", () => moveWindow(1, 0));

    _window.addOverlay(this);
  }

  moveWindow(int dx, int dy) {
    final moved = _window.position.moved(dx, dy);
    _window.position = moved;
  }

  stopMoving() {
    _window.removeOverlay(this);
    _onStopMoving();
  }

  @override
  void decorate(OverlayBuffer buffer) {
    final x = buffer.width ~/ 2;
    final y = buffer.height ~/ 2;
    buffer.draw(x - 2, y - 2, cross);
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
