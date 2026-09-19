import 'package:airo_haptics/airo_haptics.dart';
import 'package:airo_haptics/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAiroHapticPlatform fakePlatform;

  setUp(() async {
    fakePlatform = FakeAiroHapticPlatform();
    AiroHapticsPlatform.instance = fakePlatform;
    await AiroHaptics.updateSettings(const AiroHapticSettings());
    AiroHaptics.theme = AiroHapticTheme.standard();
    AiroHaptics.profile = AiroHapticProfile.defaultProfile;
    fakePlatform.clearInvocations();
  });

  group('AiroHaptics Facade & Engine', () {
    test('semantic shortcuts invoke platform performFeedback and assertion helper matches', () async {
      await AiroHaptics.success();
      await AiroHaptics.warning();
      await AiroHaptics.error();

      expectHapticPlayed(fakePlatform, AiroHapticFeedbackType.success);
      expectHapticPlayed(fakePlatform, AiroHapticFeedbackType.warning);
      expectHapticPlayed(fakePlatform, AiroHapticFeedbackType.error);
    });

    test('impact shortcuts invoke platform performImpact with correct intensity', () async {
      await AiroHaptics.lightImpact();
      await AiroHaptics.heavyImpact();

      expect(fakePlatform.invocations.length, 2);
      expect(fakePlatform.invocations[0].impact, AiroHapticImpact.light);
      expect(fakePlatform.invocations[1].impact, AiroHapticImpact.heavy);
      expect(fakePlatform.invocations[1].intensity, 1.0);
    });

    test('controllable player lifecycle and live parameter updates', () async {
      final player = await AiroHaptics.createPlayer(AiroHapticPattern.doubleClick());
      await player.start();
      expect(player.isPlaying, isTrue);

      await player.update(intensity: 0.8, sharpness: 0.3);
      expect(player.currentIntensity, 0.8);
      expect(player.currentSharpness, 0.3);

      final updateInvocations = fakePlatform.invocations.where((i) => i.method == 'updatePattern');
      expect(updateInvocations.isNotEmpty, isTrue);

      player.stop();
      expect(player.isPlaying, isFalse);
    });

    test('isolated session lifecycle management', () async {
      final session = await AiroHaptics.startSession(id: 'test_session');
      expect(session.isActive, isTrue);

      final player = await session.play(AiroHapticPattern.doubleClick());
      expect(player, isNotNull);
      expect(session.activePlayer, isNotNull);

      await session.stop();
      expect(session.activePlayer, isNull);

      session.dispose();
      expect(session.isActive, isFalse);
    });

    test('ADSR envelope continuous haptics playback', () async {
      const envelope = AiroHapticEnvelope(
        attack: Duration(milliseconds: 20),
        decay: Duration(milliseconds: 50),
        sustain: 0.7,
        release: Duration(milliseconds: 100),
      );

      final player = await AiroHaptics.playContinuous(
        intensity: 0.6,
        sharpness: 0.4,
        envelope: envelope,
      );

      expect(player.isPlaying, isTrue);
      player.stop();
    });

    test('AHAP design format map parsing', () {
      final ahapJson = {
        'Pattern': [
          {
            'Event': {
              'EventType': 'HapticTransient',
              'Time': 0.05,
              'EventParameters': [
                {'ParameterID': 'HapticIntensity', 'ParameterValue': 0.7},
                {'ParameterID': 'HapticSharpness', 'ParameterValue': 0.8}
              ]
            }
          },
          {
            'Event': {
              'EventType': 'HapticContinuous',
              'Time': 0.2,
              'EventDuration': 0.4,
              'EventParameters': [
                {'ParameterID': 'HapticIntensity', 'ParameterValue': 0.5}
              ]
            }
          }
        ]
      };

      final pattern = AiroHapticPattern.fromAhap(ahapJson, id: 'parsed_ahap');
      expect(pattern.id, 'parsed_ahap');
      expect(pattern.events.length, 2);
      expect(pattern.events[0].type, AiroHapticEventType.transient);
      expect(pattern.events[0].intensity, 0.7);
      expect(pattern.events[1].type, AiroHapticEventType.continuous);
      expect(pattern.events[1].duration.inMilliseconds, 400);
    });

    test('profile selector updates global scaling and throttle windows', () {
      AiroHaptics.profile = AiroHapticProfile.tv;
      expect(AiroHaptics.profile, AiroHapticProfile.tv);
      expect(AiroHaptics.settings.globalScale, 0.8);
      expect(AiroHaptics.settings.minThrottleDuration, const Duration(milliseconds: 40));
    });

    test('expectNoHapticPlayed passes when no events fired', () {
      expectNoHapticPlayed(fakePlatform);
    });

    test('stopAll triggers platform stopAll', () async {
      await AiroHaptics.stopAll();
      expect(fakePlatform.isStopped, isTrue);
    });
  });

  group('AiroHapticStrength', () {
    setUp(() => AiroHaptics.strength = AiroHapticStrength.medium);

    test('off suppresses semantic, impact and pattern output', () async {
      AiroHaptics.strength = AiroHapticStrength.off;
      await AiroHaptics.confirm();
      await AiroHaptics.heavy();
      await AiroHaptics.playPattern(AiroHapticPattern.doubleClick());
      expectNoHapticPlayed(fakePlatform);
    });

    test('semantic feedback carries the scaled intensity to the platform', () async {
      Future<double?> sent(AiroHapticStrength strength) async {
        fakePlatform.clearInvocations();
        AiroHaptics.strength = strength;
        await AiroHaptics.updateSettings(
          AiroHaptics.settings.copyWith(minThrottleDuration: Duration.zero),
        );
        await AiroHaptics.confirm();
        return fakePlatform.invocations.last.options?.intensity;
      }

      final soft = await sent(AiroHapticStrength.soft);
      final medium = await sent(AiroHapticStrength.medium);
      final strong = await sent(AiroHapticStrength.strong);
      expect(soft, lessThan(medium!));
      expect(strong, greaterThanOrEqualTo(medium));
      expect(strong, lessThanOrEqualTo(1.0));
    });

    test('profile changes do not reset the chosen strength', () {
      AiroHaptics.strength = AiroHapticStrength.strong;
      AiroHaptics.profile = AiroHapticProfile.media;
      expect(AiroHaptics.strength, AiroHapticStrength.strong);
      expect(AiroHaptics.settings.globalScale, AiroHapticProfile.media.intensityScale);
    });

    test('fromName falls back to medium and settings round-trip json', () {
      expect(AiroHapticStrength.fromName('nope'), AiroHapticStrength.medium);
      expect(AiroHapticStrength.fromName(null), AiroHapticStrength.medium);
      const settings = AiroHapticSettings(strength: AiroHapticStrength.soft);
      expect(AiroHapticSettings.fromJson(settings.toJson()).strength, AiroHapticStrength.soft);
    });

    test('store restores the saved strength and persists changes', () async {
      final store = _MemoryStore('strong');
      await AiroHaptics.useStrengthStore(store);
      expect(AiroHaptics.strength, AiroHapticStrength.strong);
      await AiroHaptics.setStrength(AiroHapticStrength.soft);
      expect(store.value, 'soft');
    });
  });

  group('AiroHapticStrengthPicker', () {
    testWidgets('lists every level and reports the selection', (tester) async {
      AiroHapticStrength? picked;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AiroHapticStrengthPicker(
            value: AiroHapticStrength.medium,
            onChanged: (s) => picked = s,
          ),
        ),
      ));
      for (final s in AiroHapticStrength.values) {
        expect(find.byKey(ValueKey('haptic-strength-${s.name}')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('haptic-strength-off')));
      await tester.pump();
      expect(picked, AiroHapticStrength.off);
    });
  });
}

class _MemoryStore implements AiroHapticStrengthStore {
  _MemoryStore(this.value);
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String name) async => value = name;
}
