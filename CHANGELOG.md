## 0.0.16

- Add `ListWindow` (from krok term project)
- Make toast more visible
- Make auto-help jump to section for focused window
- Fix one-off bug in `ScrolledContent`

## 0.0.15

- Switch to `termlib`
- Remove `Control.enter` in favor or just `Control.return`
- Add `ColorCanvas` from `dart-krok-term` project
- Add simple game skeleton/demo

## 0.0.14

- Auto-raise window when using `MouseGestures`
- Fix handling of multiple/fast mouse events
- Provide <C-j> as is instead of mapped to <Enter>
- Switch dialog elements via (S-)Tab
- Improve DUI key handling
- Add `DuiSwitcher` component
- Introduce poor man's reactive `DuiState`

## 0.0.13

- Introduced `MouseGestures` to simply mouse event handling
- Add basic query dialog system
- Add basic DUI layout and components
- Add basic dialog handling system
- Add basic desktop notifications system
- Add border styles
- Add `WindowFlag.alwaysOnTop`
- Add `Desktop.dimWhenOverlapped` option

## 0.0.12

- Fix partial matching with nested key maps
- Fix mouse handling for undecorated (and tiny) windows
- Autofill new buffers with space
- Make debug log more versatile and reusable

## 0.0.11

- Fix partial matching with nested key maps

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
