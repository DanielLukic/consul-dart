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

/// Pseudo desktop environment for the console.
/// Requires an implementation of [ConIO] for rendering.
/// Functions only during awaited execution of the [run] function.
class Desktop with FocusHandling, KeyHandling, ToastHandling, _WindowHandling {
  final ConIO _conIO;
  final _subscriptions = StreamController<String>.broadcast();
  final _invalidated = StreamController<DateTime>.broadcast();

  FPS _maxFPS;
  StreamSubscription? _tick;

  get interceptSigInt => _conIO.interceptSigInt;

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
    // when focus changes, reset unfocused window/handler:
    if (_nested != _focused) _nested?._reset();

    _nested = _focused;
    _onKeyEvent(it);
  }

  /// Handle <TAB> and <S-TAB> for window switching.
  void setDefaultKeys() {
    onKey("<TAB>", focusNext);
    onKey("<S-TAB>", focusPrevious);
    onKey("<C-w>_", minimizeFocusedWindow);
    // onKey("<A-m>", moveFocusedWindow);
    onKey("<C-w>o", toggleMaximizeFocusedWindow);
    // onKey("<A-r>", resizeFocusedWindow);
    onKey("<C-w>x", closeFocusedWindow);
  }

  void toggleMaximizeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    if (!current.flags.contains(WindowFlag.maximizable)) return;

    if (current.state == WindowState.maximized) {
      current.state = WindowState.normal;
      current.resize_(_restoreSizes[current] ?? current.size.max);
    } else {
      // horrible.. :-D but will it do for now?
      _restoreSizes[current] = current.size.current;

      current.state = WindowState.maximized;
      current.resize(columns, rows - (current.undecorated ? 0 : 1 /*titlebar*/));
    }

    redraw();
  }

  void minimizeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    if (current.state == WindowState.minimized) return;
    if (!current.flags.contains(WindowFlag.minimizable)) return;
    current.state = WindowState.minimized;
    _updateFocus();
    redraw();
  }

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
    // ignore broken windows:
    if (_invalidated.isClosed) return;
    _invalidated.add(DateTime.now());
  }

  int get columns => _conIO.columns();

  int get rows => _conIO.rows() - 1;

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
