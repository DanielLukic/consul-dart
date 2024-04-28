## Dart Consul - CLI "Desktop" System

There is no good reason why this exists. Another fun/joke project I picked up to learn me some more Dart. Did not mean
to take it as far as it has gotten. But will probably not take this any further... 🙃 🤷 ☯

Seriously, ignore this. Look at this instead: https://charm.sh/libs/ Not Dart. But makes much more sense.

### What is this?

A very basic, limited, rudimentary, and weird "desktop windowing" system for the console/terminal. Currently tested
only on my one linux machine. Will most probably not work on Windows or macOS. Feel free to test and report back.

And it is written in Dart. Because I'm currently learning Dart to get into Flutter (and Flutter Flame) at some
point. I think. We'll see.

### Sorry, what?

No, I'm sorry... 🤷

### Example Screenshot

Screenshot of the `example.dart` running:

![Screenshot](https://github.com/DanielLukic/consul-dart/raw/main/images/example.gif)

### Credits

Besides some obvious dart dependencies, these dependencies are used:

- https://pub.dev/packages/termlib for the terminal interaction
- https://pub.dev/packages/console for the `DrawingCanvas` using the Braille unicode character block
- https://pub.dev/packages/dart_console for raw terminal access via some native code
- https://pub.dev/packages/rxdart for "throttleTime", so I don't have to implement this ^^
- https://pub.dev/packages/ansi for the ansi styling

This fun project would not exist without these dependencies!

### So... Does it work?

Well, it works on my machine... 🙃

You can try the included `example.dart` and see for yourself.

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

It does support a "braille" characters based "canvas". This way you can do something like the `example.dart`.

Note that this canvas functionality comes from https://pub.dev/packages/console.

Example animated gif:

![Screenshot](https://github.com/DanielLukic/consul-dart/raw/main/images/consul-example.gif)

### To Do

The essentials I want to be done for a "Version 1":

- Basic dialog system
- Basic popup system

Some other things on my mind:

- *MAYBE* Taskbar showing all (including minimized) windows
- *MAYBE* Taskbar overflow with all remaining windows
- *MAYBE* Blink(?) active (move or resize) window title (or indicate somehow else for small windows especially)
- *MAYBE* Menubar system
- *MAYBE* Improve handling of terminal resize
- *MAYBE* Use the table/border functionality of the included dependencies
- *MAYBE* Make scroll view, border view, etc first class concepts to use "transparently" inside windows

### Done

- Draw windows
- Window title bar with controls
- Console input handling (keys only for now)
- Tab switching
- Console mouse input handling
- Minimize/maximize/close windows via key
- Nested key handling
- Move windows via key
- Resize window via keys
- Window hooks (state & size for now)
- Basic mouse actions (raise, minimize, maximize, close)
- Resize window with mouse
- Move window with mouse
- Help (?) button to show key configuration
- Add basic (vertical only) scrolled content

### Bugs

- *MAJOR* Moving window fast, then moving another window, moves the first one again.
- *MAJOR* Focus does not skip minimized windows properly.

### Fixed Bugs

- *CRITICAL* One off bug for resize control. Applies only for some `Position` type it seems?
- *MAJOR* Titlebar controls do not respect window flags.
- Move overlay shown when window is too small.
- Drawing a buffer into a buffer breaks ansi in the replaced area.
  Potential fix: collect ansi sequences being replaced and add to `Cell.after` of the last cell.
  Related: should `Cell.reset` happen before `Cell.after`? seems to make more sense now.
- Related to the previous one: ansi sequences leak into the drawn parts.
- Moving window out left side breaks ansi.
  Potential fix: collect all ansi sequences cut off and combine into one.
  Placing this one into the first visible cell.
