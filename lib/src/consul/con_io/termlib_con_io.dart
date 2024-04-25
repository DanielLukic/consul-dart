import 'dart:io';

import 'package:dart_consul/src/consul/con_io/extensions.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:termlib/termlib.dart';
import 'package:termparser/termparser.dart';
import 'package:termparser/termparser_events.dart' as tpe;

import '../../../dart_consul.dart';
import '../../util/common.dart';

class TermLibConIO implements ConIO {
  final t = TermLib();
  final p = Parser();

  final d = CompositeDisposable();

  TermLibConIO() {
    rawModeReturnQuirk = true;
    ctrlQuestionMarkQuirk = true;
    zellijMouseMotionQuirk = true;
    stdin.echoMode = false;
    stdin.lineMode = false;
    t.enableRawMode();
    t.enableAlternateScreen();
    t.enableKeyboardEnhancementFull();
    t.enableMouseEvents();
    t.cursorHide();
    d.wrap(stdin.listen(_onStdIn));
    d.wrap(ProcessSignal.sigint.watch().listen((e) => close()));
    d.wrap(ProcessSignal.sigterm.watch().listen((e) => close()));
  }

  close() {
    d.dispose();
    t.cursorShow();
    t.disableMouseEvents();
    t.disableKeyboardEnhancement();
    t.disableAlternateScreen();
    t.disableRawMode();
    safely(() => stdin.echoMode = true);
    safely(() => stdin.lineMode = true);
  }

  void _onStdIn(List<int> bytes) {
    if (bytes.firstOrNull.isSigIntTrigger && !interceptSigInt) {
      close();
      t.eraseClear();
      t.flushThenExit(0);
      exit(0);
    } else {
      p.advance(bytes);
      while (p.moveNext()) {
        _onEvent(p.current, bytes);
      }
    }
  }

  void _onEvent(tpe.Event e, List<int> bytes) {
    if (e case tpe.MouseEvent me) {
      _onMouseEvent(me);
    } else if (e case tpe.KeyEvent ke) {
      _onKeyEvent(ke, bytes);
    }
  }

  void _onMouseEvent(tpe.MouseEvent me) {
    final down = me.button.action == tpe.MouseButtonAction.down;
    final drag = me.button.action == tpe.MouseButtonAction.drag;
    final moved = me.button.action == tpe.MouseButtonAction.moved;
    final up = me.button.action == tpe.MouseButtonAction.up;
    final wheelDown = me.button.action == tpe.MouseButtonAction.wheelDown;
    final wheelUp = me.button.action == tpe.MouseButtonAction.wheelUp;
    final lmb = me.button.button == tpe.MouseButtonKind.left;
    final rmb = me.button.button == tpe.MouseButtonKind.right;
    final mmb = me.button.button == tpe.MouseButtonKind.middle;
    final x = me.x - 1;
    final y = me.y - 1;
    final result = switch (me) {
      _ when lmb && down => MouseButtonEvent(MouseButtonKind.lmbDown, x, y),
      _ when mmb && down => MouseButtonEvent(MouseButtonKind.mmbDown, x, y),
      _ when rmb && down => MouseButtonEvent(MouseButtonKind.rmbDown, x, y),
      _ when lmb && up => MouseButtonEvent(MouseButtonKind.lmbUp, x, y),
      _ when mmb && up => MouseButtonEvent(MouseButtonKind.mmbUp, x, y),
      _ when rmb && up => MouseButtonEvent(MouseButtonKind.rmbUp, x, y),
      _ when wheelDown => MouseWheelEvent(MouseWheelKind.wheelDown, x, y),
      _ when wheelUp => MouseWheelEvent(MouseWheelKind.wheelUp, x, y),
      _ when drag || moved && lmb =>
        MouseMotionEvent(MouseMotionKind.lmb, x, y),
      _ when drag || moved && mmb =>
        MouseMotionEvent(MouseMotionKind.mmb, x, y),
      _ when drag || moved && rmb =>
        MouseMotionEvent(MouseMotionKind.rmb, x, y),
      _ => null,
    };
    if (result != null) onMouseEvent(result);
  }

  void _onKeyEvent(tpe.KeyEvent ke, List<int> bytes) {
    final alt = ke.modifiers.has(tpe.KeyModifiers.alt);
    final ctrl = ke.modifiers.has(tpe.KeyModifiers.ctrl);
    var shift = ke.modifiers.has(tpe.KeyModifiers.shift);

    // logInfo('${bytes.toByteHexString()} ${bytes.printable}');
    // logInfo('a $alt c $ctrl s $shift');
    // logInfo(ke);

    if (ke.code.name != tpe.KeyCodeName.none) {
      final n = ke.code.name.name.toLowerCase();
      var match =
          Control.values.firstWhereOrNull((e) => e.name.toLowerCase() == n);
      if (match == null) {
        switch (ke.code.name) {
          case tpe.KeyCodeName.backTab:
            match = Control.Tab;
            shift = true;
          case tpe.KeyCodeName.enter:
            match = Control.Return;
          default:
            logWarn('$n not found in ${Control.values}');
        }
      }
      if (match != null) {
        onKeyEvent(ControlKey(match, alt: alt, ctrl: ctrl, shift: shift));
      }
    } else {
      var ch = ke.code.char;
      if (ch == ch.toUpperCase() && ch != ch.toLowerCase()) {
        ch = ch.toLowerCase();
        shift = true;
      }
      final co = ke.code.char.codeUnitAt(0);
      onKeyEvent(InputKey(ch, co, alt: alt, ctrl: ctrl, shift: shift));
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
