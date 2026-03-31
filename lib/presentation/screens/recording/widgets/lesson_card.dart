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

  const LessonCard({
    super.key,
    required this.recording,
    required this.onTap,
    this.onLongPress,
    this.onDelete,
    this.score,
  });

  Color _getStatusColor(BuildContext context) {
    if (recording.isProcessing) return AppTheme.warningColor;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
        boxShadow: isDark ? [] : [
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
                // Icon Box
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getStatusColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getSubjectIcon(),
                    color: _getStatusColor(context),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: CircleAvatar(
                              radius: 2, 
                              backgroundColor: isDark ? Colors.grey[600] : Colors.grey.shade300
                            ),
                          ),
                          Text(
                            DateFormat('MMM d').format(recording.createdAt), 
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : AppTheme.textSub,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status / Action
                if (recording.isProcessing || recording.isPending)
                  Container(
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
                           child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.warningColor)
                         ),
                         SizedBox(width: 6),
                         Text(
                           'Analyzing',
                           style: TextStyle(
                             color: AppTheme.warningColor,
                             fontSize: 10,
                             fontWeight: FontWeight.bold
                           ),
                         ),
                      ],
                    ),
                  )
                else if (score != null && score! > 0)
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                     decoration: BoxDecoration(
                       color: AppTheme.getScoreColor(score!.toInt()).withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            score!.toStringAsFixed(1),
                            style: TextStyle(
                              color: AppTheme.getScoreColor(score!.toInt()),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star_rounded, size: 14, color: AppTheme.getScoreColor(score!.toInt())),
                        ],
                     ),
                   )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded, 
                    size: 16, 
                    color: isDark ? Colors.grey[600] : Colors.grey.shade300
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
