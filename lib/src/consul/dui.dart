import 'dart:math';

import 'package:dart_consul/common.dart';
import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

extension DialogExtensions on Dialog {
  void attach(DuiLayout layout) {
    redraw = layout.redraw;
    onKeyEvent = layout;
    onMouseEvent = layout.onMouseEvent;
    layout.requestRedraw = requestRedraw;
  }
}

class DuiLayout with KeyHandling {
  final DuiElement _element;

  DuiLayout(this._element) {
    DuiContainer.doForEach(_element, (e) {
      e.requestRedraw = () => requestRedraw();
      if (e case DuiFocusable f) f.isFocused = (e) => e == focused;
    });
    focused = DuiContainer.focusablesFrom(_element).firstOrNull;
  }

  Function() requestRedraw = () {};

  String redraw() => _element.render(_element.width());

  void onMouseEvent(MouseEvent event) => logWarn('nyi');

  @override
  MatchResult match(KeyEvent it) {
    if (it.printable == '<Tab>') {
      return _tabChange(1);
    } else if (it.printable == '<S-Tab>') {
      return _tabChange(-1);
    }

    final f = focused;
    if (f != null) {
      final mr = f.consumeMatch(it);
      if (mr == MatchResult.consumed) {
        logVerbose('focused consumed $it');
        return mr;
      } else {
        return super.match(it);
      }
    } else {
      final smr = super.match(it);
      if (smr.isEmpty) {
        return MatchResult.empty;
      } else {
        return smr;
      }
    }
  }

  MatchResult _tabChange(int direction) {
    final focusable = DuiContainer.focusablesFrom(_element);
    final index = focusable.indexWhere((e) => identical(e, focused));
    if (index == -1) {
      focused = focusable.firstOrNull;
    } else {
      final next = (index + direction) % focusable.length;
      focused = focusable[next];
    }
    return MatchResult.consumed;
  }

  DuiFocusable? focused;
}

abstract class DuiFocusable extends BaseElement {
  late bool Function(DuiFocusable) isFocused;

  MatchResult consumeMatch(KeyEvent it) => MatchResult.empty;

  String renderUnfocused(int maxWidth);

  @override
  String render(int maxWidth) {
    if (!isFocused(this)) return renderUnfocused(maxWidth);

    final unfocused = renderUnfocused(maxWidth);
    final buffer = Buffer(width(), height());
    buffer.drawBuffer(0, 0, unfocused.stripped().whiteBright());
    return buffer.frame();
  }
}

abstract interface class DuiContainer {
  void forEach(Function(DuiElement) func);

  List<DuiFocusable> focusables();

  static List<DuiFocusable> focusablesFrom(DuiElement it) => switch (it) {
        DuiContainer x => x.focusables(),
        DuiFocusable f => [f],
        _ => const [],
      };

  static doForEach(DuiElement it, Function(DuiElement) func) {
    if (it case DuiElement e) func(e);
    if (it case DuiContainer x) x.forEach(func);
  }
}

abstract interface class DuiElement {
  set requestRedraw(OnRedraw onRedraw);

  int width();

  int height();

  String render(int maxWidth);

  String? id;
}

abstract class BaseElement implements DuiElement {
  @override
  OnRedraw requestRedraw = () => null;

  @override
  String? id;
}

class DuiSpace extends BaseElement {
  final int size;

  DuiSpace([this.size = 1]);

  @override
  int width() => size;

  @override
  int height() => size;

  @override
  String render(int maxWidth) => Buffer(width(), height()).render();
}

class DuiButton extends BaseElement {
  final String text;

  DuiButton(this.text);

  @override
  int width() =>
      text.split('\n').fold(0, (w, r) => max(w, r.stripped().length)) + 2;

  @override
  int height() => text.split('\n').length + 2;

  @override
  String render(int maxWidth) {
    final buffer = Buffer(width(), height());
    buffer.drawBorder(0, 0, width(), height(), roundedBorder);
    buffer.drawBuffer(1, 1, text);
    return buffer.render();
  }
}

class DuiTitle extends BaseElement {
  final String text;

  DuiTitle(this.text);

  @override
  int width() =>
      text.split('\n').fold(0, (w, r) => max(w, r.stripped().length));

  @override
  int height() => text.split('\n').length;

  @override
  String render(int maxWidth) => italic(bold(text));
}

class DuiText extends BaseElement {
  final String text;

  DuiText(this.text);

  DuiText.fromLines(Iterable<String> lines) : this(lines.join('\n'));

  @override
  int width() =>
      text.split('\n').fold(0, (w, r) => max(w, r.stripped().length));

  @override
  int height() => text.split('\n').length;

  @override
  String render(int maxWidth) => text;
}

class DuiTextInput extends DuiFocusable {
  String _input = "";

  int? limitLength;

  String get input => _input;

  set input(String it) {
    _input = it;
    requestRedraw();
  }

  Pattern? filter;

