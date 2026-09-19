/// User-facing haptic strength preference.
///
/// Applied on top of the tuning profile and per-call intensity, so an app can
/// let people pick how hard feedback feels (or turn it off) without touching
/// its own call sites.
enum AiroHapticStrength {
  /// No haptic output.
  off('Off', 'No vibration feedback', 0),

  /// Light, subtle taps.
  soft('Soft', 'Light, subtle taps', 0.5),

  /// Neutral: the intensities the engine and profiles define, unchanged.
  medium('Medium', 'Balanced feedback', 1),

  /// Boosted taps that are easy to feel; the result is still clamped to 1.0.
  strong('Strong', 'Firm, easy-to-feel taps', 1.4);

  const AiroHapticStrength(this.label, this.description, this.scale);

  /// Short human-readable name for settings UI.
  final String label;

  /// One-line explanation for settings UI.
  final String description;

  /// Multiplier applied to the effective intensity.
  final double scale;

  /// Whether this level produces any output.
  bool get isOn => this != AiroHapticStrength.off;

  /// Parses a persisted [name], falling back to [medium] for unknown values.
  static AiroHapticStrength fromName(String? name) => values.firstWhere(
        (s) => s.name == name,
        orElse: () => AiroHapticStrength.medium,
      );
}

/// Persistence hook so apps can remember the user's strength choice.
abstract class AiroHapticStrengthStore {
  /// Returns the stored [AiroHapticStrength.name], or null when nothing is stored.
  Future<String?> read();

  /// Stores the [AiroHapticStrength.name].
  Future<void> write(String name);
}
