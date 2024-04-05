part of 'desktop.dart';

class _WindowMoving with KeyHandling implements WindowOverlay {
  final Window _window;
  final Function _onStopMoving;

  _WindowMoving(this._window, this._onStopMoving) {
    onKey("<Enter>", description: "Finish moving window", action: stopMoving);
    onKey("<Escape>", description: "Finish moving window", action: stopMoving);
    onKey("<Return>", description: "Finish moving window", action: stopMoving);
    onKey("q", description: "Finish moving window", action: stopMoving);

    onKey("<Down>", description: "Move one down", action: () => moveWindow(0, 1));
    onKey("<Left>", description: "Move one left", action: () => moveWindow(-1, 0));
    onKey("<Right>", description: "Move one right", action: () => moveWindow(1, 0));
    onKey("<Up>", description: "Move one up", action: () => moveWindow(0, -1));
    onKey("h", description: "Move one left", action: () => moveWindow(-1, 0));
    onKey("j", description: "Move one down", action: () => moveWindow(0, 1));
    onKey("k", description: "Move one up", action: () => moveWindow(0, -1));
    onKey("l", description: "Move one right", action: () => moveWindow(1, 0));

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
