import 'package:consul/consul.dart';

void addDemoKeys(Desktop desktop) {
  final window = Window(
    "demo-keys",
    "Demo Keys",
    position: RelativePosition.fromTop(yOffset: 2),
    size: WindowSize.fixed(Size(40, 10)),
  );

  window.redrawBuffer = () => "Press <C-?> to show help screen.\n\n"
      "Focus this window, then:\n"
      "Press d or dd for a 'toast' demo.\n";

  window.flags.remove(WindowFlag.resizable);

  window.onKey(
    "d",
    description: "Demo single key toast",
    action: () => desktop.toast("Single key   press handled!"),
  );
  window.onKey(
    "dd",
    description: "Demo double key toast",
    action: () => desktop.toast("Double key press handled!"),
  );
  window.onKey(
    "<C-c>",
    description: "Demo <C-c> intercept",
    action: () => desktop.toast("<C-c> intercepted!"),
  );
  // window.onKey("n", action: () => desktop.notify("Desktop notification"));

  desktop.openWindow(window);
}
