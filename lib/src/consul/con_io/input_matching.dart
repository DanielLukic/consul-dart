import 'package:dart_consul/common.dart';
import 'package:dart_consul/dart_consul.dart';
import 'package:dart_consul/src/consul/con_io/extensions.dart';

mixin InputMatching {
  static const _esc = 0x1B;
  static const _ctl = 0x5B;
  static const _bs = 0x7F;

  // mouse events with these groups:
  // 1. button/action info 2. x 3. y and 4. release/press (m/M)
  final _mouseMatcher = RegExp(r"<ESC>\[<([^;]+);([^;]+);([^;]+)([mM])");

  // see how this is used in [_matchEvent] to identify various "control keys" via "printable"
  // matching.
  KeyEvent? _matchControlKey(String printable, {required bool alt}) {
    final control = _controls[printable];
    return control != null ? ControlKey(control, alt: alt) : null;
  }

  (dynamic, int) matchEvent(List<int> bytes, [String? printable]) {
    printable ??= bytes.printable;
    //
    // (pure madness :-D)
    //
    // i don't know where to begin explaining this. i made a deliberate decision to not look up any
    // spec for this. and simply go step by step and see where this leads me. it led me here. and i
    // regret my decision... :-D but here we are... ‾\_('')_/‾
    //
    // anyway, pattern matching order matters. obviously.
    // to simplify(?) a bit, the _controls lookup is used at various places.
    // then there are mouse events, handled via regex pattern with groups.

    final mouse = _mouseMatcher.firstMatch(bytes.printable);

    dynamic event;
    int skip = 0;
    switch (bytes) {
      case [_bs]:
        event = ControlKey(Control.Backspace);
        skip = 1;
      case [_esc, _bs]:
        event = ControlKey(Control.Backspace, alt: true);
        skip = 2;
      case [_esc, 13]:
        event = ControlKey(Control.Return, alt: true);
        skip = 2;
      case [_esc, var key] when key < 32:
        event = _matchControlKey([key].printable, alt: true);
        event = event ?? InputKey(key.alphaChar, key, alt: true, ctrl: true);
        skip = 2;
      case [_esc, var key]:
        final shift = key.isShifted;
        event = _matchControlKey([key].printable, alt: true);
        event = event ?? InputKey(key.char, key, alt: true, shift: shift);
        skip = 2;
      case [_esc, _ctl, 90]:
        event = ControlKey(Control.Tab, shift: true);
        skip = 3;
      case [_esc, _ctl, 49, 59, var mod, var key]:
        event = _lookup([key], mod);
        skip = 6;
      case [_esc, _ctl, var key1, var key2, 59, var mod, 126]:
        event = _lookup([key1, key2, 126], mod);
        skip = 7;

      // mouse events here
      case [...] when _isMouse(mouse):
        (event, skip) = _handleMouseEvent(bytes, mouse!);

      // attempt quick control key lookup before falling back to single input char matching below...
      case [...] when bytes.length >= 3:
        //
        // what a mess... :-D
        //

        final five = bytes.take_(5);
        event = _matchControlKey(five.printable, alt: false);
        if (event != null) {
          skip = 5;
          break;
        }
        final four = bytes.take_(4);
        event = _matchControlKey(four.printable, alt: false);
        if (event != null) {
          skip = 4;
          break;
        }
        final three = bytes.take_(3);
        event = _matchControlKey(three.printable, alt: false);
        if (event != null) {
          skip = 3;
          break;
        }

      case [0x1F]:
        event = InputKey('?', 0x1F, ctrl: true);
        skip = 1;

      case [var key] when key < 32:
        event = _matchControlKey(printable, alt: false);
        event = event ?? InputKey(key.alphaChar, key, ctrl: true);
        skip = 1;

      case [var key]:
        event = _matchControlKey(printable, alt: false);
        final shift = key.isShifted;
        event = event ?? InputKey(key.char, key, shift: shift);
        skip = 1;
    }
    return (event, skip);
  }

  bool _isMouse(RegExpMatch? mouse) {
    if (mouse == null) return false;
    if (mouse.start != 0) return false;
    return true;
  }

  (MouseEvent?, int) _handleMouseEvent(List<int> bytes, RegExpMatch it) {
    final id = int.tryParse(it.group(1) ?? "") ?? 0;
    final lmb = (id & 3) == 0;
    final mmb = (id & 1) == 1;
    final rmb = (id & 2) == 2;
    final moving = (id & 0x20) == 0x20;
    final wheeling = (id & 0x40) == 0x40;
    final wheelingDown = (id & 1) == 1;
    final x = (int.tryParse(it.group(2) ?? "") ?? 0) - 1;
    final y = (int.tryParse(it.group(3) ?? "") ?? 0) - 1;
    final released = it.group(4) == "m";

    MouseEvent? event;
    if (wheeling) {
      final kind = mouseWheelKind(wheelingDown);
      event = MouseWheelEvent(kind, x, y);
    } else if (moving) {
      final kind = MouseMotionKind.lmb.takeIf(lmb) ??
          MouseMotionKind.mmb.takeIf(mmb) ??
          MouseMotionKind.rmb.takeIf(rmb);
      if (kind != null) event = MouseMotionEvent(kind, x, y);
    } else {
      final kind = released
          ? MouseButtonKind.lmbUp.takeIf(lmb) ??
              MouseButtonKind.mmbUp.takeIf(mmb) ??
              MouseButtonKind.rmbUp.takeIf(rmb)
          : MouseButtonKind.lmbDown.takeIf(lmb) ??
              MouseButtonKind.mmbDown.takeIf(mmb) ??
              MouseButtonKind.rmbDown.takeIf(rmb);
      if (kind != null) event = MouseButtonEvent(kind, x, y);
    }

    // printable <ESC> has 5 characters but is 1 byte in bytes. therefore: - 4
    final skip = it.end - 4;
    return (event, skip);
  }

  ControlKey? _lookup(List<int> suffix, int mod) {
    final stripped = [_esc, _ctl, ...suffix].printable;
    final found = _controls[stripped];
    if (found == null) return null;
    final ctrl = mod == 53 || mod == 54 || mod == 55 || mod == 56;
    final alt = mod == 51 || mod == 52 || mod == 55 || mod == 56;
    final shift = mod == 50 || mod == 52 || mod == 54 || mod == 56;
    return ControlKey(found, alt: alt, ctrl: ctrl, shift: shift);
  }

  // oh what a mess.. i decided to explicitly not look up any information.. so this will most
  // probably fail in multiple ways on different setups.. and surely won't work for Windows and
  // probably not even for MacOS... but it's enough for my use case for now.. ‾\_('')_/‾
  final _controls = {
    "<BACKSPACE>": Control.Backspace,
    "<DEL>": Control.Delete,
    "<ESC>": Control.Escape,
    "<ESC>OM": Control.NumPadEnter,
    "<ESC>OP": Control.F1,
    "<ESC>OQ": Control.F2,
    "<ESC>OR": Control.F3,
    "<ESC>OS": Control.F4,
    "<ESC>Oj": Control.NumPadStar,
    "<ESC>Ok": Control.NumPadPlus,
    "<ESC>Om": Control.NumPadMinus,
    "<ESC>Oo": Control.NumPadSlash,
    "<ESC>[15~": Control.F5,
    "<ESC>[17~": Control.F6,
    "<ESC>[18~": Control.F7,
    "<ESC>[19~": Control.F8,
    "<ESC>[20~": Control.F9,
    "<ESC>[21~": Control.F10,
    "<ESC>[22~": Control.F11,
    "<ESC>[23~": Control.F12,
    "<ESC>[2~": Control.Insert,
    "<ESC>[3~": Control.Delete,
    "<ESC>[5~": Control.PageUp,
    "<ESC>[6~": Control.PageDown,
    "<ESC>[A": Control.Up,
    "<ESC>[B": Control.Down,
    "<ESC>[C": Control.Right,
    "<ESC>[D": Control.Left,
    "<ESC>[F": Control.End,
    "<ESC>[H": Control.Home,
    "<ESC>[P": Control.F1,
    "<ESC>[Q": Control.F2,
    "<ESC>[R": Control.F3,
    "<ESC>[S": Control.F4,
    "<RETURN>": Control.Return,
    "<TAB>": Control.Tab,
  };
}

class TestMatching with InputMatching {
  (MouseEvent?, int) handleMouseEvent(List<int> bytes, RegExpMatch it) =>
      _handleMouseEvent(bytes, it);
}
