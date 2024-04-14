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
      _popDialog();
    });

    window.onKey('<Escape>', aliases: ['q'], description: 'Cancel dialog',
        action: () {
      onResult(QueryResult.cancel);
      _popDialog();
    });

    return window;
  }

  void _popDialog() {
    final d = _dialog;
    if (d == null) return;
    closeWindow(d);
    _dialog = null;
    if (_dialogStack.isNotEmpty) _dialog = _dialogStack.removeLast();
  }
}
