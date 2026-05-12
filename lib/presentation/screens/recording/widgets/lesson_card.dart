import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/recording.dart';
import 'package:intl/intl.dart';

class LessonCard extends StatelessWidget {
  final Recording recording;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final double? score;
  /// True while this local draft is actively being uploaded to the server.
  final bool isUploading;

  const LessonCard({
    super.key,
    required this.recording,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.score,
    this.isUploading = false,
  });

  Color _getStatusColor(BuildContext context) {
    if (recording.isLocalDraft) return const Color(0xFF64748B); // slate
    if (recording.isProcessing || recording.isPending) return AppTheme.warningColor;
    if (recording.isFailed) return AppTheme.errorColor;
    return _getSubjectColor(context);
  }
  
  Color _getSubjectColor(BuildContext context) {
    final s = recording.subject?.toLowerCase() ?? '';
    if (s.contains('math')) return const Color(0xFF2563EB); // Blue-600
    if (s.contains('science')) return const Color(0xFF059669); // Emerald-600
    if (s.contains('english') || s.contains('reading')) return const Color(0xFF9333EA); // Purple-600
    if (s.contains('history')) return const Color(0xFFD97706); // Amber-600
    if (s.contains('art')) return const Color(0xFFDB2777); // Pink-600
    return Theme.of(context).primaryColor;
  }

  IconData _getSubjectIcon() {
    if (recording.isLocalDraft) return Icons.cloud_upload_outlined;
    final s = recording.subject?.toLowerCase() ?? '';
    if (s.contains('math')) return Icons.functions_rounded;
    if (s.contains('science')) return Icons.science_rounded;
    if (s.contains('english') || s.contains('reading')) return Icons.menu_book_rounded;
    if (s.contains('history')) return Icons.history_edu_rounded;
    if (s.contains('art')) return Icons.palette_rounded;
    return Icons.school_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recording.isLocalDraft
              ? (isDark ? const Color(0xFF334155) : Colors.grey.shade200)
              : (isDark ? Colors.transparent : Colors.grey.shade100),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Icon box ──────────────────────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getSubjectIcon(),
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Draft label
                      if (recording.isLocalDraft)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Local Draft',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      Text(
                        recording.title ?? 'Untitled Lesson',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.textMain,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              recording.subject ?? 'General',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? Colors.grey[400] : AppTheme.textSub,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            child: CircleAvatar(
                                radius: 2,
                                backgroundColor: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey.shade300),
                          ),
                          Text(
                            DateFormat('MMM d').format(recording.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      isDark ? Colors.grey[400] : AppTheme.textSub,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ── Status badge / trailing ───────────────────────────────
                _buildTrailing(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, bool isDark) {
    // Local draft actively uploading — show immediately when upload starts
    if (recording.isLocalDraft && isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Uploading…',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    // Local draft — not yet uploaded
    if (recording.isLocalDraft) {
      return _badge(
        context,
        icon: Icons.cloud_upload_outlined,
        label: 'Not uploaded',
        color: const Color(0xFF64748B),
      );
    }

    // Actively analyzing
    if (recording.isProcessing || recording.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.warningColor),
            ),
            SizedBox(width: 6),
            Text(
              'Analyzing',
              style: TextStyle(
                color: AppTheme.warningColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Analysis complete — show qualitative label only (no number)
    if (score != null && score! > 0) {
      final label = score! >= 4.0
          ? 'Excellent'
          : score! >= 3.0
              ? 'Good'
              : score! >= 2.0
                  ? 'Developing'
                  : 'Needs Focus';
      final color = AppTheme.getScoreColor(score!.toInt());
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Uploaded but no analysis yet (e.g. waiting in queue or completed with
    // no analysis found)
    if (recording.isCompleted || recording.isPending) {
      return _badge(
        context,
        icon: Icons.hourglass_top_rounded,
        label: 'Not analyzed',
        color: isDark ? Colors.grey[500]! : Colors.grey.shade400,
      );
    }

    // Default arrow
    return Icon(
      Icons.arrow_forward_ios_rounded,
      size: 16,
      color: isDark ? Colors.grey[600] : Colors.grey.shade300,
    );
  }

  Widget _badge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
