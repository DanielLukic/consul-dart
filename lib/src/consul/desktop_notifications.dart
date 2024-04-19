part of 'desktop.dart';

class DesktopNotification {
  final String title;
  final String tag;
  final String message;
  final dynamic onClickMsg;

  DesktopNotification(this.title, this.tag, this.message, this.onClickMsg);

  @override
  String toString() => title;
}

const int _maxNotifications = 5;
const int _maxNotificationLines = 3;

final List<(DesktopNotification, Window, DateTime)> _shownNotifications = [];

extension DesktopNotifications on Desktop {
  void notify(DesktopNotification dn) {
    autoDispose(
      'notifications-timer',
      Timer.periodic(10.seconds, _timeoutNotifications),
    );
    if (_shownNotifications.length >= _maxNotifications) {
      _closeOldestNotification();
    }
    _openNotification(dn);
  }

  void _timeoutNotifications(Timer _) {
    if (_shownNotifications.isEmpty) {
      dispose('notifications-timer');
      return;
    }

    final now = DateTime.timestamp();
    final (_, _, ts) = _shownNotifications[0];
    if (ts.difference(now).inMinutes < -10) _closeOldestNotification();
  }

  void _closeOldestNotification() {
    final (_, w, _) = _shownNotifications.removeAt(0);
    closeWindow(w);
    _updateNotifications();
  }

  void _updateNotifications() {
    var offset = 0;
    for (final (_, w, _) in _shownNotifications) {
      w.position = RelativePosition.fromBottomRight(
        xOffset: 0,
        yOffset: offset,
      );
      offset -= w.height;
    }
  }

  void _openNotification(DesktopNotification dn) {
    final b = _drawNotification(dn);
    final w = Window(
      'dn',
      'dn',
      position: RelativePosition.fromBottomRight(),
      size: WindowSize.fixed(Size(b.width, b.height)),
      flags: {
        WindowFlag.alwaysOnTop,
        WindowFlag.undecorated,
        WindowFlag.unmovable,
      },
      redraw: () => b.frame(),
    );
    _shownNotifications.add((dn, w, DateTime.timestamp()));
    openWindow(w);
    _updateNotifications();
  }

  Buffer _drawNotification(DesktopNotification dn) {
    final lines = dn.message.autoWrap(38).take(_maxNotificationLines);
    final buffer = Buffer(42, lines.length + 4);
    buffer.drawBuffer(40 - dn.tag.length, 1, dn.tag);
    buffer.drawBuffer(2, 1, dn.title);
    buffer.drawBuffer(2, 3, lines.join('\n'));
    buffer.drawBorder(0, 0, buffer.width, buffer.height, roundedBorder);
    return buffer;
  }
}

extension on String {
  List<String> autoWrap(int maxLength) {
    final result = <String>[];
    final words = split(' ');
    final buffer = StringBuffer();
    for (final w in words) {
      if (buffer.isNotEmpty && buffer.length + 1 + w.length >= maxLength) {
        result.add(buffer.toString());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(w);
      if (identical(w, words.last) && buffer.isNotEmpty) {
        result.add(buffer.toString());
        buffer.clear();
      }
    }
    return result;
  }
}
