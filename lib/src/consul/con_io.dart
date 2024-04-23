part of 'desktop.dart';

/// Defines the required functionality to be provided from a console/terminal.
abstract interface class ConIO {
  /// When true, "ctrl-c" is intercepted and delivered via [onKeyEvent]. Otherwise, the program is
  /// terminated via [exit] call.
  bool interceptSigInt = false;

  /// When set, will receive all understood [KeyEvent]s.
  abstract KeyHandler onKeyEvent;

  /// When set, will receive all understood [MouseEvent]s.
  abstract MouseHandler onMouseEvent;

  /// Current terminal width in characters.
  int columns();

  /// Current terminal height in characters.
  int rows();

  /// Clear the terminal. Does not necessarily change the cursor position.
  void clear();

  /// Position the cursor at the specified position.
  void moveCursor(int column, int row);

  /// Write the given [buffer] at the current cursor position. Line breaks and control characters
  /// etc are supported/interpreted.
  void write(String buffer);
}