  DuiTextInput({this.limitLength, String? preset, this.filter}) {
    if (preset != null) _input = preset;
  }

  @override
  MatchResult consumeMatch(KeyEvent it) {
    if (it is InputKey) {
      if (it.printable == "<C-u>") input = "";

      var checked = input + it.char;
      if (limitLength != null) {
        checked = checked.take(limitLength!);
      }
      if (filter != null) {
        final m = filter!.matchAsPrefix(checked);
        if (m == null) return MatchResult.empty;
        if (m.end != checked.length) return MatchResult.empty;
      }
      input = checked;
      return MatchResult.consumed;
    }
    if (it is ControlKey && it.key == Control.Backspace) {
      input = input.dropLast(1);
      return MatchResult.consumed;
    }
    return MatchResult.empty;
  }

  @override
  int width() => (limitLength ?? 20) + 2;

  @override
  int height() => 3;

  @override
  String renderUnfocused(int maxWidth) {
    final buffer = Buffer(width(), height());
    buffer.drawBuffer(1, 1, input);
    buffer.drawBorder(0, 0, width(), height(), inputBorder);
    return buffer.render();
  }
}

class DuiPadding extends BaseElement implements DuiContainer {
  final DuiElement wrapped;
  final int left;
  final int top;
  final int right;
  final int bottom;

  DuiPadding.hv(DuiElement wrapped, {int h = 0, int v = 0})
      : this(wrapped, left: h, top: v, right: h, bottom: v);

  DuiPadding(
    this.wrapped, {
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  })  : assert(left >= 0, "left >= 0: $left"),
        assert(top >= 0, "top >= 0: $top"),
        assert(right >= 0, "right >= 0: $right"),
        assert(bottom >= 0, "bottom >= 0: $bottom");

  @override
  void forEach(Function(DuiElement) func) =>
      DuiContainer.doForEach(wrapped, func);

  @override
  List<DuiFocusable> focusables() => DuiContainer.focusablesFrom(wrapped);

  @override
  int width() => wrapped.width() + left + right;

  @override
  int height() => wrapped.height() + top + bottom;

  @override
  String render(int maxWidth) {
    final buffer = Buffer(width(), height());
    buffer.drawBuffer(left, top, wrapped.render(maxWidth));
    return buffer.frame();
  }
}

class DuiBorder extends BaseElement implements DuiContainer {
  final DuiElement wrapped;
  final List<String> style;

  DuiBorder(this.wrapped, {this.style = defaultBorder});

  @override
  void forEach(Function(DuiElement) func) =>
      DuiContainer.doForEach(wrapped, func);

  @override
  List<DuiFocusable> focusables() => DuiContainer.focusablesFrom(wrapped);

  @override
  int width() => wrapped.width() + 2;

  @override
  int height() => wrapped.height() + 2;

  @override
  String render(int maxWidth) {
    final buffer = Buffer(width(), height());
    buffer.drawBorder(0, 0, width(), height(), style);
    buffer.drawBuffer(1, 1, wrapped.render(maxWidth));
    return buffer.render();
  }
}

class DuiColumn extends BaseElement implements DuiContainer {
  final List<DuiElement> _elements = [];

  DuiColumn([List<DuiElement> elements = const []]) {
    _elements.addAll(elements);
  }

  void add(DuiElement element) => _elements.add(element);

  @override
  void forEach(Function(DuiElement) func) {
    for (final e in _elements) {
      DuiContainer.doForEach(e, func);
    }
  }

  @override
  List<DuiFocusable> focusables() =>
      [for (final e in _elements) ...DuiContainer.focusablesFrom(e)];

  @override
  int width() => _elements.fold(0, (w, e) => max(w, e.width()));

  @override
  int height() => _elements.fold(0, (h, e) => h + e.height());

  @override
  String render(int maxWidth) {
    final buffer = Buffer(width(), height());
    var row = 0;
    for (final e in _elements) {
      buffer.drawBuffer(0, row, e.render(buffer.width));
      row += e.height();
    }
    return buffer.frame();
  }
}

class DuiRow extends BaseElement implements DuiContainer {
  final List<DuiElement> _elements = [];

  DuiRow([List<DuiElement> elements = const []]) {
    _elements.addAll(elements);
  }

  void add(DuiElement element) => _elements.add(element);

  @override
  void forEach(Function(DuiElement) func) {
    for (final e in _elements) {
      DuiContainer.doForEach(e, func);
    }
  }

  @override
  List<DuiFocusable> focusables() =>
      [for (final e in _elements) ...DuiContainer.focusablesFrom(e)];

  @override
  int width() => _elements.fold(0, (w, e) => w + e.width());

  @override
  int height() => _elements.fold(0, (h, e) => max(h, e.height()));

  @override
  String render(int maxWidth) {
    final buffer = Buffer(width(), height());
    var column = 0;
    for (final e in _elements) {
      buffer.drawBuffer(column, 0, e.render(buffer.width));
      column += e.width();
    }
    return buffer.frame();
  }
}
