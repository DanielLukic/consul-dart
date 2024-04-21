import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_consul/common.dart';
import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

extension DialogExtensions on Dialog {
  void attach(DuiLayout layout) {
    nested = layout;
    redraw = layout.redraw;
    onKeyEvent = layout;
    onMouseEvent = layout.onMouseEvent;
    layout.requestRedraw = requestRedraw;
  }
}

class DuiState {
  final void Function() onChange;

  final _data = <String, dynamic>{};

  DuiState(this.onChange);

  dynamic operator [](String key) => _data[key];

  void operator []=(String key, dynamic value) {
    if (identical(_data[key], value)) return;
    if (_data[key] == value) return;
    _data[key] = value;
    onChange();
  }
}

class DuiLayout with KeyHandling {
  late final DuiState _state;
  final DuiElement _element;

  DuiLayout({DuiState? state, required DuiElement root}) : _element = root {
    _state = state ?? DuiState(() => requestRedraw());

    DuiContainer.doForEach(_element, (e) {
      e.requestRedraw = () => requestRedraw();
      if (e case DuiFocusable f) f.isFocused = (e) => e == focused;
    });
    final focusables = DuiContainer.focusablesFrom(_element);
    final focusedId = _state['DuiLayout#focused#id'];
    focused = focusables.firstWhereOrNull((e) => e.id == focusedId);
    focused ??= focusables.firstOrNull;
    nested = focused;
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

    final nested = this.nested?.match(it) ?? MatchResult.empty;
    logVerbose('nested $nested');
    if (nested == MatchResult.consumed) return nested;

    final ours = super.match(it);
    logVerbose('ours $ours');

    return nested + ours;
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
    _state['DuiLayout#focused#id'] = focused?.id;
    nested = focused;
    return MatchResult.consumed;
  }

  DuiFocusable? focused;
}

abstract class DuiFocusable extends BaseElement with KeyHandling {
  DuiFocusable(String id) {
    super.id = id;
  }

  late bool Function(DuiFocusable) isFocused;

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

class DuiButton extends DuiFocusable {
  final String text;

  void Function() onClick = () {};

  DuiButton({
    required String id,
    required this.text,
    bool defaultKeys = true,
  }) : super(id) {
    onKey('<Return>', description: 'Trigger button', action: () => onClick());
  }

  @override
  int width() =>
      text.split('\n').fold(0, (w, r) => max(w, r.stripped().length)) + 2;

  @override
  int height() => text.split('\n').length + 2;

  @override
  String renderUnfocused(int maxWidth) {
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

  DuiTextInput({
    required String id,
    this.limitLength,
    String? preset,
    this.filter,
  }) : super(id) {
    if (preset != null) _input = preset;
  }

  @override
  MatchResult match(KeyEvent it) {
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

  DuiPadding.hv({int h = 0, int v = 0, required DuiElement wrapped})
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
  final bool autoSpace;

  DuiRow(List<DuiElement> elements, {this.autoSpace = true}) {
    for (final e in elements) {
      _elements.add(e);
      if (autoSpace && e != elements.lastOrNull) _elements.add(DuiSpace());
    }
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

class DuiSwitcher<T> extends DuiFocusable {
  final List<(String, T)> entries;
  late T? selected;

  void Function(T) onSelection = (_) {};

  DuiSwitcher({
    required String id,
    required this.entries,
    T? selected,
    bool defaultKeys = true,
  }) : super(id) {
    this.selected = selected ?? entries.firstOrNull?.$2;
    if (!defaultKeys) return;
    onKey('j', description: 'Select next entry', action: () => select(1));
    onKey('k', description: 'Select previous entry', action: () => select(-1));
  }

  void select(int direction) {
    if (entries.isEmpty) return;
    final index = entries.indexWhere((e) => e.$2 == selected);
    if (selected == null || index == -1) {
      if (direction > 0) selected = entries.firstOrNull?.$2;
      if (direction < 0) selected = entries.lastOrNull?.$2;
    } else {
      final was = selected;
      final target = (index + direction) % entries.length;
      final now = entries[target].$2;
      if (was != now) onSelection(now);
      selected = now;
    }
  }

  @override
  int width() {
    if (entries.isEmpty) return 0;
    return entries.map((e) => e.$1.length).max + 4;
  }

  @override
  int height() {
    if (entries.isEmpty) return 0;
    return 3;
  }

  @override
  String renderUnfocused(int maxWidth) {
    if (entries.isEmpty) return "";
    final label = entries.where((e) => e.$2 == selected).firstOrNull?.$1;
    if (label == null) return "";
    final buffer = Buffer(width(), height());
    buffer.drawBuffer(1, 1, label);
    buffer.drawBuffer(width() - 2, 1, '◥');
    buffer.drawBorder(0, 0, width(), height(), roundedBorder);
    return buffer.frame();
  }
}
