part of 'desktop.dart';

class DecoratedWindow with _WindowDecoration implements Window {
  final Window _window;

  DecoratedWindow.decorate(this._window) {
    eventDebugLog.add("window decorated: $_window");
    onMouseEvent = _onMouseEvent;
  }

  OngoingMouseAction? _onMouseEvent(MouseEvent it) {
    final isLmbDown = it is MouseButtonEvent && it.kind == MouseButtonKind.lmbDown;

    // check for titlebar click:
    if (isLmbDown && it.y == 0 && it.x >= 0 && it.x < width) {
      if (it.x >= width - 3) {
        return CloseWindowAction(this, it, sendMessage);
      } else if (it.x >= width - 6) {
        return MaximizeWindowAction(this, it, sendMessage);
      } else if (it.x >= width - 9) {
        return MinimizeWindowAction(this, it, sendMessage);
      } else {
        return MoveWindowAction(this, it, sendMessage);
      }
    }

    // check for resize control click:
    if (isLmbDown && it.y == height - 1 && it.x == width - 1 && resizable) {
      return ResizeWindowAction(this, it, sendMessage);
    }

    // check for inside click:
    if (it.x >= 0 && it.x < width && it.y > 0 && it.y < height) {
      // TODO handle inner handler ^^
      return RaiseWindowAction(this, it, sendMessage);
    }

    // no action here, pass on null to let someone else handle it:
    return null;
  }

  @override
  Function(dynamic) get sendMessage => _window.sendMessage;

  @override
  late OngoingMouseAction? Function(MouseEvent) onMouseEvent;

  AbsolutePosition decoratedPosition(Size desktop) {
    if (_window.isMaximized) {
      return Position.topLeft;
    } else {
      return position.toAbsolute(desktop, _decoratedSize(_window).current);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Quick hack for now to prototype this...
    final symbol = invocation.memberName.toString();
    final name = symbol.split('"')[1];
    final result = switch (name) {
      "flags" => _window.flags,
      "height" => _window.height,
      "id" => _window.id,
      "name" => _window.name,
      "position" => _window.position,
      "redrawBuffer" => _decorateBuffer(_window),
      "resizable" => _window.resizable,
      "size" => _decoratedSize(_window),
      "state" => _window.state,
      "undecorated" => _window.undecorated,
      "width" => _window.width,
      _ => throw NoSuchMethodError.withInvocation(_window, invocation),
    };
    return result;
  }

  @override
  String toString() => "Decorated($_window)";
}
