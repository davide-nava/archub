import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/attendance_type.dart';
import '../bloc/clocking_bloc.dart';
import '../bloc/clocking_event.dart';
import '../bloc/clocking_state.dart';
import 'widgets/action_punch_button.dart';
import 'widgets/gps_badge.dart';
import 'widgets/live_shift_timer.dart';
import 'widgets/pending_sync_badge.dart';
import 'widgets/recent_punches_list.dart';

class PunchScreen extends StatelessWidget {
  const PunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Presenze & Timbrature',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Sincronizza marcature',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<ClockingBloc>().add(const ClockingSyncRequested());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Ricarica',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<ClockingBloc>().add(const ClockingStarted());
            },
          ),
        ],
      ),
      body: BlocConsumer<ClockingBloc, ClockingState>(
        listener: (context, state) {
          if (state.status == ClockingStatus.synced) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Marcatura registrata e sincronizzata online!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (state.status == ClockingStatus.offlineCached) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Offline: Marcatura salvata in locale (SQLite). Verrà inviata appena online.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFF59E0B),
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          } else if (state.status == ClockingStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isPunching = state.isPunching;
          final isWorking = state.isWorking;
          final isOnBreak = state.isOnBreak;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ClockingBloc>().add(const ClockingStarted());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending sync banner if any offline punches exist
                  PendingSyncBadge(
                    pendingCount: state.pendingCount,
                    isSyncing: state.isSyncing,
                    onSyncPressed: () {
                      HapticFeedback.selectionClick();
                      context.read<ClockingBloc>().add(const ClockingSyncRequested());
                    },
                  ),

                  // Live shift timer
                  LiveShiftTimer(
                    duration: state.activeDuration,
                    lastPunch: state.lastPunch,
                    isWorking: isWorking,
                    isOnBreak: isOnBreak,
                  ),

                  const SizedBox(height: 16),

                  // GPS Coordinates & accuracy badge
                  GpsBadge(
                    location: state.currentLocation,
                    isLoading: state.isLocationLoading,
                    error: state.locationError,
                    onRefresh: () {
                      HapticFeedback.selectionClick();
                      context
                          .read<ClockingBloc>()
                          .add(const ClockingLocationRefreshRequested());
                    },
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  Text(
                    'TIMBRATURA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Large Action Buttons Row (Entrata, Pausa, Uscita)
                  Row(
                    children: [
                      ActionPunchButton.entrata(
                        isSelected: isWorking && !isOnBreak,
                        isEnabled: !isWorking || isOnBreak,
                        isLoading: isPunching && state.lastPunch?.type != AttendanceType.clockIn,
                        onPressed: () => _handlePunch(context, AttendanceType.clockIn),
                      ),
                      const SizedBox(width: 10),
                      ActionPunchButton.pausa(
                        isOnBreak: isOnBreak,
                        isEnabled: isWorking || isOnBreak,
                        isLoading: isPunching &&
                            (state.lastPunch?.type == AttendanceType.breakStart ||
                                state.lastPunch?.type == AttendanceType.breakEnd),
                        onPressed: () {
                          final nextType = isOnBreak
                              ? AttendanceType.breakEnd
                              : AttendanceType.breakStart;
                          _handlePunch(context, nextType);
                        },
                      ),
                      const SizedBox(width: 10),
                      ActionPunchButton.uscita(
                        isSelected: false,
                        isEnabled: isWorking || isOnBreak,
                        isLoading: isPunching && state.lastPunch?.type == AttendanceType.clockOut,
                        onPressed: () => _handlePunch(context, AttendanceType.clockOut),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // History header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CRONOLOGIA RECENTE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _showAddNoteDialog(context);
                        },
                        icon: const Icon(Icons.note_add_outlined, size: 16),
                        label: const Text(
                          'Aggiungi nota',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent punches list
                  RecentPunchesList(punches: state.recentPunches),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handlePunch(BuildContext context, AttendanceType type) {
    HapticFeedback.mediumImpact();
    context.read<ClockingBloc>().add(ClockingPunchSubmitted(type: type));
  }

  void _showAddNoteDialog(BuildContext context) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nota Marcatura'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Inserisci una nota o giustificativo per la marcatura...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                final note = noteController.text.trim();
                Navigator.of(dialogContext).pop();
                if (note.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nota registrata per la prossima timbratura: "$note"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );
  }
}
