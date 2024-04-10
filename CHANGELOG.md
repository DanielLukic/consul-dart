## 0.0.10

- Allow ANSI in desktop background
- Simplify `BaseOngoingMouseAction` (for krok term)

## 0.0.9

- Fix mouse events dispatch to visible windows only
- Fix `AutoDispose` to dispose once only
- Use minilog package
- Make log window configurable
- Expose `dart_consul/common.dart` with extensions and ansi helpers
- Map <C-h> to <Backspace>
- Update to `dart_console 4.0.1`
- Add key input stealing for input fields etc

## 0.0.8

- Fix desktop refresh when moving/resizing
- Add ScrolledContent component (vertical-only for now)

## 0.0.7

- Fix missing minimize button when window not resizable

## 0.0.6

- Minor clean up and pub.dev fixes

## 0.0.5 / 0.0.4 / 0.0.3

- Try showing animation on pub.dev

## 0.0.2

- Fix example name

## 0.0.1

Basic functionality implemented:

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
