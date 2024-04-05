part of 'mad_con_io.dart';

extension on int? {
  bool get isSigIntTrigger => this == 3;
}

extension on List<int> {
  String get printable => map((it) => it.printable).join();
}

extension on int {
  String get printable {
    if (this == 8) return "<DEL>";
    if (this == 9) return "<TAB>";
    if (this == 10) return "<ENTER>";
    if (this == 13) return "<RETURN>";
    if (this == 27) return "<ESC>";
    if (this == 127) return "<BACKSPACE>";
    if (this == 31) return "<C-?>";
    if (this < 32) return "<C-${String.fromCharCode(this + 96)}>";
    return String.fromCharCode(this);
  }

  bool get isShifted => 'A'.codeUnitAt(0) <= this && this <= 'Z'.codeUnitAt(0);

  String get char => String.fromCharCode(this);

  String get alphaChar => String.fromCharCode(96 + this);
}

extension on dc.Console {
  set cursor(bool enabled) {
    if (enabled) {
      showCursor();
    } else {
      hideCursor();
    }
  }

  set mouseMode(bool value) {
    write("\x1b[?1000;1002;1003;1006;1015${value ? 'h' : 'l'}");
  }
}
