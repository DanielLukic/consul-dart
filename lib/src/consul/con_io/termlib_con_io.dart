import 'dart:io';

import 'package:dart_consul/src/consul/con_io/extensions.dart';
import 'package:dart_consul/src/consul/con_io/input_matching.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:termlib/termlib.dart';
import 'package:termparser/termparser.dart';

import '../../../dart_consul.dart';
import '../../util/common.dart';

class TermLibConIO with InputMatching implements ConIO {
  final t = TermLib();
  final p = Parser();

  final d = CompositeDisposable();

  TermLibConIO() {
    stdin.echoMode = false;
    stdin.lineMode = false;
    t.enableRawMode();
    t.enableAlternateScreen();
    t.enableKeyboardEnhancementFull();
    // t.enableMouseEvents();
    t.write(mouseModeCode(true));
    t.cursorHide();
    d.wrap(stdin.listen(_onStdIn));
    d.wrap(ProcessSignal.sigint.watch().listen((e) => close()));
    d.wrap(ProcessSignal.sigterm.watch().listen((e) => close()));
  }

  close() {
    d.dispose();
    t.cursorShow();
    t.write(mouseModeCode(false));
    // t.disableMouseEvents();
    t.disableKeyboardEnhancement();
    t.disableAlternateScreen();
    t.disableRawMode();
    safely(() => stdin.echoMode = true);
    safely(() => stdin.lineMode = true);
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

  @override
  bool interceptSigInt = false;

  @override
  KeyHandler onKeyEvent = (_) {};

  @override
  MouseHandler onMouseEvent = (_) {};

  @override
  int columns() => t.windowWidth;

  @override
  int rows() => t.windowHeight;

  @override
  void clear() => t.eraseClear();

  @override
  void moveCursor(int column, int row) => t.moveTo(row + 1, column + 1);

  @override
  void write(String buffer) => t.write(buffer);
}
