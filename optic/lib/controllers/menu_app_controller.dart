import 'package:flutter/material.dart';

/// Controls the state of the sidebar menu and active screen index.
class MenuAppController extends ChangeNotifier {
  // Sidebar open/close state
  bool _isMenuOpen = true;

  // Current selected screen index
  int _selectedIndex = 0;

  bool get isMenuOpen => _isMenuOpen;
  int get selectedIndex => _selectedIndex;

  /// Toggle the sidebar open/close
  void toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
    notifyListeners();
  }

  /// Set the active screen index
  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }
}
