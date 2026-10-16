import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

const double _lbPerKg = 2.2046226218;
const double _kgStep = 0.1;

/// Current-weight tracker with +/- step buttons.
///
/// [currentWeight], [startingWeight], and the delta passed to [onAdjust] are
/// all in pounds, matching how weight is stored (`pregnancy_weight_entries.
/// weight_lb`) — this widget only converts to kilograms for display and for
/// sizing the +/- step so each tap moves the shown value by 0.1 kg.
class PregnancyWeightCard extends StatelessWidget {
  const PregnancyWeightCard({
    super.key,
    required this.currentWeight,
    required this.startingWeight,
    required this.onAdjust,
    required this.onSetWeight,
    this.enabled = true,
  });

  final double currentWeight;
  final double startingWeight;
  final ValueChanged<double> onAdjust;

  /// Called with an absolute weight in pounds, entered directly by the user
  /// (as an alternative to nudging with the +/- buttons).
  final Future<void> Function(double) onSetWeight;
  final bool enabled;

  Future<void> _openEditDialog(BuildContext context, double currentKg) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _WeightEditDialog(currentKg: currentKg, onSave: onSetWeight),
      );
  @override
  Widget build(BuildContext context) {
    final currentKg = currentWeight / _lbPerKg;
    final deltaKg = (currentWeight - startingWeight) / _lbPerKg;
    final lbStep = _kgStep * _lbPerKg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: enabled ? () => _openEditDialog(context, currentKg) : null,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your current weight',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${currentKg.toStringAsFixed(1)} kg',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${deltaKg >= 0 ? '+' : ''}${deltaKg.toStringAsFixed(1)} kg since week 0',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _WeightStepButton(
            icon: Icons.remove_rounded,
            onTap: enabled ? () => onAdjust(-lbStep) : null,
          ),
          const SizedBox(width: 8),
          _WeightStepButton(
            icon: Icons.add_rounded,
            onTap: enabled ? () => onAdjust(lbStep) : null,
          ),
        ],
      ),
    );
  }
}

class _WeightEditDialog extends StatefulWidget {
  const _WeightEditDialog({required this.currentKg, required this.onSave});

  final double currentKg;
  final Future<void> Function(double) onSave;

  @override
  State<_WeightEditDialog> createState() => _WeightEditDialogState();
}

class _WeightEditDialogState extends State<_WeightEditDialog> {
  late final _controller = TextEditingController(
    text: widget.currentKg.toStringAsFixed(1),
  );
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final kg = double.parse(_controller.text.trim().replaceAll(',', '.'));
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(kg * _lbPerKg);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save weight. Please try again.\n$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Set current weight'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _controller,
                autofocus: true,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current weight',
                  suffixText: 'kg',
                ),
                validator: (value) {
                  final kg = double.tryParse(
                    value?.trim().replaceAll(',', '.') ?? '',
                  );
                  if (kg == null || !kg.isFinite) {
                    return 'Enter a valid weight.';
                  }
                  if (kg < 27.2 || kg > 181.4) {
                    return 'Enter a weight from 27.2 to 181.4 kg.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    ),
  );
}

class _WeightStepButton extends StatelessWidget {
  const _WeightStepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFD3BBFE),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    ),
  );
}
