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

typedef _NotificationEntry = (DesktopNotification, Window, DateTime);

final List<_NotificationEntry> _shownNotifications = [];

_NotificationEntry? _selected;

extension DesktopNotifications on Desktop {
  void clearNotifications() {
    dispose('notifications-timer');
    while (_shownNotifications.isNotEmpty) {
      _closeOldestNotification();
    }
  }

  void triggerLatestNotification() {
    final s = _shownNotifications.lastOrNull;
    if (s != null) _triggerNotification(s);
  }

  void _triggerNotification(_NotificationEntry it) {
    sendMessage(it.$1.onClickMsg);
    _closeNotification(it);
  }

  void selectNotificationArea() {
    if (_shownNotifications.isEmpty) return;

    _selected ??= _shownNotifications.lastOrNull;
    _forceFocusSelectedNotification();
  }

  void _forceFocusSelectedNotification() {
    if (_selected != null) _updateFocus(override: _selected?.$2);
    redraw();
  }

  void selectPreviousNotification() {
    if (_shownNotifications.isEmpty) return;

    final s = _selected;
    if (s == null) {
      _selected = _shownNotifications.lastOrNull;
    } else {
      var i = _shownNotifications.indexOf(s) - 1;
      if (i < 0) i = _shownNotifications.length - 1;
      _selected = _shownNotifications[i];
    }

    _forceFocusSelectedNotification();
  }

  void selectNextNotification() {
    if (_shownNotifications.isEmpty) return;

    final s = _selected;
    if (s == null) {
      _selected = _shownNotifications.firstOrNull;
    } else {
      var i = _shownNotifications.indexOf(s) + 1;
      if (i > _shownNotifications.length - 1) i = 0;
      _selected = _shownNotifications[i];
    }

    _forceFocusSelectedNotification();
  }

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

  void _closeOldestNotification() =>
      _closeNotification(_shownNotifications.removeAt(0));

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
      redraw: () => _drawNotification(dn).frame(),
    );
    final it = (dn, w, DateTime.timestamp());
    w.onKey('<Escape>', description: 'Unfocus notification area', action: () {
      _selected = null;
      _updateFocus();
      redraw();
    });
    w.onKey('<Return>', description: 'Trigger notification action', action: () {
      _triggerNotification(it);
    });
    w.onKey('x', description: 'Close notification', action: () {
      _closeNotification(it);
      selectPreviousNotification();
    });
    w.onKey(
      'j',
      aliases: ['<Tab>'],
      description: 'Previous notification',
      action: () => selectPreviousNotification(),
    );
    w.onKey(
      'k',
      aliases: ['<S-Tab>'],
      description: 'Next notification',
      action: () => selectNextNotification(),
    );
    w.chainOnMouseEvent((e) {
      if (e.isUp) _triggerNotification(it);
      return ConsumedMouseAction(w);
    });
    _shownNotifications.add(it);
    openWindow(w);
    _updateNotifications();
  }

  void _closeNotification(_NotificationEntry it) {
    if (_selected == it) _selected = null;
    _shownNotifications.remove(it);
    closeWindow(it.$2);
    _updateNotifications();
  }

  Buffer _drawNotification(DesktopNotification dn) {
    final lines = dn.message.autoWrap(38).take(_maxNotificationLines);
    final buffer = Buffer(42, lines.length + 4);
    buffer.drawBuffer(40 - dn.tag.length, 1, dn.tag);
    buffer.drawBuffer(2, 1, dn.title);
    buffer.drawBuffer(2, 3, lines.join('\n'));
    final style = _isSelected(dn) ? doubleBorder : roundedBorder;
    buffer.drawBorder(0, 0, buffer.width, buffer.height, style);
    return buffer;
  }

  bool _isSelected(DesktopNotification dn) =>
      _selected?.$1 == dn && _selected?.$2 == _focused;
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
