import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Modèle pour un mot à réviser
class WordToReview {
  final String wordId;
  final String status; // 'À revoir' ou 'Maîtrisé'
  final DateTime? nextReviewDate;
  final int reviewCount;
  final DateTime lastReviewed;
  final String reviewFrequency; // Fréquence (legacy, ex: '1 jour')
  final int reviewDays; // Nombre de jours (source de vérité)

  WordToReview({
    required this.wordId,
    required this.status,
    this.nextReviewDate,
    required this.reviewCount,
    required this.lastReviewed,
    required this.reviewFrequency,
    required this.reviewDays,
  });

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'status': status,
      'nextReviewDate': nextReviewDate?.millisecondsSinceEpoch,
      'reviewCount': reviewCount,
      'lastReviewed': lastReviewed.millisecondsSinceEpoch,
      'reviewFrequency': reviewFrequency,
      'reviewDays': reviewDays,
    };
  }

  factory WordToReview.fromJson(Map<String, dynamic> json) {
    int _labelToDays(String label) {
      switch (label) {
        case '1 jour':
        case '1 day':
        case '1 দিন':
          return 1;
        case '3 jours':
        case '3 days':
        case '3 দিন':
          return 3;
        case '7 jours':
        case '7 days':
        case '7 দিন':
          return 7;
        case '14 jours':
        case '14 days':
        case '14 দিন':
          return 14;
        case '30 jours':
        case '30 days':
        case '30 দিন':
          return 30;
        default:
          return 7;
      }
    }
    return WordToReview(
      wordId: json['wordId'] as String,
      status: json['status'] as String,
      nextReviewDate: json['nextReviewDate'] != null 
        ? DateTime.fromMillisecondsSinceEpoch(json['nextReviewDate'] as int)
        : null,
      reviewCount: json['reviewCount'] as int? ?? 0,
      lastReviewed: DateTime.fromMillisecondsSinceEpoch(json['lastReviewed'] as int),
      reviewFrequency: json['reviewFrequency'] as String? ?? '7 jours',
      reviewDays: (json['reviewDays'] as int?) ?? _labelToDays((json['reviewFrequency'] as String?) ?? '7 jours'),
    );
  }
}

class SpacedRepetitionService {
  static const String _storageKey = 'spaced_repetition_data';
  
  // Fréquences de révision disponibles
  static const Map<String, int> _reviewFrequencies = {
    '1 jour': 1,
    '3 jours': 3,
    '7 jours': 7,
    '14 jours': 14,
    '30 jours': 30,
  };
  
  // Instance singleton
  static final SpacedRepetitionService _instance = SpacedRepetitionService._internal();
  factory SpacedRepetitionService() => _instance;
  SpacedRepetitionService._internal();

