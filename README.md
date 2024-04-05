### Dart Consul - CLI "Desktop" System

There is no good reason why this exists. Another fun/joke project I picked up to learn me some more Dart. Did not mean
to take it as far as it has gotten. But will probably not take this any further... :-D ‾\_('')_/‾

Seriously, ignore this. Look at this instead: https://charm.sh/libs/ Not Dart. But makes much more sense.

#### Credits

Besides some obvious dart dependencies, these dependencies are used:

- https://pub.dev/packages/console for the `DrawingCanvas` using the Braille unicode character block
- https://pub.dev/packages/dart_console2 for raw terminal access via some native code
- https://pub.dev/packages/rxdart for "throttleTime", so I don't have to implement this ^^
- https://pub.dev/packages/ansi for the ansi styling

This fun project would not exist without these dependencies!

#### What is this?

A very basic, limited, rudimentary, and weird "desktop windowing" system for the console/terminal. Currently tested
only on my one linux machine. Will most probably not work on Windows or macOS. Feel free to test and report back.

And it is written in Dart. Because I'm currently learning Dart to get into Flutter (and Flutter Flame) at some
point. I think. We'll see.

#### Sorry, what?

No, I'm sorry... ‾\_('')_/‾

#### So... Does it work?

Well, it works on my machine... :-D

You can try the included `example/desk.dart` and see for yourself.

The basic idea is:

```
final desktop = Desktop(...);
desktop.onKey('k', () => doSomething());

final window = Window(
  "some-id",
  "Some Title",
  size: WindowSize.defaultMinMax(Size(60, 40)),
  position: RelativePosition.fromTopLeft(xOffset: 4, yOffset: 2),
  redraw: () => "Hello, world!",
);
desktop.openWindow(window);
```

It does support a "braille" characters based "canvas". This way you can do something like the `example/desk.dart`:

![Screenshot](images/consul-example.gif)

Note that this functionality comes from https://pub.dev/packages/console.

#### To Do

The essentials I want to be done for a "Version 1":

- [ ] Taskbar showing all (including minimized) windows
- [ ] Taskbar overflow with all remaining windows

Maybes:

- [ ] Blink(?) active (move or resize) window title (or indicate somehow else for small windows especially)
- [ ] Menubar system
- [ ] Basic dialog system
- [ ] Improve handling of terminal resize

#### Done

- [X] Draw windows
- [X] Window title bar with controls
- [X] Console input handling (keys only for now)
- [X] Tab switching
- [X] Console mouse input handling
- [X] Minimize/maximize/close windows via key
- [X] Nested key handling
- [X] Move windows via key
- [X] Resize window via keys
- [X] Window hooks (state & size for now)
- [X] Basic mouse actions (raise, minimize, maximize, close)
- [X] Resize window with mouse
- [X] Move window with mouse
- [X] Help (?) button to show key configuration

#### Bugs

- [X] *MAJOR* Titlebar controls do not respect window flags.
- [ ] *MAJOR* Moving window fast, then moving another window, moves the first one again.
- [ ] *MAJOR* Focus does not skip minimized windows properly.
- [X] *CRITICAL* One off bug for resize control. Applies only for some `Position` type it seems?
- [X] Move overlay shown when window is too small.
- [X] Drawing a buffer into a buffer breaks ansi in the replaced area.
  Potential fix: collect ansi sequences being replaced and add to `Cell.after` of the last cell.
  Related: should `Cell.reset` happen before `Cell.after`? seems to make more sense now.
- [X] Related to the previous one: ansi sequences leak into the drawn parts.
- [X] Moving window out left side breaks ansi.
  Potential fix: collect all ansi sequences cut off and combine into one.
  Placing this one into the first visible cell.
