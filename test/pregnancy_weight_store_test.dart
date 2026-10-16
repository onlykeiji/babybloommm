import 'dart:convert';

import 'package:babybloom2/core/supabase_config.dart';
import 'package:babybloom2/features/home/presentation/pregnancy_weight_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  Map<String, dynamic>? savedRow;
  const userId = '11111111-1111-4111-8111-111111111111';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final mock = MockClient((request) async {
      if (request.url.path == '/auth/v1/token') {
        return http.Response(
          jsonEncode({
            'access_token': 'test-access-token',
            'refresh_token': 'test-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': userId,
              'aud': 'authenticated',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-09-07T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      requests.add(request);
      if (request.method == 'POST') {
        savedRow = {
          'id': 'saved-weight-id',
          ...jsonDecode(request.body) as Map<String, dynamic>,
        };
        return http.Response(
          jsonEncode(savedRow),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }
      return http.Response(
        jsonEncode([?savedRow]),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    await Supabase.initialize(
      url: 'https://weight-test.example',
      publishableKey: 'test-key',
      httpClient: mock,
    );
    await SupabaseConfig.client.auth.signInWithPassword(
      email: 'test@example.com',
      password: 'test-password',
    );
  });

  tearDownAll(() => Supabase.instance.dispose());

  test(
    'minimum kg saves as pounds; same-day update and reload use returned row',
    () async {
      await PregnancyWeightStore.saveToday(27.2 * 2.2046226218);
      expect(savedRow!['weight_lb'], 60.0);
      expect(savedRow!['user_id'], userId);
      expect(requests.single.method, 'POST');
      expect(
        requests.single.url.queryParameters['on_conflict'],
        'user_id,recorded_on',
      );
      expect(
        requests.single.headers['prefer'],
        contains('resolution=merge-duplicates'),
      );

      await PregnancyWeightStore.saveToday(65.5 * 2.2046226218);
      expect(PregnancyWeightStore.entries.value, hasLength(1));
      expect(PregnancyWeightStore.entries.value.single.weightLb, 144.4);
      PregnancyWeightStore.entries.value = [];
      await PregnancyWeightStore.fetch();
      expect(PregnancyWeightStore.entries.value.single.weightLb, 144.4);
      expect(requests.last.url.queryParameters['user_id'], 'eq.$userId');
    },
  );

  test('invalid weights never reach the database', () async {
    final before = requests.length;
    for (final invalid in [double.nan, double.infinity, 0.0, 401.0]) {
      await expectLater(
        PregnancyWeightStore.saveToday(invalid),
        throwsArgumentError,
      );
    }
    expect(requests.length, before);
  });
}
