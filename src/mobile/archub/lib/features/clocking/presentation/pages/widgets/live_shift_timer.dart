import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:flutter/material.dart';

class LiveShiftTimer extends StatelessWidget {
  final Duration duration;
  final AttendanceEntity? lastPunch;
  final bool isWorking;
  final bool isOnBreak;

  const LiveShiftTimer({
    super.key,
    required this.duration,
    required this.lastPunch,
    required this.isWorking,
    required this.isOnBreak,
  });

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (isOnBreak) {
      statusColor = const Color(0xFFF59E0B);
      statusTitle = 'IN PAUSA';
      statusIcon = Icons.pause_circle_filled_rounded;
    } else if (isWorking) {
      statusColor = const Color(0xFF10B981);
      statusTitle = 'IN TURNO';
      statusIcon = Icons.timelapse_rounded;
    } else {
      statusColor = Colors.grey.shade500;
      statusTitle = 'NON IN SERVIZIO';
      statusIcon = Icons.stop_circle_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWorking || isOnBreak
              ? statusColor.withValues(alpha: 0.3)
              : theme.dividerColor.withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isWorking || isOnBreak)
                ? statusColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Digital Timer display
          Text(
            _formatDuration(duration),
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              letterSpacing: 2.0,
              color: isWorking ? theme.textTheme.headlineLarge?.color : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),

          // Last punch note or time
          if (lastPunch != null)
            Text(
              'Ultima marcatura: ${lastPunch!.type.label} alle ${_formatTime(lastPunch!.timestamp)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              'Nessuna marcatura registrata oggi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
