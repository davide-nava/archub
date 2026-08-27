import 'package:archub/core/services/location_service.dart';
import 'package:flutter/material.dart';

class GpsBadge extends StatelessWidget {
  final LocationData? location;
  final bool isLoading;
  final String? error;
  final VoidCallback onRefresh;

  const GpsBadge({
    super.key,
    required this.location,
    required this.isLoading,
    required this.onRefresh,
    this.error,
  });

  Color _getAccuracyColor(double accuracy) {
    if (accuracy <= 15) return const Color(0xFF10B981); // High accuracy
    if (accuracy <= 50) return const Color(0xFFF59E0B); // Medium accuracy
    return const Color(0xFFEF4444); // Low accuracy
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = location != null;
    final hasError = error != null && !hasData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? Colors.red.shade300
              : theme.dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: hasError
                  ? Colors.red.withValues(alpha: 0.12)
                  : hasData
                      ? _getAccuracyColor(location!.accuracy).withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasError
                  ? Icons.location_off_rounded
                  : Icons.location_on_rounded,
              size: 18,
              color: hasError
                  ? Colors.red
                  : hasData
                      ? _getAccuracyColor(location!.accuracy)
                      : Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Posizione GPS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _getAccuracyColor(location!.accuracy).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '± ${location!.accuracy.toStringAsFixed(1)}m',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _getAccuracyColor(location!.accuracy),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (isLoading)
                  Text(
                    'Acquisizione coordinate GPS...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else if (hasError)
                  Text(
                    error!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (hasData)
                  Text(
                    '${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  )
                else
                  Text(
                    'Nessuna posizione rilevata',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: isLoading ? null : onRefresh,
            iconSize: 20,
            splashRadius: 18,
            tooltip: 'Aggiorna GPS',
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
