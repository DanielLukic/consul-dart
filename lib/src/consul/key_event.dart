// ignore_for_file: constant_identifier_names

part of 'desktop.dart';

typedef KeyHandler = Function(KeyEvent);

/// Represents incoming low-level events (keyboard and mouse).
class RawEvent {
  final List<int> raw;
  final String printable;

  RawEvent(this.raw, this.printable);

  @override
  String toString() => "${raw.toByteHexString(delimiter: " ")} $printable";
}

/// Represents the various kinds of incoming key events.
sealed class KeyEvent {
  bool alt;
  bool ctrl;
  bool shift;

  KeyEvent({required this.alt, required this.ctrl, required this.shift});

  String get printable;
}

/// Represents an "unidentified key sequence" event.
class Unidentified extends KeyEvent {
  final RawEvent event;

  Unidentified(this.event) : super(alt: false, ctrl: false, shift: false);

  @override
  String toString() => "unidentified: $event";

  @override
  String get printable => "<${event.printable}>";
}

/// Represents an identified control-key event.
class ControlKey extends KeyEvent {
  final Control key;

  ControlKey(this.key, {bool? alt, bool? ctrl, bool? shift})
      : super(alt: alt ?? false, ctrl: ctrl ?? false, shift: shift ?? false);

  @override
  String toString() => "<${key.name}>: alt=$alt ctrl=$ctrl shift=$shift";

  @override
  String get printable {
    final prefix = StringBuffer();
    if (alt) prefix.write("A-");
    if (ctrl) prefix.write("C-");
    if (shift) prefix.write("S-");
    return "<$prefix${key.name}>";
  }
}

/// Represents an identified "printable key" event.
class InputKey extends KeyEvent {
  final String char;
  final int code;

  InputKey(this.char, this.code, {bool? alt, bool? ctrl, bool? shift})
      : super(alt: alt ?? false, ctrl: ctrl ?? false, shift: shift ?? false);

  String get _char => code == 32 ? '<Space>' : char;

  @override
  String toString() => "$_char($code): alt=$alt ctrl=$ctrl shift=$shift";

  @override
  String get printable {
    if (!alt && !ctrl && !shift) return _char;
    final prefix = StringBuffer();
    if (alt) prefix.write("A-");
    if (ctrl) prefix.write("C-");
    if (shift) prefix.write("S-");
    if (code == 32) return "<${prefix}Space>";
    return "<$prefix${char.toLowerCase()}>";
  }
}

/// Identifies the supported control keys. Captured via [ControlKey] events.
enum Control {
  Backspace,
  Delete,
  Down,
  End,
  Enter,
  Escape,
  F1,
  F10,
  F11,
  F12,
  F2,
  F3,
  F4,
  F5,
  F6,
  F7,
  F8,
  F9,
  Home,
  Insert,
  Left,
  NumPadEnter,
  NumPadMinus,
  NumPadPlus,
  NumPadSlash,
  NumPadStar,
  PageDown,
  PageUp,
  Return,
  Right,
  Tab,
  Up,
}
