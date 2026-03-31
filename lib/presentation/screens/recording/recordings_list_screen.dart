import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/recording_provider.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../../data/models/analysis.dart';
import '../../../data/models/recording.dart';
import '../analysis/analysis_screen.dart';
import '../analysis/analysis_error_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import 'widgets/lesson_card.dart';

enum SortOption {
  alphabeticalAZ,
  alphabeticalZA,
  dateNewest,
  dateOldest,
}

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> with WidgetsBindingObserver {
  SortOption _currentSort = SortOption.dateNewest;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Wire up the polling callback ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RecordingProvider>();
      provider.onStatusChanged = _onRecordingStatusChanged;
      provider.startPollingIfNeeded();
      provider.loadRecordings(silent: true);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        final provider = context.read<RecordingProvider>();
        provider.loadRecordings(silent: true);
        context.read<AnalysisProvider>().loadAnalyses();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Remove our callback so it doesn't fire after we're gone
    final provider = context.read<RecordingProvider>();
    if (provider.onStatusChanged == _onRecordingStatusChanged) {
      provider.onStatusChanged = null;
    }
    super.dispose();
  }

  void _onRecordingStatusChanged(Recording recording, String previousStatus) {
    if (!mounted) return;

    if (recording.isCompleted) {
      // Refresh analyses so the score shows up
      context.read<AnalysisProvider>().loadAnalyses();
      AppToast.show(
        context,
        message: '✅ "${recording.title ?? 'Lesson'}" analysis is ready!',
        type: ToastType.success,
        duration: const Duration(seconds: 5),
      );
    } else if (recording.isFailed || recording.isInsufficientAudio) {
      AppToast.show(
        context,
        message: '❌ Analysis failed for "${recording.title ?? 'Lesson'}". Tap to see details.',
        type: ToastType.error,
        duration: const Duration(seconds: 6),
      );
    }
  }

  List<Recording> _sortRecordings(List<Recording> recordings) {
    // 1. Filter by Search
    var filtered = recordings.where((r) {
      final title = r.title?.toLowerCase() ?? '';
      final subject = r.subject?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || subject.contains(query);
    }).toList();

    // 2. Filter by Category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((r) =>
        (r.subject?.toLowerCase() ?? '').contains(_selectedCategory.toLowerCase())
      ).toList();
    }

    // 3. Sort
    filtered.sort((a, b) {
      switch (_currentSort) {
        case SortOption.alphabeticalAZ:
          return (a.title ?? '').compareTo(b.title ?? '');
        case SortOption.alphabeticalZA:
          return (b.title ?? '').compareTo(a.title ?? '');
        case SortOption.dateNewest:
          return b.createdAt.compareTo(a.createdAt);
        case SortOption.dateOldest:
          return a.createdAt.compareTo(b.createdAt);
      }
    });

    return filtered;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 16),
                child: Text(
                  'Sort By',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSortOption('Alphabetical (A-Z)', Icons.sort_by_alpha, SortOption.alphabeticalAZ),
              _buildSortOption('Alphabetical (Z-A)', Icons.sort_by_alpha, SortOption.alphabeticalZA),
              _buildSortOption('Date (Newest First)', Icons.calendar_today, SortOption.dateNewest),
              _buildSortOption('Date (Oldest First)', Icons.calendar_today, SortOption.dateOldest),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, IconData icon, SortOption option) {
    final isSelected = _currentSort == option;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.grey[400] : Colors.grey),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.white : AppTheme.textMain),
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
      onTap: () {
        setState(() => _currentSort = option);
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordingProvider = context.watch<RecordingProvider>();
    final analysisProvider = context.watch<AnalysisProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortedRecordings = _sortRecordings(recordingProvider.recordings);

    final Map<String, Analysis> analysisMap = {
      for (var a in analysisProvider.analyses) a.recordingId: a
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'My Lessons',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textMain,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Show a subtle pulsing dot when polling is active
          if (recordingProvider.hasProcessingRecordings)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Analysis in progress…',
                child: _PollingDot(),
              ),
            ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Search & Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade200),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.textMain),
                      decoration: InputDecoration(
                        hintText: 'Search lessons...',
                        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: isDark ? Colors.grey[500] : Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filters Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category Filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isDense: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            icon: Icon(Icons.keyboard_arrow_down, size: 18, color: Theme.of(context).primaryColor),
                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                            items: ['All', 'Math', 'Science', 'English', 'History', 'Art'].map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCategory = val);
                            },
                          ),
                        ),
                      ),
                      // Sort Button
                      TextButton.icon(
                        onPressed: _showSortOptions,
                        icon: Icon(Icons.sort_rounded, size: 18),
                        label: const Text('Sort'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lessons List
            Expanded(
              child: recordingProvider.isLoading
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                  : sortedRecordings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic_none_rounded, size: 80, color: isDark ? Colors.grey[700] : Colors.grey.shade200),
                              const SizedBox(height: 16),
                              Text(
                                'No lessons found',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: isDark ? Colors.grey[500] : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: Theme.of(context).primaryColor,
                          onRefresh: () async {
                            await Future.wait([
                              context.read<RecordingProvider>().loadRecordings(),
                              context.read<AnalysisProvider>().loadAnalyses(),
                            ]);
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: sortedRecordings.length,
                            itemBuilder: (context, index) {
                              final recording = sortedRecordings[index];
                              final analysis = analysisMap[recording.id];

                              return LessonCard(
                                recording: recording,
                                score: analysis?.overallScore,
                                onTap: () => _navigateToAnalysis(context, recording, analysis),
                                onLongPress: () => _deleteRecording(context, recordingProvider, recording.id),
                                onDelete: () => _deleteRecording(context, recordingProvider, recording.id),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAnalysis(
    BuildContext context,
    Recording recording,
    Analysis? analysis,
  ) async {
    if (analysis != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AnalysisScreen(analysisId: analysis.id)),
      );
      return;
    }

    if (recording.isCompleted) {
      AppToast.show(context, message: 'Fetching analysis details…', type: ToastType.info);

      final provider = context.read<AnalysisProvider>();
      await provider.loadAnalyses();

      if (!context.mounted) return;

      final updatedAnalysis = provider.analyses
          .where((a) => a.recordingId == recording.id)
          .firstOrNull;

      if (updatedAnalysis != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AnalysisScreen(analysisId: updatedAnalysis.id)),
        );
        return;
      }
    }

    if (recording.isFailed || recording.isInsufficientAudio) {
      final localPath = context.read<RecordingProvider>().getLocalFilePath(recording.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnalysisErrorScreen(
            recording: recording,
            localFilePath: localPath,
          ),
        ),
      );
      return;
    }

    if (recording.isProcessing || recording.isPending) {
      AppToast.show(
        context,
        message: 'This lesson is still being analyzed. Please wait.',
        type: ToastType.info,
      );
    } else {
      AppToast.show(
        context,
        message: 'No analysis found. Try pulling down to refresh.',
        type: ToastType.info,
      );
    }
  }

  Future<void> _deleteRecording(BuildContext context, RecordingProvider provider, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text('This will permanently delete the recording and its analysis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteRecording(id);
      if (context.mounted) {
        AppToast.show(context, message: 'Recording deleted.', type: ToastType.info);
      }
    }
  }
}

// ── Animated polling indicator dot ───────────────────────────────────────
class _PollingDot extends StatefulWidget {
  @override
  State<_PollingDot> createState() => _PollingDotState();
}

class _PollingDotState extends State<_PollingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.warningColor.withValues(alpha: 0.4 + _ctrl.value * 0.6),
        ),
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    var iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
