part of 'desktop.dart';

class MatchResult {
  final Iterable<Matcher> matches;
  final Iterable<Matcher> partials;
  final Iterable<Matcher> completed;

  bool get isEmpty => matches.isEmpty && partials.isEmpty && completed.isEmpty;

  MatchResult(this.matches, this.partials, this.completed);

  MatchResult operator +(MatchResult other) {
    return MatchResult(matches + other.matches, partials + other.partials,
        completed + other.completed);
  }

  static final empty = MatchResult([], [], []);

  static final consumed = MatchResult([], [], []);
}

mixin KeyHandling {
  var _keyTimeoutMillis = 600;

  int get keyTimeoutMillis => _keyTimeoutMillis;

  set keyTimeoutMillis(int value) => _keyTimeoutMillis = value < 0 ? 0 : value;

  final _matchers = <Matcher>[];
  Timer? _autoReset;

  KeyHandling? _nested;

  _onKeyEvent(KeyEvent it) {
    _autoReset?.cancel();

    final nested = _nested?.match(it) ?? MatchResult.empty;
    final result = nested + match(it);
    final matches = result.matches;
    final partials = result.partials;

    // if match found, but no partials, reset matching, trigger first match, and be done here:
    if (matches.isNotEmpty && partials.isEmpty) {
      // prioritize completed partial matches. this allows a global "gx" to
      // override a local "x".
      final completed = result.completed.firstOrNull;
      final match = completed ?? matches.firstOrNull;
      match?.trigger();
      _reset();
      return;
    }

    // if nothing matched at all, immediately reset and be done:
    if (matches.isEmpty && partials.isEmpty) {
      _reset();
      return;
    }

    // otherwise we have partial matches.

    // auto reset these after a timeout if a timeout is set:
    if (_keyTimeoutMillis != 0) {
      _autoReset = Timer(keyTimeoutMillis.millis, () {
        matches.firstOrNull?.trigger();
        _reset();
      });
    }
  }

  void _reset() {
    _nested?._reset();
    _autoReset?.cancel();
    _resetMatchers();
  }

  MatchResult match(KeyEvent it) {
    for (final matcher in _matchers) {
      matcher.consume(it);
    }

    final matches = _matchers.where((element) => element.isMatch());
    final partials = _matchers.where((element) => element.isPartialMatch());
    final completed = _matchers.where((element) => element.isCompletedMatch());
    return MatchResult(matches, partials, completed);
  }

  void _resetMatchers() {
    for (final e in _matchers) {
      e.reset();
    }
  }

  /// Add a key handler matching the given [pattern] or any of the given [aliases], if any.
  /// [description] is used when showing the current keymap configuration. [action] will be
  /// executed when the [pattern] or one of the [aliases] is matched to user input.
  Disposable onKey(
    String pattern, {
    List<String> aliases = const [],
    required String description,
    required Function action,
  }) {
    final patterns = [pattern, ...aliases];
    if (_matchers.any((m) => m.overlaps(patterns))) {
      final found = _matchers.map((e) => (e.patterns, e.description)).join(',');
      throw ArgumentError('pattern overlap: $found', patterns.join(','));
    }
    var it = Matcher(patterns, description, action);
    _matchers.add(it);
    return Disposable.wrap(() => _matchers.remove(it));
  }

  Iterable<(String, String)> keyMapEntries() =>
      _matchers.map((e) => (e.patterns.toString(), e.description));
}

extension on Matcher {
  bool overlaps(List<String> patterns) =>
      this.patterns.any((e) => patterns.contains(e));
}

class Matcher {
  final List<String> patterns;
  final String description;
  final Function _handler;

  bool _wasPartial = false;
  String _buffer = "";

  Matcher(this.patterns, this.description, this._handler);

  void consume(KeyEvent it) {
    _buffer = _buffer + it.printable;
    _wasPartial = _wasPartial | isPartialMatch();
  }

  bool isPartialMatch() =>
      !isMatch() && patterns.any((it) => it.startsWith(_buffer));

  bool isCompletedMatch() => isMatch() && _wasPartial;

  bool isMatch() => patterns.any((it) => it == _buffer);

  void trigger() => _handler();

  void reset() {
    _wasPartial = false;
    _buffer = "";
  }

  @override
  String toString() => "$patterns <=> $_buffer";
}
