import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dart_console/dart_console.dart' as dc;
import 'package:dart_consul/src/consul/desktop.dart';

import '../../../dart_consul.dart';
import '../../util/common.dart';

part 'extensions.dart';
part 'input_matching.dart';

/// A [ConIO] implementation using [dart_console] for "raw mode" handling.
class MadConIO with _InputMatching implements ConIO {
  final _console = dc.Console();
  final _subscriptions = <StreamSubscription>[];

  MadConIO() {
    stdin.echoMode = false;
    stdin.lineMode = false;
    _subscriptions.add(stdin.listen(_onStdIn));
    _console.cursor = false;
    _console.rawMode = true;
    _console.mouseMode = true;
  }

  _onStdIn(List<int> bytes) {
    if (bytes.firstOrNull.isSigIntTrigger && !_interceptSigInt) {
      close();
      exit(0);
    }

    // the main issue: incoming bytes can contain multiple "events". and there is no real separator
    // (afaik). the approach chosen here is:
    //
    // 1. in _matchEvent, using pattern matching, find a longest match, returning the interpreted
    // event plus the number of bytes to skip.
    //
    // 2. if nothing identified, bite the bullet and wrap the whole input in an [Unidentified]
    // event.
    //
    // 3. at the end, skip the interpreted bytes and if there is more, recurse.

    final printable = bytes.printable;
    final debug = RawEvent(bytes, printable);

    // otherwise filter what we need via patterns:
    var (event, skip) = _matchEvent(bytes, printable);

    // if nothing matched, pump out an Unidentified event:
    event = event ?? Unidentified(debug);
    skip = bytes.length;

    // final line = "${event.toString().padRight(80)} RAW: $debug";
    // eventDebugLog.add(line);

    if (event is KeyEvent) _keyEventHandler?.let((it) => it(event));
    if (event is MouseEvent) _mouseEventHandler?.let((it) => it(event));

    final next = bytes.drop(skip);
    if (next.isNotEmpty) {
      final hex = next.toByteHexString(delimiter: ' ');
      eventDebugLog.add("skip $skip => $hex");
      _onStdIn(next);
    }
  }

  close() {
    _console.mouseMode = false;
    _console.rawMode = false;
    _console.cursor = true;
    safely(() => stdin.echoMode = true);
    safely(() => stdin.lineMode = true);

    for (final it in _subscriptions) {
      it.cancel();
    }
  }

  var _interceptSigInt = false;

  @override
  bool get interceptSigInt => _interceptSigInt;

  @override
  set interceptSigInt(enabled) => _interceptSigInt = enabled;

  @override
  KeyHandler? get onKeyEvent => _keyEventHandler;

  @override
  set onKeyEvent(KeyHandler? value) => _keyEventHandler = value;

  @override
  MouseHandler? get onMouseEvent => _mouseEventHandler;

  @override
  set onMouseEvent(MouseHandler? value) => _mouseEventHandler = value;

  @override
  int columns() => _console.windowWidth;

  @override
  int rows() => _console.windowHeight;

  @override
  void clear() => _console.clearScreen();

  @override
  void moveCursor(int column, int row) =>
      _console.cursorPosition = dc.Coordinate(row, column);

  @override
  void write(String buffer) => _console.write(buffer);
}
