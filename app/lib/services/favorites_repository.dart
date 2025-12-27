import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository extends ChangeNotifier {
  static const String _prefsKey = 'favorites';

  final ValueNotifier<List<String>> _favoritesNotifier;

  FavoritesRepository._(List<String> initial)
      : _favoritesNotifier = ValueNotifier<List<String>>(List<String>.from(initial)) {
    _favoritesNotifier.addListener(_persist);
  }

  static Future<FavoritesRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? <String>[];
    return FavoritesRepository._(saved);
  }

  ValueNotifier<List<String>> get notifier => _favoritesNotifier;
  List<String> get value => _favoritesNotifier.value;

  bool contains(String id) => _favoritesNotifier.value.contains(id);

  void add(String id) {
    if (!contains(id)) {
      _favoritesNotifier.value = [..._favoritesNotifier.value, id];
      notifyListeners();
    }
  }

  void remove(String id) {
    if (contains(id)) {
      final next = List<String>.from(_favoritesNotifier.value)..remove(id);
      _favoritesNotifier.value = next;
      notifyListeners();
    }
  }

  void toggle(String id) => contains(id) ? remove(id) : add(id);

  void clear() {
    _favoritesNotifier.value = <String>[];
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _favoritesNotifier.value);
  }

  @override
  void dispose() {
    _favoritesNotifier.removeListener(_persist);
    _favoritesNotifier.dispose();
    super.dispose();
  }
}

