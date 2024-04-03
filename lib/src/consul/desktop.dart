import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ansi/ansi.dart';
import 'package:consul/src/util/common.dart';
import 'package:consul/src/util/log.dart';
import 'package:rxdart/transformers.dart';

part 'buffer.dart';
part 'con_io.dart';
part 'debug_log.dart';
part 'decorated_window.dart';
part 'focus_handling.dart';
part 'key_event.dart';
part 'key_handling.dart';
part 'menu.dart';
part 'mouse_event.dart';
part 'toast.dart';
part 'types.dart';
part 'window.dart';
part 'window_handling.dart';
part 'window_moving.dart';
part 'window_resizing.dart';

/// Pseudo desktop environment for the console.
/// Requires an implementation of [ConIO] for rendering.
/// Functions only during awaited execution of the [run] function.
class Desktop with FocusHandling, KeyHandling, ToastHandling, _WindowHandling {
  final ConIO _conIO;
  final _subscriptions = StreamController<String>.broadcast();
  final _invalidated = StreamController<DateTime>.broadcast();

  FPS _maxFPS;
  StreamSubscription? _tick;

  KeyHandling? _keyInterceptor;

  /// Currently available width for the desktop.
  int get columns => _conIO.columns();

  /// Currently available height for the desktop.
  int get rows => _conIO.rows() - 1;

  /// Currently available width and height for the desktop.
  Size get size => Size(columns, rows);

  /// Is <Ctrl-c> intercepted? Or auto-handled by the console to stop the program? Note that if you
  /// loop in your code, <Ctrl-c> will not be handled either way!
  get interceptSigInt => _conIO.interceptSigInt;

  /// If [intercept] is true, <Ctrl-c> will be reported as a key event. It will be auto-handled as
  /// program termination otherwise.
  set interceptSigInt(intercept) => _conIO.interceptSigInt = intercept;

  Desktop({
    required ConIO conIO,
    int Function()? now,
    int maxFPS = 60,
  })  : _conIO = conIO,
        _maxFPS = FPS(maxFPS) {
    _conIO.onKeyEvent = _handleKeyEvent;
  }

  void _handleKeyEvent(KeyEvent it) {
    if (_keyInterceptor != null) {
      _keyInterceptor?._onKeyEvent(it);
      return;
    }

    // when focus changes, reset unfocused window/handler:
    if (_nested != _focused) _nested?._reset();

    _nested = _focused;
    _onKeyEvent(it);
  }

  /// Handle <TAB> and <S-TAB> for window switching.
  void setDefaultKeys() {
    onKey("<Tab>", focusNext);
    onKey("<S-Tab>", focusPrevious);
    onKey("<C-w>_", minimizeFocusedWindow);
    onKey("<C-w>m", moveFocusedWindow);
    onKey("<C-w>o", toggleMaximizeFocusedWindow);
    onKey("<C-w>r", resizeFocusedWindow);
    onKey("<C-w>x", closeFocusedWindow);
  }

  /// Resize currently focused window via keyboard. Nop if no window focused. Nop if window is not
  /// [WindowFlag.resizable].
  void resizeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    if (!current.flags.contains(WindowFlag.resizable)) return;
    _keyInterceptor = _WindowResizing(size, current, () => _keyInterceptor = null);
  }

  /// Move currently focused window via keyboard. Nop if no window focused.
  void moveFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    if (current.flags.contains(WindowFlag.unmovable)) return;
    _keyInterceptor = _WindowMoving(current, () => _keyInterceptor = null);
  }

  /// Toggle maximized state of currently focused window. Nop if no window focused.
  void toggleMaximizeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    toggleMaximizeWindow(current);
  }

  /// Toggle maximized state of [window].
  void toggleMaximizeWindow(Window window) {
    if (!window.flags.contains(WindowFlag.maximizable)) return;

    if (window.state == WindowState.maximized) {
      window.state = WindowState.normal;
      window.resize_(_restoreSizes[window] ?? window.size.max);
    } else {
      // horrible.. :-D but will it do for now?
      _restoreSizes[window] = window.size.current;

      window.state = WindowState.maximized;
      window.resize(columns, rows - (window.undecorated ? 0 : 1 /*titlebar*/));
    }

    redraw();
  }

  /// Minimize currently focused window.
  void minimizeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    minimizeWindow(current);
  }

  /// Minimize [window].
  void minimizeWindow(Window window) {
    if (window.state == WindowState.minimized) return;
    if (!window.flags.contains(WindowFlag.minimizable)) return;
    window.state = WindowState.minimized;
    _updateFocus();
    redraw();
  }

  /// Close the currently focused window. Nop without focused window.
  void closeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    closeWindow(current);
  }

  @override
  void _updateRow(int row, String data) {
    _conIO.moveCursor(0, row);
    _conIO.write(data + _ansiReset);
  }

  /// Run the desktop "main loop".
  run() async {
    try {
      _redraw(0);
      _startTicking();
      await listen("exit").first;
    } catch (it, trace) {
      logError(it.toString(), trace);
      rethrow;
    } finally {
      logWarn("exiting");
      _tick?.cancel();
      _invalidated.close();
      _subscriptions.close();
    }
  }

  void _startTicking() {
    _tick?.cancel();
    _tick = _invalidated.stream.throttleTime(_maxFPS.milliseconds, trailing: true).listen(_redraw);
  }

  /// Change the background character. Does not redraw the desktop. Call [_redrawDesktop] as
  /// necessary.
  setBackground(int charCode) {
    _background = charCode;
    redraw();
  }

  /// Change the max FPS being rendered.
  changeMaxFPS(FPS maxFPS) {
    _maxFPS = maxFPS;
    _redraw(0);
    _startTicking();
  }

  /// Trigger an (async) redraw.
  redraw() {
    // ignore broken windows still sending after shutdown:
    if (_invalidated.isClosed) return;

    _invalidated.add(DateTime.now());
  }

  _redraw(_) => _redrawDesktop(columns: columns, rows: rows);

  /// TODO Change the displayed menu.
  setMenu(Menu menu) {}

  /// Lookup a window by [id].
  Window? findWindow(String id) => _windows.where((it) => it.id == id).firstOrNull;

  /// Ensure [window] is not minimized.
  restore(Window window) {
    if (window.state == WindowState.minimized) {
      window.state = WindowState.normal;
    }
    openWindow(window);
  }

  /// Start displaying the [window] on this "desktop".
  @override
  openWindow(Window window) {
    window._isFocused = (it) => it == _focused;
    window.requestRedraw = redraw;

    // move window to top (end) of stack:
    _windows.remove(window);
    _windows.add(window);

    _updateFocus();
    redraw();
  }

  /// Remove [window] from this "desktop".
  @override
  closeWindow(Window window) {
    window.state = WindowState.closed;
    window.requestRedraw = () {};
    window.disposeAll();
    _removeWindow(window);
    _updateFocus();
    redraw();
  }

  /// Forward [msg] to all subscribers.
  sendMessage(msg) => _subscriptions.sink.add(msg);

  /// Receive notifications of [msg] via [Stream].
  Stream<String> listen(msg) => _subscriptions.stream.where((event) => event == msg);

  /// Receive notifications of [msg] via callback function.
  StreamSubscription<String> subscribe(msg, Function(dynamic) callback) =>
      _subscriptions.stream.where((event) => event == msg).listen((event) {
        callback(event);
      });
}
