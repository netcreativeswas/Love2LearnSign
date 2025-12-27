import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRepository extends ChangeNotifier {
  static const String _prefsKey = 'history';

  final ValueNotifier<List<String>> _historyNotifier;

  HistoryRepository._(List<String> initial)
      : _historyNotifier = ValueNotifier<List<String>>(List<String>.from(initial)) {
    _historyNotifier.addListener(_persist);
  }

  static Future<HistoryRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? <String>[];
    return HistoryRepository._(saved);
  }

  ValueNotifier<List<String>> get notifier => _historyNotifier;
  List<String> get value => _historyNotifier.value;

  bool contains(String id) => _historyNotifier.value.contains(id);

  void add(String id) {
    if (!contains(id)) {
      _historyNotifier.value = [..._historyNotifier.value, id];
      notifyListeners();
    }
  }

  void remove(String id) {
    if (contains(id)) {
      final next = List<String>.from(_historyNotifier.value)..remove(id);
      _historyNotifier.value = next;
      notifyListeners();
    }
  }

  void clear() {
    _historyNotifier.value = <String>[];
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _historyNotifier.value);
  }

  @override
  void dispose() {
    _historyNotifier.removeListener(_persist);
    _historyNotifier.dispose();
    super.dispose();
  }
}

