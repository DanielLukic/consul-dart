part of 'desktop.dart';

//
// TODO I long realized I'm going overboard with the abstract mixins... :-D
//

abstract mixin class _MouseActions {
  Size get size;

  List<Window> get _windows;

  OngoingMouseAction? _ongoingMouseAction;

  void _handleMouseEvent(MouseEvent event) {
    final ongoing = _ongoingMouseAction;
    if (ongoing != null) {
      final p = ongoing.window.decoratedPosition();
      final relative = event.relativeTo(p);
      ongoing.onMouseEvent(relative);
      if (ongoing.done) _ongoingMouseAction = null;
      return;
    }

    for (final it in _windows.reversed) {
      final p = it.decoratedPosition();
      final relative = event.relativeTo(p);
      final action = it._onMouseEvent(relative);
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

/// Interface for handling "ongoing" mouse actions. [Window]s can return an
/// [OngoingMouseAction] from their [Window.onMouseEvent] to intercept mouse
/// events until [done] returns true. This way moving/dragging, resizing, etc
/// can be implemented.
abstract interface class OngoingMouseAction {
  /// The window this [OngoingMouseAction] originated from.
  Window get window;

  /// Must return `true` as long as mouse events should be delivered into
  /// [onMouseEvent].
  bool get done;

  /// Will be called by the [Desktop] until after [done] returns `false`.
  void onMouseEvent(MouseEvent event);
}

/// Immediately done. Use this to block duplicate event handling in chained
/// mouse event handlers.
class NopMouseAction extends OngoingMouseAction {
  NopMouseAction(this.window);

  @override
  final Window window;

  @override
  bool get done => true;

  @override
  void onMouseEvent(MouseEvent event) {}
}

/// Base class for [OngoingMouseAction]s that require access to the
/// originating [window], and/or [event], and/or [sendMessage] shortcut.
abstract class BaseOngoingMouseAction implements OngoingMouseAction {
  @override
  final Window window;

  /// The initial [MouseEvent] that triggered this [OngoingMouseAction].
  final MouseEvent event;

  /// Shortcut to send messages into or through [Desktop]. This way ongoing
  /// actions can be kept simple. Side effects can be mere messages.
  final Function(dynamic) sendMessage;

  @override
  var done = false;

  BaseOngoingMouseAction(this.window, this.event, this.sendMessage);
}

/// Predefined action to close the window that generates this action.
/// Triggers on button release. Uses the [Desktop] built-in "close-window"
/// message.
class CloseWindowAction extends BaseOngoingMouseAction {
  CloseWindowAction(super.window, super.event, super.sendMessage);

  @override
  onMouseEvent(MouseEvent event) {
    if (event.isUp) {
      done = true;
      if (event.x == event.x && event.y == event.y) {
        sendMessage(("close-window", window));
      }
    }
  }
}

/// Predefined action to toggle maximize the window that generates this action.
/// Triggers on button release.
class MaximizeWindowAction extends BaseOngoingMouseAction {
  MaximizeWindowAction(super.window, super.event, super.sendMessage);

  @override
  onMouseEvent(MouseEvent event) {
    if (event.isUp) {
      done = true;
      if (event.x == event.x && event.y == event.y) {
        sendMessage(("maximize-window", window));
      }
    }
  }
}

/// Predefined action to minimize the window that generates this action.
/// Triggers on button release.
class MinimizeWindowAction extends BaseOngoingMouseAction {
  MinimizeWindowAction(super.window, super.event, super.sendMessage);

  @override
  onMouseEvent(MouseEvent event) {
    if (event.isUp) {
      done = true;
      if (event.x == event.x && event.y == event.y) {
        sendMessage(("minimize-window", window));
      }
    }
  }
}

/// Predefined action to move/drag the window that generates this action.
class MoveWindowAction extends BaseOngoingMouseAction {
  late final AbsolutePosition _basePosition;

  MoveWindowAction(super.window, super.event, super.sendMessage) {
    _basePosition = window.position.toAbsolute(
      window._desktopSize(),
      window.size.current,
    );
  }

  @override
  onMouseEvent(MouseEvent event) {
    final dx = event.xAbs - this.event.xAbs;
    final dy = event.yAbs - this.event.yAbs;
    window.position = _basePosition.moved(dx, dy);
    if (event.isUp) done = true;
  }
}

/// Predefined action to resize the window that generates this action. Uses the
/// "resize-window" message to handle resize via the [Desktop] built-in resize.
class ResizeWindowAction extends BaseOngoingMouseAction {
  final Size _baseSize;

  ResizeWindowAction(super.window, super.event, super.sendMessage)
      : _baseSize = window.size.current;

  @override
  onMouseEvent(MouseEvent event) {
    final dx = event.x - this.event.x;
    final dy = event.y - this.event.y;
    sendMessage(("resize-window", window, _baseSize.plus(dx, dy)));
    if (event.isUp) done = true;
  }
}

/// Predefined action to raise/restore the window that generates this action.
class RaiseWindowAction extends BaseOngoingMouseAction {
  RaiseWindowAction(super.window, super.event, super.sendMessage) {
    sendMessage(("raise-window", window));
    done = true;
  }

  @override
  void onMouseEvent(MouseEvent event) {}
}
