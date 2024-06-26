import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ansi/ansi.dart';
import 'package:dart_consul/src/util/auto_dispose.dart';
import 'package:dart_consul/src/util/common.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:rxdart/transformers.dart';

part 'buffer.dart';
part 'con_io.dart';
part 'debug_log.dart';
part 'desktop_notifications.dart';
part 'dialog_handling.dart';
part 'focus_handling.dart';
part 'key_event.dart';
part 'key_handling.dart';
part 'mouse_actions.dart';
part 'mouse_event.dart';
part 'mouse_gestures.dart';
part 'toast.dart';
part 'types.dart';
part 'window.dart';
part 'window_decoration.dart';
part 'window_extensions.dart';
part 'window_handling.dart';
part 'window_mousing.dart';
part 'window_moving.dart';
part 'window_resizing.dart';

/// Pseudo desktop environment for the console.
/// Requires an implementation of [ConIO] for rendering.
/// Functions only during awaited execution of the [run] function.
///
/// Note on [sendMessage] method: besides passing all the messages on to any
/// subscribers, the [Desktop] understands a few messages itself. At the time
/// of this writing, the following messages are supported.
///
/// ```
/// ("close-window", Window)
/// ("maximize-window", Window)
/// ("minimize-window", Window)
/// ("raise-window", Window)
/// ("resize-window", Window, Size)
/// ```
///
/// These are records with the message id as a [String], plus the required
/// parameters.
class Desktop
    with
        AutoDispose,
        FocusHandling,
        KeyHandling,
        ToastHandling,
        _DialogHandling,
        _MouseActions,
        _WindowHandling {
  final ConIO _conIO;
  final _subscriptions = StreamController<dynamic>.broadcast();
  final _invalidated = StreamController<DateTime>.broadcast();
  final _sizeChange = StreamController<Size>.broadcast();

  @override
  var dimWhenOverlapped = true;

  FPS _maxFPS;
  StreamSubscription? _tick;

  KeyHandling? _keyInterceptor;
  Function(KeyEvent)? _keyStealer;

  /// Currently available width for the desktop.
  int get columns => _conIO.columns();

  /// Currently available height for the desktop.
  int get rows => _conIO.rows() - 1;

  /// Currently available width and height for the desktop.
  @override
  Size get size => Size(columns, rows);

  /// Stream for watching desktop size changes.
  late Stream<Size> Function() onSizeChange;

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
    _conIO.onMouseEvent = _handleMouseEvent;
    _subscriptions.stream.listen(_onMessage);
    onSizeChange = () => _sizeChange.stream;
    autoDispose(
      "sigwinch",
      ProcessSignal.sigwinch.watch().listen((event) {
        logVerbose("terminal resized: $columns x $rows");
        _sizeChange.add(Size(columns, rows));
      }),
    );
  }

  Disposable stealKeys(Function(KeyEvent) stealer) {
    if (_keyStealer != null) {
      throw StateError("already stolen - check logic/state");
    }
    _keyStealer = stealer;
    return Disposable.wrap(() => unstealKeys(stealer));
  }

  void unstealKeys(Function(KeyEvent) stealer) {
    if (_keyStealer != stealer) {
      throw StateError("already disposed or changed - check logic/state");
    }
    _keyStealer = null;
  }

  void handleStolen(KeyEvent it) => _handleKeyEvent(it, false);

  void _handleKeyEvent(KeyEvent it, [bool allowStealing = true]) {
    final dialog = _dialog;
    if (dialog != null) {
      dialog.handleKeyEvent(it);
      return;
    }

    if (_keyStealer != null && allowStealing) {
      _keyStealer!(it);
      return;
    }

    if (_keyInterceptor != null) {
      _keyInterceptor?.handleKeyEvent(it);
      return;
    }

    // when focus changes, reset unfocused window/handler:
    if (nested != _focused) nested?._reset();

    nested = _focused;
    handleKeyEvent(it);
  }

  void _onMessage(dynamic msg) {
    switch (msg) {
      case ("close-window", Window it):
        closeWindow(it);
      case ("maximize-window", Window it):
        toggleMaximizeWindow(it);
      case ("minimize-window", Window it):
        minimizeWindow(it);
      case ("raise-window", Window it):
        raiseWindow(it);
      case ("resize-window", Window it, Size size_):
        it._resizeClamped(size_.width, size_.height);
    }
  }

  void exit() => sendMessage("exit");

  /// Handle <Tab> and <S-Tab> for window switching, <C-w> plus <some-key> for window manipulation.
  void setDefaultKeys() {
    onKey("<Tab>", description: "Focus next window", action: focusNext);
    onKey("<S-Tab>",
        description: "Focus previous window", action: focusPrevious);
    onKey("<C-n>x",
        description: "Clear desktop notifications", action: clearNotifications);
    onKey("<C-n><Return>",
        description: "Trigger latest notification",
        action: triggerLatestNotification);
    onKey("<C-n>n",
        description: "Select notification area",
        action: selectNotificationArea);
    onKey("<C-w>_",
        description: "Minimize focused window", action: minimizeFocusedWindow);
    onKey("<C-w>m",
        description: "Move focused window", action: moveFocusedWindow);
    onKey("<C-w>o",
        description: "Toggle maximize window",
        action: toggleMaximizeFocusedWindow);
    onKey("<C-w>r",
        description: "Resize focused window", action: resizeFocusedWindow);
    onKey("<C-w>x",
        description: "Close focused window", action: closeFocusedWindow);
  }

  /// Change the background character to the given [charCode].
  setBackground(int charCode) {
    _background = Cell(charCode);
    redraw();
  }

  /// Change the background character to the given [Cell], allowing for ANSI
  /// sequences in the background.
  setBackgroundCell(Cell cell) {
    _background = cell;
    redraw();
  }

  /// Change the max FPS being rendered.
  changeMaxFPS(FPS maxFPS) {
    _maxFPS = maxFPS;
    _redraw(0);
    _startTicking();
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
      disposeAll();
      _tick?.cancel();
      _invalidated.close();
      _subscriptions.close();
    }
  }

  _redraw(_) => _redrawDesktop(columns: columns, rows: rows);

  void _startTicking() {
    _tick?.cancel();
    _tick = _invalidated.stream
        .throttleTime(_maxFPS.milliseconds, trailing: true)
        .listen(_redraw);
  }

  /// Trigger an (async) redraw.
  @override
  void redraw() {
    // ignore broken windows still sending after shutdown:
    if (_invalidated.isClosed) return;

    _invalidated.add(DateTime.now());
  }

  /// Lookup a window by [id].
  Window? findWindow(String id) =>
      _windows.where((it) => it.id == id).firstOrNull;

  /// Currently focused [Window] or `null` if none focused.
  Window? get focused => _focused;

  /// Ensure [window] is not minimized.
  raiseWindow(Window window) {
    if (window.state == WindowState.minimized) {
      window.state = window._restoreState ?? WindowState.normal;
      window._restoreState = null;
    }
    openWindow(window);
  }

  /// Start displaying the [window] on this "desktop".
  @override
  openWindow(Window window) {
    window._desktopSize = () => size;
    window._isFocused = (it) => it == _focused;
    window.sendMessage = sendMessage;
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
    window.sendMessage = (_) {};
    window._isFocused = (_) => false;
    window._desktopSize = () => Size.zero;
    window.disposeAll();
    _removeWindow(window);
    _updateFocus();
    redraw();
  }

  /// Resize currently focused window via keyboard. Nop if no window focused. Nop if window is not
  /// [WindowFlag.resizable].
  void resizeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    if (!current.flags.contains(WindowFlag.resizable)) return;
    _keyInterceptor = _WindowResizing(current, () => _keyInterceptor = null);
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
      window._resize_(_restoreSizes[window] ?? window.size.max);
    } else {
      // horrible.. :-D but will it do for now?
      _restoreSizes[window] = window.size.current;

      window.state = WindowState.maximized;
      window._resize(columns, rows - (window.undecorated ? 0 : 1 /*titlebar*/));
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
    window._restoreState = window.state;
    window.state = WindowState.minimized;
    _updateFocus();
    redraw();
  }

  /// Close the currently focused window. Nop without focused window.
  void closeFocusedWindow() {
    final current = _focused;
    if (current == null) return;
    if (current.closeable) closeWindow(current);
  }

  /// Focus window identified by [id]. Nop if window not found or not focusable.
  void focusById(String id) {
    final match = _windows.firstWhereOrNull((e) => e.id == id);
    if (match != null && match.focusable) raiseWindow(match);
  }

  /// Forward [msg] to all subscribers.
  sendMessage(msg) => _subscriptions.sink.add(msg);

  /// Stream of all messages going through the desktop.
  Stream<dynamic> stream() => _subscriptions.stream;

  /// Receive notifications of [msg] via [Stream].
  Stream<dynamic> listen(msg) =>
      _subscriptions.stream.where((event) => event == msg);

  /// Receive notifications of [msg] via callback function.
  StreamSubscription<dynamic> subscribe(msg, Function(dynamic) callback) =>
      _subscriptions.stream.where((event) => event == msg).listen((event) {
        callback(event);
      });

  KeyMap keyMap() {
    final result = KeyMap();
    result["Desktop"] = keyMapEntries();
    for (final window in _windows) {
      var mapping = window.keyMapEntries();
      if (mapping.isNotEmpty) result[window.name] = mapping;
    }
    return result;
  }

  @override
  void _updateRow(int row, String data) {
    _conIO.moveCursor(0, row);
    _conIO.write(data + ansiReset);
  }
}
