### Dart Consul - CLI "Desktop" System

There is no good reason why this exists. Another fun/joke project I picked up to learn me some more Dart. Did not mean
to take it as far as it has gotten. But will probably not take this any further... :-D ‾\_('')_/‾

Seriously, ignore this. Look at this instead: https://charm.sh/libs/

#### What is this?

A very basic, limited, rudimentary, and weird "desktop windowing" system for the console/terminal. Currently tested 
only on my one linux machine. Will most probably not work on Windows or macOS. Feel free to test and report back.

And it is written in Dart. Because I'm currently learning to Dart to get into Flutter and Flutter Flame at some 
point. I think. We'll see.

#### Sorry, what?

No, I'm sorry... ‾\_('')_/‾

#### So... Does it work?

Well, it works on my machine... :-D

You can try the included `example/desk.dart` and see for yourself.

The basic idea is:
```
final desktop = Desktop(...);
desktop.onKey('q', () => exit(0));

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

However, there is far too much to do to call this useful in any way...

#### To Do

2. Tab Switching
3. Key Event Hierarchy
4. Min/Max/Close/Move via Keys
5. Taskbar
6. Menu
7. Global [?] vs Local _ Hotkeys
7. Mouse...

* Dialog
* Menu Bar
* Window Life Cycle
* Key Event Hierarchy
* Mouse Events
* Mouse Event Hierarchy
* Window Move
* Taskbar
* Window Raise Lower Minimize Maximize (?)

#### Bugs

- [X] moving window out left side breaks ansi.
  potential fix: collect all ansi sequences cut off and combine into one.
  placing this one into the first visible cell.
