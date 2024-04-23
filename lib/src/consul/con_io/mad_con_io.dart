import 'dart:async';
import 'dart:io';

import 'package:dart_console/dart_console.dart' as dc;
import 'package:dart_consul/src/consul/con_io/extensions.dart';
import 'package:dart_consul/src/consul/desktop.dart';
import 'package:dart_minilog/dart_minilog.dart';

import '../../../dart_consul.dart';
import '../../util/common.dart';
import 'input_matching.dart';

/// A [ConIO] implementation using [dart_console] for "raw mode" handling.
class MadConIO with InputMatching implements ConIO {
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
    if (bytes.firstOrNull.isSigIntTrigger && !interceptSigInt) {
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
    var (event, skip) = matchEvent(bytes, printable);

    // if nothing matched, pump out an Unidentified event:
    if (event == null) {
      event = event ?? Unidentified(debug);
      skip = bytes.length;
    }

    if (event is KeyEvent) onKeyEvent(event);
    if (event is MouseEvent) onMouseEvent(event);

    final next = bytes.drop(skip);
    if (next.isNotEmpty) {
      final hex = next.toByteHexString(delimiter: ' ');
      logVerbose("skip $skip => $hex");
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

  @override
  bool interceptSigInt = false;

  @override
  KeyHandler onKeyEvent = (e) {};

  @override
  MouseHandler onMouseEvent = (e) {};

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

extension on dc.Console {
  set cursor(bool enabled) {
    if (enabled) {
      showCursor();
    } else {
      hideCursor();
    }
  }

  set mouseMode(bool value) => write(mouseModeCode(value));
}
