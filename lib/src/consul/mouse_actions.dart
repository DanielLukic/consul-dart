part of 'desktop.dart';

//
// TODO I long realized I'm going overboard with the abstract mixins... :-D
//

abstract mixin class _MouseActions {
  Size get size;

  List<Window> get _windows;

  Map<Window, DecoratedWindow> get _decorators;

  OngoingMouseAction? _ongoingMouseAction;

  void _handleMouseEvent(MouseEvent event) {
    final ongoing = _ongoingMouseAction;
    if (ongoing != null) {
      final p = ongoing.window.decoratedPosition(size);
      final relative = event.relativeTo(p);
      ongoing.onMouseEvent(relative);
      if (ongoing.done) _ongoingMouseAction = null;
      return;
    }

    final decorators = _windows.mapNotNull((it) => _decorators[it]);
    for (final it in decorators.reversed) {
      final p = it.decoratedPosition(size);
      final relative = event.relativeTo(p);
      final action = it.onMouseEvent(relative);
      if (action == null) continue;

      eventDebugLog.add(
        "on $event <-> ${it.id} - win pos: $p - relative: $relative - action? $action",
      );

      // some actions are done immediately. must not be assigned to _ongoingMouseAction.
      if (!action.done) _ongoingMouseAction = action;

      // if we have an ongoing action now, stop searching.
      break;
    }
  }
}

abstract class OngoingMouseAction {
  final DecoratedWindow window;
  final MouseEvent event;
  final Function(dynamic) sendMessage;

  var _done = false;

  OngoingMouseAction(this.window, this.event, this.sendMessage);

  bool get done => _done;

  void onMouseEvent(MouseEvent event);
}

class CloseWindowAction extends OngoingMouseAction {
  CloseWindowAction(super.window, super.event, super.sendMessage);

  @override
  onMouseEvent(MouseEvent event) {
    if (event.isUp) {
      _done = true;
      if (event.x == event.x && event.y == event.y) {
        sendMessage(("close-window", window));
      }
    }
  }
}

class MaximizeWindowAction extends OngoingMouseAction {
  MaximizeWindowAction(super.window, super.event, super.sendMessage);

  @override
  onMouseEvent(MouseEvent event) {
    if (event.isUp) {
      _done = true;
      if (event.x == event.x && event.y == event.y) {
        sendMessage(("maximize-window", window));
      }
    }
  }
}

class MinimizeWindowAction extends OngoingMouseAction {
  MinimizeWindowAction(super.window, super.event, super.sendMessage);

  @override
  onMouseEvent(MouseEvent event) {
    if (event.isUp) {
      _done = true;
      if (event.x == event.x && event.y == event.y) {
        sendMessage(("minimize-window", window));
      }
    }
  }
}

class MoveWindowAction extends OngoingMouseAction {
  MoveWindowAction(super.window, super.event, super.sendMessage);

  @override
  onMouseEvent(MouseEvent event) {}
}

class ResizeWindowAction extends OngoingMouseAction {
  final Size _baseSize;

  ResizeWindowAction(super.window, super.event, super.sendMessage)
      : _baseSize = window.size.current;

  @override
  onMouseEvent(MouseEvent event) {
    final dx = event.x - this.event.x;
    final dy = event.y - this.event.y;
    eventDebugLog.clear();
    eventDebugLog.add("resize: $event => $dx $dy");
    eventDebugLog.add("current: ${window.size.current}");
    eventDebugLog.add("min: ${window.size.min}");
    eventDebugLog.add("max: ${window.size.max}");
    sendMessage(("resize-window", window, _baseSize.plus(dx, dy)));

    if (event.isUp) _done = true;
  }
}

class RaiseWindowAction extends OngoingMouseAction {
  RaiseWindowAction(super.window, super.event, super.sendMessage) {
    sendMessage(("raise-window", window));
    _done = true;
  }

  @override
  void onMouseEvent(MouseEvent event) {}
}
