part of 'desktop.dart';

/// Simple mouse gesture detection. Has to be installed as a mouse event
/// listener via for example [Window.chainOnMouseEvent].
class MouseGestures with AutoDispose implements OngoingMouseAction {
  @override
  final Window window;

  final Desktop desktop;

  /// Create a gesture detector for the [window]. The [desktop] is required
  /// to keep potentially other installed event handlers working.
  MouseGestures(this.window, this.desktop);

  /// Will be called when a drag action is detected. Return
  /// [OngoingMouseAction.done] from this to stop intercepting mouse events.
  OngoingMouseAction Function(MouseEvent)? onDrag;

  void Function(MouseEvent)? onClick;
  void Function(MouseEvent)? onDoubleClick;
  void Function(MouseEvent)? onLongClick;

  /// Will be called with the click pattern. For example 'SSL' for double
  /// short plus long click. Note that [onMultiClick] will be called in
  /// addition to one of the more specific click callbacks.
  void Function(MouseEvent, String)? onMultiClick;

  OngoingMouseAction? process(MouseEvent event) {
    if (event is MouseWheelEvent) {
      return null;
    }

    if (event.isDown) {
      desktop.raiseWindow(window);
      _reset(start: event, trackClick: true);
      return this;
    }
    return ConsumedMouseAction(window);
  }

  void _reset({MouseEvent? start, bool trackClick = false}) {
    _start = start;
    _clicks = '';
    _done = false;
    _delegate = null;
    if (trackClick) {
      _clickedAt = DateTime.timestamp();
    } else {
      _clickedAt = null;
    }
    desktop.resetMouseAction(this);
  }

  MouseEvent? _start;
  String _clicks = '';
  bool _done = false;
  OngoingMouseAction? _delegate;
  DateTime? _clickedAt;

  @override
  bool get done => _done;

  @override
  void onMouseEvent(MouseEvent event) {
    dispose('autoClick');

    // TODO cancel on wheel event?

    if (_done) throw StateError('already done');

    final d = _delegate;
    if (d != null) {
      if (!d.done) d.onMouseEvent(event);
      if (d.done) _reset();
      return;
    }

    final s = _start;
    if (s == null) throw StateError('ongoing detection without start');
    if (event.x != s.x || event.y != s.y) {
      final d = onDrag ?? (s) => _StealUntilUp(window, s);
      _delegate = d(s);
      _delegate?.onMouseEvent(event);
      return;
    }

    if (event.isDown) {
      _clickedAt = DateTime.timestamp();
    }

    if (event.isUp) {
      _clicks += _clickType();
      _clickedAt = null;
      autoClick();
    }
  }

  String _clickType() {
    final s = _clickedAt;
    if (s == null) {
      throw ArgumentError('click start missing', '_clickedAt');
    }
    final n = DateTime.now();
    final delta = n.difference(s);
    return delta.inMilliseconds < 500 ? 'S' : 'L';
  }

  void autoClick() {
    autoDispose(
        'autoClick',
        Timer(300.millis, () {
          final s = _start;
          if (s != null) {
            if (_clicks == 'S') onClick?.call(s);
            if (_clicks == 'SS') onDoubleClick?.call(s);
            if (_clicks == 'L') onLongClick?.call(s);
            onMultiClick?.call(s, _clicks);
          }
          _reset();
        }));
  }
}

class _StealUntilUp extends BaseOngoingMouseAction {
  _StealUntilUp(super.window, super.event);

  @override
  void onMouseEvent(MouseEvent event) {
    logInfo('stolen $event');
    done = event.isUp;
  }
}
