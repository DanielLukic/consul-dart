part of 'desktop.dart';

class Menu {
  String _title;

  String? _key;

  Menu(this._title, {String? key}) : _key = key;

  add(Menu subMenu) {}

  entry(String name, Function() callback) {}
}
