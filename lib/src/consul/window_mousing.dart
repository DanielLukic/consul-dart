part of 'desktop.dart';

extension WindowMousing on Window {
  /// Shortcut for installing a chained mouse event handler. Replaces the
  /// currently installed handler. But forwards all unprocessed events to
  /// this handler. To avoid duplicate event handling, return [
  void chainOnMouseEvent(OnMouseEvent handler) {
    final next = onMouseEvent;
    onMouseEvent = (it) {
      final handled = handler(it);
      if (handled != null) return handled;
      return next(it);
    };
  }

  /// Shortcut for the common functionality of handling a mouse wheel up
  /// event in a window.
  void onWheelUp(void Function() quickAction) {
    chainOnMouseEvent((e) => e.onWheelUp((it) {
          quickAction();
          return NopMouseAction(this);
        }));
  }

  /// Shortcut for the common functionality of handling a mouse wheel down
  /// event in a window.
  void onWheelDown(void Function() quickAction) {
    chainOnMouseEvent((e) => e.onWheelDown((it) {
          quickAction();
          return NopMouseAction(this);
        }));
  }

  OngoingMouseAction? _onMouseEvent(MouseEvent it) {
    final isLmbDown =
        it is MouseButtonEvent && it.kind == MouseButtonKind.lmbDown;

    // check for titlebar click:
    if (isLmbDown && it.y == 0 && it.x >= 0 && it.x < width) {
      sendMessage(("raise-window", this));
      if (it.x >= _controlsOffset) {
        // lovely... :-D
        final x = (it.x - _controlsOffset) ~/ 3 * 3 + _controlsOffset + 1;
        final control = ansiStripped(_titlebar).substring(x, x + 1);
        return switch (control) {
          "X" => CloseWindowAction(this, it),
          "O" => MaximizeWindowAction(this, it),
          "_" => MinimizeWindowAction(this, it),
          _ => null,
        };
      } else if (movable) {
        return MoveWindowAction(this, it);
      }
      return null;
    }

    final height = _decoratedSize(this).current.height;

    // check for resize control click:
    if (isLmbDown && it.y == height - 1 && it.x == width - 1 && resizable) {
      if (!isMaximized) {
        sendMessage(("raise-window", this));
        return ResizeWindowAction(this, it);
      }
    }

    // check for inside click:
    if (it.x >= 0 && it.x < width && it.y > 0 && it.y < height) {
      final consumed = onMouseEvent(it);
      if (consumed != null) return consumed;
      if (isLmbDown) return RaiseWindowAction(this, it);
    }

    // no action here, pass on null to let someone else handle it:
    return null;
  }
}
