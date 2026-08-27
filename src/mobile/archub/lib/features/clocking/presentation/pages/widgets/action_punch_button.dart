import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:flutter/material.dart';

class ActionPunchButton extends StatelessWidget {
  final AttendanceType type;
  final String label;
  final IconData icon;
  final Color primaryColor;
  final bool isSelected;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onPressed;

  const ActionPunchButton({
    super.key,
    required this.type,
    required this.label,
    required this.icon,
    required this.primaryColor,
    this.isSelected = false,
    this.isEnabled = true,
    this.isLoading = false,
    this.onPressed,
  });

  factory ActionPunchButton.entrata({
    Key? key,
    bool isSelected = false,
    bool isEnabled = true,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return ActionPunchButton(
      key: key,
      type: AttendanceType.clockIn,
      label: 'Entrata',
      icon: Icons.login_rounded,
      primaryColor: const Color(0xFF10B981), // Emerald Green
      isSelected: isSelected,
      isEnabled: isEnabled,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  factory ActionPunchButton.pausa({
    Key? key,
    bool isOnBreak = false,
    bool isEnabled = true,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return ActionPunchButton(
      key: key,
      type: isOnBreak ? AttendanceType.breakEnd : AttendanceType.breakStart,
      label: isOnBreak ? 'Fine Pausa' : 'Pausa',
      icon: isOnBreak ? Icons.play_arrow_rounded : Icons.pause_rounded,
      primaryColor: const Color(0xFFF59E0B), // Amber
      isSelected: isOnBreak,
      isEnabled: isEnabled,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  factory ActionPunchButton.uscita({
    Key? key,
    bool isSelected = false,
    bool isEnabled = true,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    return ActionPunchButton(
      key: key,
      type: AttendanceType.clockOut,
      label: 'Uscita',
      icon: Icons.logout_rounded,
      primaryColor: const Color(0xFFEF4444), // Coral Red
      isSelected: isSelected,
      isEnabled: isEnabled,
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = isEnabled ? primaryColor : Colors.grey.shade400;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: 108,
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.15)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isEnabled
                    ? primaryColor.withValues(alpha: 0.35)
                    : Colors.grey.shade300),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isSelected ? 0.25 : 0.08),
                    blurRadius: isSelected ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isEnabled && !isLoading ? onPressed : null,
            splashColor: primaryColor.withValues(alpha: 0.2),
            highlightColor: primaryColor.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 26,
                        color: effectiveColor,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? (isSelected ? primaryColor : theme.textTheme.bodyLarge?.color)
                          : Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
