import 'package:flutter_test/flutter_test.dart';
import 'package:pe_prm393_de190630/data/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('session save/read/clear writes only user ID and timestamp', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final now = DateTime(2026, 10, 28, 12);
    final storage = SessionStorage(preferences: preferences, now: () => now);
    await storage.save(2);
    final restored = await storage.read();
    expect(restored?.userId, 2);
    expect(restored?.createdAt, now);
    expect(preferences.getKeys(), {'session_user_id', 'session_created_at_ms'});
    await storage.clear();
    expect(await storage.read(), isNull);
    expect(preferences.getKeys(), isEmpty);
  });

  for (final partial in <Map<String, Object>>[
    {'session_user_id': 1},
    {'session_created_at_ms': 1000},
  ]) {
    test('partial session ${partial.keys.single} is cleared', () async {
      SharedPreferences.setMockInitialValues(partial);
      final preferences = await SharedPreferences.getInstance();
      expect(await SessionStorage(preferences: preferences).read(), isNull);
      expect(preferences.getKeys(), isEmpty);
    });
  }
}
