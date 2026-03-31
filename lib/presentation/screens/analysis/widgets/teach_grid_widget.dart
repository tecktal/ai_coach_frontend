import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/analysis.dart';

class TeachGridWidget extends StatelessWidget {
  final Analysis analysis;
  final Function(String, ElementAnalysis?) onElementTap;

  const TeachGridWidget({
    super.key,
    required this.analysis,
    required this.onElementTap,
  });

  /// Logic to determine if a score of 1 is actually N/A
  /// based on the behaviors associated with the element.
  int _getEffectiveScore(ElementAnalysis? element) {
    if (element == null) return 0;
    
    // If score is 1 (Low), check if it's actually N/A
    // The backend might force N/A (0) to 1.
    if (element.score == 1) {
      // If we have no behaviors, or all behaviors are N/A, treat as N/A (0)
      if (element.behaviors.isEmpty) {
         // Strict N/A: If no behaviors are found, it is N/A (0).
         return 0; 
      }

      bool hasActualRating = false;
      for (var b in element.behaviors.values) {
        // If we find any High, Medium, or explicitly Low rating that isn't N/A
        if (b.rating.toUpperCase() != 'N/A' && b.rating != '0') {
          hasActualRating = true;
          break;
        }
      }
      
      // If no actual ratings found (all N/A), then the element score is effectively N/A (0)
      if (!hasActualRating) return 0;
    }
    
    return element.score;
  }



  // Calculate average score for a domain group
  double _calculateDomainAverage(List<Map<String, dynamic>> items) {
    double total = 0;
    int count = 0;
    for (var item in items) {
      int score = item['score'] ?? 0;
      if (score > 0) {
        total += score;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCollapsibleDomain(
          context,
          'Classroom Culture',
          [
            _createData('Supportive Learning Environment', analysis.supportiveEnvironment, Icons.spa, const Color(0xFF14B8A5), const Color(0xFFE8F5F3)),
            _createData('Positive Behavioral Expectations', analysis.positiveExpectations, Icons.psychology_alt, const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
          ],
        ),
        const SizedBox(height: 16),
        _buildCollapsibleDomain(
          context,
          'Instruction',
          [
            _createData('Lesson Facilitation', analysis.lessonFacilitation, Icons.record_voice_over, const Color(0xFF2196F3), const Color(0xFFE3F2FD)),
            _createData('Checks for Understanding', analysis.checksUnderstanding, Icons.quiz, const Color(0xFFFF9800), const Color(0xFFFFF3E0)),
            _createData('Feedback', analysis.feedback, Icons.feedback, const Color(0xFF9C27B0), const Color(0xFFF3E5F5)),
            _createData('Critical Thinking', analysis.criticalThinking, Icons.lightbulb, const Color(0xFFFFC107), const Color(0xFFFFFDE7)),
          ],
        ),
        const SizedBox(height: 16),
        _buildCollapsibleDomain(
          context,
          'Socioemotional Skills',
          [
            _createData('Autonomy', analysis.autonomy, Icons.accessibility_new, const Color(0xFFE91E63), const Color(0xFFFCE4EC)),
            _createData('Perseverance', analysis.perseverance, Icons.hiking, const Color(0xFF795548), const Color(0xFFEFEBE9)),
            _createData('Social & Collaborative Skills', analysis.socialCollaborative, Icons.groups, const Color(0xFF3F51B5), const Color(0xFFE8EAF6)),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _createData(String label, ElementAnalysis? element, IconData icon, Color color, Color bg) {
    final effectiveScore = _getEffectiveScore(element);
    return {
      'label': label,
      'element': element, // Pass the full object
      'score': effectiveScore,
      'icon': icon,
      'color': color,
      'bg': bg,
    };
  }

  Widget _buildCollapsibleDomain(BuildContext context, String title, List<Map<String, dynamic>> items) {
    final avgScore = _calculateDomainAverage(items);
    final hasScore = avgScore > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view ${items.length} elements',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Show average score in collapsed state
              if (hasScore)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.getScoreColorDouble(avgScore).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        avgScore.toStringAsFixed(1),
                        style: TextStyle(
                          color: AppTheme.getScoreColorDouble(avgScore),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '/5',
                        style: TextStyle(
                          color: AppTheme.getScoreColorDouble(avgScore),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'N/A',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            const SizedBox(height: 16),
            
            // Pros Section
            if (items.any((i) => (i['score'] as int) >= 3)) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text('PROS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 12)),
                  ],
                ),
              ),
              ...items.where((i) => (i['score'] as int) >= 3).map((item) => _buildTeachListTile(context, item)),
              const SizedBox(height: 16),
            ],

            // Cons Section
            if (items.any((i) => (i['score'] as int) < 3 && (i['score'] as int) > 0)) ...[
               Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text('CONS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 12)),
                  ],
                ),
              ),
              ...items.where((i) => (i['score'] as int) < 3 && (i['score'] as int) > 0).map((item) => _buildTeachListTile(context, item)),
            ],

            // N/A Section (Optional, maybe hide or show at bottom)
             if (items.any((i) => (i['score'] as int) == 0)) ...[
               const SizedBox(height: 16),
               Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, color: Colors.grey.shade400, size: 16),
                    const SizedBox(width: 8),
                    Text('NOT OBSERVED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              ...items.where((i) => (i['score'] as int) == 0).map((item) => _buildTeachListTile(context, item)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeachListTile(BuildContext context, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: item['bg'],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item['icon'], color: item['color'], size: 18),
        ),
        title: Text(
          item['label'],
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        onTap: () {
           if (item['element'] != null) {
             onElementTap(item['label'], item['element']);
           } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('No detailed analysis available for this category.')),
             );
           }
        },
      ),
    );
  }
}
