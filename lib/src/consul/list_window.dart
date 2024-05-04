// ignore_for_file: unused_local_variable, non_constant_identifier_names

import 'dart:math';

import 'package:dart_consul/dart_consul.dart';
import 'package:rxdart/rxdart.dart';

class ListWindow {
  final Window _window;
  final int _topOff;
  final int _bottomOff;
  String Function(String) asSelected;
  String Function(String)? asUnfocusedSelected;
  Function(int)? onSelect;

  var _clearedAt = -1;
  final _selected = BehaviorSubject.seeded(-1);
  late final ScrolledContent _scrolled;
  String _buffer = "";
  List<String> _entries = [];
  List<int> _indexes = [];

  int get selected => _selected.value;

  bool get isEmpty => _entries.isEmpty;

  String? get header => _scrolled.header;

  set header(String? header) => _scrolled.header = header;

  ListWindow({
    required Window window,
    required int topOff,
    required int bottomOff,
    bool escapeToClear = true,
    bool extendName = true,
    String? header,
    this.asSelected = inverse,
    this.asUnfocusedSelected,
    this.onSelect,
  })  : _window = window,
        _topOff = topOff,
        _bottomOff = bottomOff {
    //
    _scrolled = scrolled(
      _window,
      () => _buffer,
      header: header,
      extendName: extendName,
      defaultShortcuts: false,
    );

    _window.chainOnMouseEvent((e) {
      if (!e.isUp || e.y < 1) return null;
      return _clickSelect(e);
    });

    void gotoFirst() {
      if (_entries.isEmpty) return;
      _selected.value = 0;
      _keySelect(0);
    }

    void gotoLast() {
      if (_entries.isEmpty) return;
      _selected.value = _entries.length - 1;
      _keySelect(0);
    }

    final jump = max(3, _window.height - 4);
    _window.onKey('gg', description: 'Select first entry', action: gotoFirst);
    _window.onKey('<S-g>', description: 'Select last entry', action: gotoLast);
    _window.onKey('k',
        description: 'Select previous entry', action: () => _keySelect(-1));
    _window.onKey('j',
        description: 'Select next entry', action: () => _keySelect(1));
    _window.onKey('<S-k>',
        description: 'Select previous entry', action: () => _keySelect(-jump));
    _window.onKey('<S-j>',
        description: 'Select next entry', action: () => _keySelect(jump));

    if (escapeToClear) {
      _window.onKey('<Escape>', description: 'Clear selection', action: () {
        _clearedAt = _selected.value;
        _selected.value = -1;
        _refresh();
      });
    }

    _window.onKey('<Return>',
        aliases: ['<Space>'],
        description: 'Toggle entry action',
        action: () => _toggleAction());

    _window.onFocusChanged.add(_refresh);
  }

  void updateEntries(List<String> entries) {
    _entries = entries;
    _refresh();
  }

  void _refresh() {
    _indexes = [];

    final output = <String>[];
    for (final (i, e) in _entries.indexed) {
      final lines = e.split('\n');
      for (final l in lines) {
        _indexes.add(i);
        if (i == _selected.value && _window.isFocused) {
          output.add(asSelected(l));
        } else if (i == _selected.value && asUnfocusedSelected != null) {
          output.add(asUnfocusedSelected!(l));
        } else {
          output.add(l);
        }
      }
    }
    _buffer = output.join('\n');

    _window.requestRedraw();
  }

  void _toggleAction() {
    final s = _selected.value;
    if (s == -1) return;
    final os = onSelect;
    if (os == null) return;
    os(s);
    _keySelect(0);
  }

  ConsumedMouseAction _clickSelect(MouseEvent e) {
    final offset = header != null ? 2 : 1;
    final index = e.y - offset + _scrolled.scrollOffset;
    if (index < 0 || index >= _entries.length) {
      return ConsumedMouseAction(_window);
    }

    final it = _indexes[index];
    _selected.value = it;
    _toggleAction();

    return ConsumedMouseAction(_window);
  }

  void _keySelect(int delta) {
    if (_entries.isEmpty) return;

    var sv = _selected.value;
    if (sv == -1) {
      sv = _clearedAt;
      _clearedAt = -1;
    }

    final target = sv + delta;
    final newIndex = target.clamp(0, _entries.length - 1);
    _selected.value = newIndex;

    final so = _scrolled.scrollOffset;
    final si = _indexes.indexWhere((e) => e == newIndex);
    if (si < so + _topOff + 1) {
      _scrolled.scrollOffset = si - _topOff;
    }
    if (si > so + _window.height - _bottomOff - 1) {
      _scrolled.scrollOffset = si - _window.height + _bottomOff + 1;
    }

    _refresh();
  }
}