  int _parseDaysFromLabel(String label) {
    final match = RegExp(r"\d+").firstMatch(label);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 1;
    }
    return _reviewFrequencies[label] ?? 1;
  }

  // Normalise une date au début de journée (00:00:00) pour des comparaisons sur le jour calendaire
  DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);

  // Récupérer tous les mots à réviser
  Future<List<WordToReview>> getAllWordsToReview() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => WordToReview.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Récupérer les mots à réviser aujourd'hui
  Future<List<WordToReview>> getWordsToReviewToday() async {
    final allWords = await getAllWordsToReview();
    final today = DateTime.now();

    return allWords.where((word) {
      if (word.status == 'Maîtrisé') return false;
      if (word.nextReviewDate == null) return false;

      final reviewDate = DateTime(
        word.nextReviewDate!.year,
        word.nextReviewDate!.month,
        word.nextReviewDate!.day,
      );
      final todayDate = DateTime(today.year, today.month, today.day);

      return reviewDate.isAtSameMomentAs(todayDate);
    }).toList();
  }

  // Ajouter ou mettre à jour un mot à réviser
  Future<void> addWordToReview(String wordId, String frequencyLabel) async {
    final days = _parseDaysFromLabel(frequencyLabel);
    await addWordToReviewDays(wordId, days);
  }

  Future<void> addWordToReviewDays(String wordId, int daysToAdd) async {
    final allWords = await getAllWordsToReview();
    final today = DateTime.now();

    // Supprimer l'ancien mot s'il existe
    allWords.removeWhere((word) => word.wordId == wordId);

    // Calculer la prochaine date de révision
    final nextReviewDate = _atMidnight(today.add(Duration(days: daysToAdd)));

    // Créer le nouveau mot à réviser
    final newWord = WordToReview(
      wordId: wordId,
      status: 'À revoir',
      nextReviewDate: nextReviewDate,
      reviewCount: 0,
      lastReviewed: today,
      reviewFrequency: '$daysToAdd jours',
      reviewDays: daysToAdd,
    );

    allWords.add(newWord);
    await _saveWords(allWords);
  }

  // Marquer un mot comme maîtrisé
  Future<void> markWordAsMastered(String wordId) async {
    final allWords = await getAllWordsToReview();
    final wordIndex = allWords.indexWhere((word) => word.wordId == wordId);

    if (wordIndex != -1) {
      allWords[wordIndex] = WordToReview(
        wordId: wordId,
        status: 'Maîtrisé',
        nextReviewDate: null,
        reviewCount: allWords[wordIndex].reviewCount,
        lastReviewed: DateTime.now(),
        reviewFrequency: allWords[wordIndex].reviewFrequency,
        reviewDays: allWords[wordIndex].reviewDays,
      );
      await _saveWords(allWords);
    }
  }

  // Mettre à jour la fréquence de révision d'un mot
  Future<void> updateReviewFrequency(String wordId, String frequencyLabel) async {
    final days = _parseDaysFromLabel(frequencyLabel);
    await updateReviewFrequencyDays(wordId, days);
  }

  Future<void> updateReviewFrequencyDays(String wordId, int daysToAdd) async {
    final allWords = await getAllWordsToReview();
    final wordIndex = allWords.indexWhere((word) => word.wordId == wordId);

    if (wordIndex != -1) {
      final today = DateTime.now();
      final nextReviewDate = _atMidnight(today.add(Duration(days: daysToAdd)));

      allWords[wordIndex] = WordToReview(
        wordId: wordId,
        status: 'À revoir',
        nextReviewDate: nextReviewDate,
        reviewCount: allWords[wordIndex].reviewCount + 1,
        lastReviewed: today,
        reviewFrequency: '$daysToAdd jours',
        reviewDays: daysToAdd,
      );
      await _saveWords(allWords);
    }
  }

  // Nettoyer les mots non révisés depuis plus de 31 jours
  Future<void> cleanupOldWords() async {
    final allWords = await getAllWordsToReview();
    final today = DateTime.now();
    final thirtyOneDaysAgo = today.subtract(Duration(days: 31));

    allWords.removeWhere((word) {
      if (word.status == 'Maîtrisé') return false;
      return word.lastReviewed.isBefore(thirtyOneDaysAgo);
    });

    await _saveWords(allWords);
  }

  // Sauvegarder les mots
  Future<void> _saveWords(List<WordToReview> words) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = words.map((word) => word.toJson()).toList();
    final data = jsonEncode(jsonList);
    await prefs.setString(_storageKey, data);
  }

  // Récupérer les fréquences disponibles
  List<String> getAvailableFrequencies() {
    return _reviewFrequencies.keys.toList();
  }

  // Récupérer le nombre de jours pour une fréquence
  int getDaysForFrequency(String frequency) {
    return _reviewFrequencies[frequency] ?? 1;
  }

  /// Récupère tous les mots à réviser organisés par fréquence
  Future<Map<String, List<WordToReview>>> getWordsByReviewFrequency() async {
    final allWords = await getAllWordsToReview();
    final wordsToReview = allWords.where((word) => word.status == 'À revoir').toList();

    // Organiser par fréquence
    final Map<String, List<WordToReview>> wordsByFrequency = {};

    for (final word in wordsToReview) {
      final frequency = word.reviewFrequency ?? '7 jours';
      if (!wordsByFrequency.containsKey(frequency)) {
        wordsByFrequency[frequency] = [];
      }
      wordsByFrequency[frequency]!.add(word);
    }

    return wordsByFrequency;
  }

  /// Calcule le nombre de jours restants jusqu'à la prochaine révision
  int getDaysUntilReview(WordToReview word) {
    if (word.nextReviewDate == null) return 0;

    final now = DateTime.now();
    final reviewDate = word.nextReviewDate!;

    // Normaliser les dates pour ignorer l'heure
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedReview = DateTime(reviewDate.year, reviewDate.month, reviewDate.day);

    return normalizedReview.difference(normalizedNow).inDays;
  }

  /// Vérifie si un mot doit être révisé aujourd'hui
  bool isWordDueToday(WordToReview word) {
    return getDaysUntilReview(word) == 0;
  }

  /// Récupère les mots qui doivent être révisés aujourd'hui
  Future<List<WordToReview>> getWordsDueToday() async {
    final allWords = await getAllWordsToReview();
    return allWords.where((word) =>
      word.status == 'À revoir' && isWordDueToday(word)
    ).toList();
  }

  /// Récupère les mots qui doivent être révisés dans X jours
  Future<List<WordToReview>> getWordsDueInDays(int days) async {
    final allWords = await getAllWordsToReview();
    return allWords.where((word) =>
      word.status == 'À revoir' && getDaysUntilReview(word) == days
    ).toList();
  }

  /// Regroupe les mots 'À revoir' par date (normalisée à minuit, timezone locale)
  Future<Map<DateTime, List<String>>> getWordsGroupedByDay() async {
    final all = await getAllWordsToReview();
    final pending = all.where((w) => w.status == 'À revoir' && w.nextReviewDate != null);

    final Map<DateTime, List<String>> out = {};
    for (final w in pending) {
      final d = w.nextReviewDate!;
      final key = _atMidnight(d);
      out.putIfAbsent(key, () => <String>[]).add(w.wordId);
    }

    // Optionnel : préserver un ordre stable par wordId
    for (final entry in out.entries) {
      entry.value.sort();
    }
    return out;
  }

  /// Delete all words scheduled for review on a specific date
  Future<void> deleteWordsForDate(DateTime date) async {
    final allWords = await getAllWordsToReview();
    final targetDate = _atMidnight(date);
    
    // Remove words that have nextReviewDate matching the target date
    allWords.removeWhere((word) {
      if (word.nextReviewDate == null) return false;
      final wordDate = _atMidnight(word.nextReviewDate!);
      return wordDate.isAtSameMomentAs(targetDate);
    });
    
    await _saveWords(allWords);
  }
}
