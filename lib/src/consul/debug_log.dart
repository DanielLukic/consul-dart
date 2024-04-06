part of 'desktop.dart';

/// Basic debug log for "on-screen" (where else? ^^) display. Holds the ten last [RawEvent]s
/// received from the terminal.
class DebugLog {
  final _entries = <(DateTime, String)>[];

  void Function() redraw = () {};

  void clear() => _entries.clear();

  void add(message) {
    while (_entries.length >= 100) {
      _entries.removeAt(0);
    }
    _entries.add((DateTime.now(), message.toString()));
    redraw();
  }

  Iterable<String> allReversed() =>
      _entries.reversed.map((e) => _timestamped(e));

  Iterable<String> reversed(int count) =>
      _entries.reversed.take(count).map((e) => _timestamped(e));

  String _timestamped((DateTime, String) e) {
    // lovely :-D
    final timestamp = e.$1.toIso8601String().split("T").last;
    return "$timestamp: ${e.$2}";
  }
}

final eventDebugLog = DebugLog();
