part of 'desktop.dart';

/// Somewhat generic types of results that can be returned from query dialogs.
sealed class QueryResult {
  static final cancel = QueryCancel();
  static final positive = QueryPositive();
}

/// If canceling is allowed.
class QueryCancel extends QueryResult {}

/// On positive choice.
class QueryPositive extends QueryResult {}

// /// On negative choice.
// class QueryNegative extends QueryResult {}
//
// /// On neutral choice.
// class QueryNeutral extends QueryResult {}
//
// /// On choice selection.
// class QueryChoice extends QueryResult {
//   final int which;
//
//   QueryChoice(this.which);
// }
//
// /// On multiple choice selection.
// class QueryMultipleChoice extends QueryResult {
//   final List<int> which;
//
//   QueryMultipleChoice(this.which);
// }
//
// /// On multiple choice selection.
// class QueryInput extends QueryResult {
//   final String input;
//
//   QueryInput(this.input);
// }

abstract mixin class _DialogHandling {
  final List<Window> _dialogStack = [];

  Window? _dialog;

  void closeWindow(Window window);

  void openWindow(Window window);

  Dialog openDialog() {
    final w = Window(
      'dialog',
      'dialog',
      position: RelativePosition.autoCentered(),
      flags: {WindowFlag.undecorated, WindowFlag.unmovable},
    );
    openWindow(w);

    final active = _dialog;
    if (active != null) _dialogStack.add(active);
    _dialog = w;

    return Dialog(w, () => _popDialog(w));
  }

  void query(String msg, void Function(QueryResult) onResult) {
    final dialog = _openQueryDialog(msg, onResult);
    if (dialog == null) return;
    openWindow(dialog);

    final active = _dialog;
    if (active != null) _dialogStack.add(active);
    _dialog = dialog;
  }

  Window? _openQueryDialog(String msg, void Function(QueryResult) onResult) {
    final rows = msg.split('\n');
    if (rows.isEmpty) return null;

    final width = rows.map((e) => e.length).reduce((a, b) => max(a, b)) + 6;
    final height = rows.length + 6;

    final buffer = Buffer(width, height);
    buffer.drawRows(3, 2, rows);
    buffer.drawBorder(0, 0, buffer.width, buffer.height);
    buffer.drawBuffer(3, rows.length + 3, "Ok[<Return>,o,y]   Cancel[<Esc>,q]");

    final window = Window("dialog", "Query",
        position: RelativePosition.autoCentered(),
        size: WindowSize.fixed(Size(width, height)),
        flags: {WindowFlag.undecorated},
        redraw: () => buffer.frame());

    window.onKey('<Return>', aliases: ['o', 'y'], description: 'Confirm dialog',
        action: () {
      onResult(QueryResult.positive);
      _popDialog(window);
    });

    window.onKey('<Escape>', aliases: ['q'], description: 'Cancel dialog',
        action: () {
      onResult(QueryResult.cancel);
      _popDialog(window);
    });

    return window;
  }

  void _popDialog(Window window) {
    closeWindow(window);
    if (_dialog != window) {
      logError('window not current dialog: $window <-> $_dialog');
      return;
    }
    if (_dialog == window) _dialog = null;
    if (_dialogStack.isNotEmpty) _dialog = _dialogStack.removeLast();
  }
}

class Dialog with AutoDispose, KeyHandling {
  final Window _window;

  Function _dismiss;

  OnRedraw redraw = () => "";

  Function(MouseEvent) onMouseEvent = (_) {};

  set onKeyEvent(KeyHandling it) => nested = it;

  void requestRedraw() => _window.requestRedraw();

  @override
  MatchResult match(KeyEvent it) => nested?.match(it) ?? MatchResult.empty;

  Dialog(this._window, this._dismiss) {
    _window.nested = this;
    _window.chainOnMouseEvent((e) => onMouseEvent(e));
    _window.redrawBuffer = () {
      final content = redraw();
      if (content == null) return null;
      final rows = content.split('\n');
      final width = rows.map((e) => e.ansiLength).fold(0, (w, r) => max(w, r));
      final height = rows.length;
      var resize = _window.size.current.width != width;
      resize |= _window.size.current.height != height;
      if (resize) {
        _window.size = WindowSize.fixed(Size(width, height));
      }

      return content;
    };
  }

  void dismiss() {
    disposeAll();
    _dismiss();
    _dismiss = () {};
  }
}
