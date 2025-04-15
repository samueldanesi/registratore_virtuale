import 'package:shared_preferences/shared_preferences.dart';

class AliquoteManager {
  static const String _key = 'aliquoteIVA';

  static Future<List<double>> getAliquote() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key);
    if (list == null) return [0, 4, 10, 22];
    return list.map((e) => double.tryParse(e) ?? 0).toList();
  }

  static Future<void> addAliquota(double val) async {
    final prefs = await SharedPreferences.getInstance();
    final aliquote = await getAliquote();
    if (!aliquote.contains(val)) {
      aliquote.add(val);
      aliquote.sort();
      await prefs.setStringList(_key, aliquote.map((e) => e.toString()).toList());
    }
  }

  static Future<void> removeAliquota(double val) async {
    final prefs = await SharedPreferences.getInstance();
    final aliquote = await getAliquote();
    aliquote.remove(val);
    await prefs.setStringList(_key, aliquote.map((e) => e.toString()).toList());
  }
}