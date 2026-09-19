## 1.2.0

- Added `AiroHapticStrength` (`off`, `soft`, `medium`, `strong`) as a user-facing preference, exposed via `AiroHaptics.strength`, `AiroHapticSettings.strength` and the resolver.
- Added `AiroHaptics.setStrength` with `AiroHapticStrengthStore` (`useStrengthStore`) so apps can persist the choice.
- Added `AiroHapticStrengthPicker`, a drop-in settings widget with tap preview.
- Fixed: semantic feedback (`confirm`, `navigation`, ...) now sends the resolved intensity to native; it was previously dropped.
- Fixed: changing `AiroHaptics.profile` no longer discards the user strength.
- Android: semantic feedback uses amplitude-controlled one-shots where the motor supports them, and stronger predefined effects otherwise (previously faint `EFFECT_TICK`).
- iOS: semantic selection/impact feedback honours the resolved intensity.

## 1.1.0

- Added dynamic live parameter tuning via `player.update(intensity: ..., sharpness: ...)` and `AiroHaptics.createPlayer()`.
- Added first-class `AiroHapticSession` for session lifecycle, queueing, and cancellation.
- Added Attack-Decay-Sustain-Release (`AiroHapticEnvelope`) continuous envelope player (`AiroHaptics.playContinuous()`).
- Added Apple AHAP design format parser (`AiroHapticPattern.fromAhap()`).
- Added `AiroHapticProfile` tuning profiles (`default`, `minimal`, `gaming`, `accessibility`, `tv`, `media`, `assistant`).
- Added testing assertion matchers (`expectHapticPlayed`, `expectNoHapticPlayed`, `expectHapticPatternPlayed`).
- Upgraded interactive Haptic Lab in `example/` with ADSR envelope sliders, AHAP sample player, and profile switcher.

## 1.0.0

- Initial release of `airo_haptics` cross-platform Flutter haptics engine.
- Semantic feedback (20 standard feedback types).
- Physical impact shortcuts (light, medium, heavy, soft, rigid) & variable sharpness.
- Custom pattern engine & preset waves (`doubleClick`, `successWave`, `errorAlert`, `heartbeat`, `rampUp`).
- Capability detection (`AiroHapticCapabilities`).
- Throttling, coalescing, themes, diagnostics, and testing fakes.
