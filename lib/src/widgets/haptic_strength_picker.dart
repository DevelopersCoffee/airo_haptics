import 'package:flutter/material.dart';

import '../airo_haptics_facade.dart';
import '../models/haptic_strength.dart';

/// Drop-in settings control for choosing [AiroHapticStrength].
///
/// Purely presentational: the app owns the value and decides how to persist it
/// (or use [AiroHaptics.useStrengthStore]). When [previewOnChange] is true a
/// sample tap plays at the newly chosen strength.
class AiroHapticStrengthPicker extends StatelessWidget {
  const AiroHapticStrengthPicker({
    required this.value,
    required this.onChanged,
    super.key,
    this.previewOnChange = true,
  });

  final AiroHapticStrength value;
  final ValueChanged<AiroHapticStrength> onChanged;
  final bool previewOnChange;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<AiroHapticStrength>(
      groupValue: value,
      onChanged: (strength) {
        if (strength == null) return;
        onChanged(strength);
        if (previewOnChange) {
          AiroHaptics.strength = strength;
          AiroHaptics.confirm();
        }
      },
      child: Column(
        children: [
          for (final strength in AiroHapticStrength.values)
            RadioListTile<AiroHapticStrength>(
              key: ValueKey('haptic-strength-${strength.name}'),
              value: strength,
              title: Text(strength.label),
              subtitle: Text(strength.description),
            ),
        ],
      ),
    );
  }
}
