import 'package:archub/features/clocking/domain/entities/attendance_entity.dart';
import 'package:archub/features/clocking/domain/entities/attendance_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentPunchesList extends StatelessWidget {
  final List<AttendanceEntity> punches;

  const RecentPunchesList({
    super.key,
    required this.punches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (punches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'Nessuna marcatura recente',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final timeFormatter = DateFormat('HH:mm');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: punches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final punch = punches[index];
        final isSynced = punch.syncStatus.isSynced;

        Color typeColor = const Color(0xFF10B981);
        IconData typeIcon = Icons.login_rounded;

        switch (punch.type) {
          case AttendanceType.clockIn:
            typeColor = const Color(0xFF10B981);
            typeIcon = Icons.login_rounded;
            break;
          case AttendanceType.clockOut:
            typeColor = const Color(0xFFEF4444);
            typeIcon = Icons.logout_rounded;
            break;
          case AttendanceType.breakStart:
          case AttendanceType.breakEnd:
            typeColor = const Color(0xFFF59E0B);
            typeIcon = Icons.pause_rounded;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          punch.type.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sync Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSynced
                                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSynced ? Icons.check_circle_rounded : Icons.cloud_off_rounded,
                                size: 11,
                                color: isSynced
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                isSynced ? 'Sincronizzato' : 'Offline',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isSynced
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${dateFormatter.format(punch.timestamp.toLocal())} • ${timeFormatter.format(punch.timestamp.toLocal())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                          ),
                        ),
                        if (punch.hasLocation) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'GPS OK',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
