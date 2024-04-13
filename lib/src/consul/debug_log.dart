part of 'desktop.dart';

abstract interface class LogView {
  List<String> get entries;
}

/// Basic auto-timestamped log.
class DebugLog implements LogView {
  final void Function() _redraw;

  @override
  final entries = <String>[];

  final int maxSize;

  DebugLog({required Function() redraw, this.maxSize = 100}) : _redraw = redraw;

  void clear() {
    entries.clear();
    _redraw();
  }

  void add(message) {
    while (entries.length >= maxSize) {
      entries.removeLast();
    }
    entries.insert(0, _timestamped(DateTime.now(), message.toString()));
    _redraw();
  }

  String _timestamped(DateTime dt, String message) {
    // lovely :-D
    final timestamp = dt.toIso8601String().split("T").last.split('.').first;
    return "$timestamp $message";
  }
}
