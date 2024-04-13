import 'dart:async';
import 'dart:io';

import 'package:dart_consul/dart_consul.dart';
import 'package:dart_minilog/dart_minilog.dart';

import 'src/demo_keys.dart';
import 'src/gol.dart';
import 'src/starfield.dart';

void main(List<String> args) async {
  final conIO = MadConIO();
  try {
    await createDesktop(conIO);
  } finally {
    conIO.close();
  }
  exit(0); // to force exit with timers etc running
}

Future createDesktop(ConIO conIO) async {
  final desktop = Desktop(conIO: conIO);

  notify(it) => desktop.sendMessage(it);

  // using an indirection here to make the menu entries below read nicer. but you could use lambdas
  // instead inside the entries. and you don't have to use notify/subscribe either. it's just a
  // built in simple mechanism that is available for such trivial setups.

  confirmQuit() => notify("quit");
  // showGameOfLife() => notify("show-gol");
  // showStarfield() => notify("show-starfield");
  // changeFps() => notify("change-fps");

  // TODO Remove setMenu and make Menu an undecorated Window instead. Handled like any other Window.
  // desktop.setMenu(//
  //     Menu("Menu" /*key: 'M' == default*/)
  //       ..add(Menu("File")..entry("Quit", confirmQuit))
  //       ..add(Menu("Window")
  //         ..entry("Game Of Life", showGameOfLife)
  //         ..entry("Starfield", showStarfield))
  //       ..add(Menu("Command")..entry("Change FPS", changeFps)) //
  //     );

  // Note the use of "exit" as message to end [Desktop.run].
  desktop.subscribe("quit", (_) => desktop.exit()); // TODO confirm dialog
  desktop.subscribe("show-gol", (_) => gameOfLife(desktop));
  desktop.subscribe("show-starfield", (_) => starfield(desktop));
  desktop.subscribe("change-fps", (_) => print("TODO"));

  // desktop.interceptSigInt = true;
  desktop.setDefaultKeys();
  desktop.onKey("q", description: "Quit", action: confirmQuit);

  gameOfLife(desktop);
  starfield(desktop);
  addDemoKeys(desktop);
  addAnsiDemo(desktop);

  final log = DebugLog(redraw: () => desktop.redraw());
  addDebugLog(
    desktop,
    log: log,
    key: "<C-w>l",
    position: RelativePosition.fromBottom(yOffset: -1),
  );

  addAutoHelp(
    desktop,
    key: "<C-?>",
    position: RelativePosition.fromBottomRight(),
  );

  // redirect log output into our [DebugLog]:
  sink = (e) => log.add(e);
  logLevel = LogLevel.verbose;

  logVerbose("verbose");
  logDebug("debug");
  logInfo("info");
  logWarn("warn");
  logError("error");

  return await desktop.run();
}

void addAnsiDemo(Desktop desktop) {
  desktop.openWindow(Window("ansi-demo", "ANSI Demo",
      size: WindowSize.fixed(Size(20, 10)),
      position: RelativePosition.autoCentered(),
      redraw: () =>
          "some red\n".red() +
          "some blue\n".bgBlue() +
          "some invers\n".inverse() +
          "some bold\n".bold() +
          "some italic\n".italic() +
          "some underline\n".underline() +
          "some dim\n".dim() +
          "some strike-through\n".strikeThrough()));
}
