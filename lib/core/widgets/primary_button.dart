import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// The app's primary action button.
///
/// [filled] = true  → gradient background (e.g. "Get Started")
/// [filled] = false → outlined, translucent (e.g. "I Already Have an Account")
///
/// Includes a subtle scale-down on press, matching the mockup's `active:scale-95`.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.trailingIcon,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final IconData? trailingIcon;
  final bool loading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.nunitoSans(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: widget.filled ? Colors.white : AppColors.secondary,
    );

    return GestureDetector(
      onTapDown: widget.loading ? null : (_) => _setPressed(true),
      onTapUp: widget.loading ? null : (_) => _setPressed(false),
      onTapCancel: widget.loading ? null : () => _setPressed(false),
      onTap: widget.loading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.filled ? AppColors.buttonGradient : null,
            color: widget.filled ? null : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: widget.filled
                ? null
                : Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
            boxShadow: widget.filled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: widget.loading
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: widget.filled ? Colors.white : AppColors.secondary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.label, style: textStyle),
                    if (widget.trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.trailingIcon, color: Colors.white, size: 22),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
