import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/territorial_models.dart';

class StorageService {
  static const _occurrencesKey = 'geofluxo_occurrences_v1';
  static const _decisionsKey = 'geofluxo_decisions_v1';
  static const _highContrastKey = 'geofluxo_high_contrast_v1';
  static const _textScaleKey = 'geofluxo_text_scale_v1';
  static const _anonymizeKey = 'geofluxo_anonymize_v1';

  Future<List<FieldOccurrence>> loadOccurrences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_occurrencesKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => FieldOccurrence.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveOccurrences(List<FieldOccurrence> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_occurrencesKey, encoded);
  }

  Future<List<HumanDecisionRecord>> loadDecisions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_decisionsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => HumanDecisionRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveDecisions(List<HumanDecisionRecord> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_decisionsKey, encoded);
  }

  Future<({bool highContrast, double textScale, bool anonymizeCitizenData})>
      loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      highContrast: prefs.getBool(_highContrastKey) ?? false,
      textScale: prefs.getDouble(_textScaleKey) ?? 1.0,
      anonymizeCitizenData: prefs.getBool(_anonymizeKey) ?? true,
    );
  }

  Future<void> savePreferences({
    required bool highContrast,
    required double textScale,
    required bool anonymizeCitizenData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_highContrastKey, highContrast);
    await prefs.setDouble(_textScaleKey, textScale);
    await prefs.setBool(_anonymizeKey, anonymizeCitizenData);
  }
}
