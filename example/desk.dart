import 'dart:async';
import 'dart:io';

import 'package:consul/consul.dart';
import 'package:consul/src/auto_help.dart';
import 'package:consul/src/consul/con_io/mad_con_io.dart';
import 'package:consul/src/debug_log.dart';

import 'demo_keys.dart';
import 'gol.dart';
import 'starfield.dart';

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
  showGameOfLife() => notify("show-gol");
  showStarfield() => notify("show-starfield");
  changeFps() => notify("change-fps");

  // TODO Remove setMenu and make Menu an undecorated Window instead. Handled like any other Window.
  desktop.setMenu(//
      Menu("Menu" /*key: 'M' == default*/)
        ..add(Menu("File")..entry("Quit", confirmQuit))
        ..add(Menu("Window")
          ..entry("Game Of Life", showGameOfLife)
          ..entry("Starfield", showStarfield))
        ..add(Menu("Command")..entry("Change FPS", changeFps)) //
      );

  // Note the use of "exit" as message to end [Desktop.run].
  desktop.subscribe("quit", (_) => desktop.exit()); // TODO confirm dialog
  desktop.subscribe("show-gol", (_) => gameOfLife(desktop));
  desktop.subscribe("show-starfield", (_) => starfield(desktop));
  desktop.subscribe("change-fps", (_) => print("TODO"));

  // desktop.interceptSigInt = true;
  desktop.setDefaultKeys();
  desktop.onKey("q", description: "Quit", action: confirmQuit);

  addDemoKeys(desktop);
  gameOfLife(desktop);
  starfield(desktop);

  addDebugLog(
    desktop,
    key: "<C-w>l",
    position: RelativePosition.fromBottom(yOffset: -1),
  );

  addAutoHelp(
    desktop,
    key: "<C-?>",
    position: RelativePosition.fromBottomRight(),
  );

  return await desktop.run();
}
