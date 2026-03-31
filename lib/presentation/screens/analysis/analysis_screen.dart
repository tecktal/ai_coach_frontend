import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/models/analysis.dart';
import '../../../data/models/recording.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/analysis_provider.dart';
import '../../../data/providers/recording_provider.dart';
import '../../../data/providers/auth_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../chat/chat_screen.dart';

// Widgets
import 'widgets/hero_score.dart';
import 'widgets/key_takeaways_widget.dart';
import 'widgets/teach_grid_widget.dart';
import 'widgets/sticky_action_card.dart';

class AnalysisScreen extends StatefulWidget {
  final String analysisId;

  const AnalysisScreen({super.key, required this.analysisId});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Analysis? _analysis;
  Recording? _recording;

  bool _isPlaying = false;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;

  // TTS State
  bool _isSpeaking = false;
  String? _currentlySpeakingSection;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _playbackDuration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _playbackPosition = p);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _loadAnalysis() async {
    final provider = context.read<AnalysisProvider>();
    await provider.loadAnalysis(widget.analysisId);
    
    final analysis = provider.currentAnalysis;
    Recording? recording;
    
    if (analysis != null) {
       if (!mounted) return;
       final recProvider = context.read<RecordingProvider>();
       recording = recProvider.getRecordingById(analysis.recordingId);
    }

    if (mounted) {
      setState(() {
        _analysis = analysis;
        _recording = recording;
        if (recording != null && recording.durationSeconds != null && recording.durationSeconds! > 0) {
          _playbackDuration = Duration(seconds: recording.durationSeconds!);
        }
      });
    }
  }

  Future<void> _speak(String? text, String sectionId) async {
    if (text == null || text.isEmpty) return;

    if (_isSpeaking && _currentlySpeakingSection == sectionId) {
      await _tts.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingSection = null;
        });
      }
      return;
    }

    if (_isSpeaking) {
      await _tts.stop();
    }

    if (mounted) {
      setState(() {
        _isSpeaking = true;
        _currentlySpeakingSection = sectionId;
      });
    }

    final cleanText = text
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('**', '')
        .replaceAll('_', '');

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingSection = null;
        });
      }
    });

    await _tts.speak(cleanText);
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _navigateToElementDetail(String name, ElementAnalysis? element) {
    if (element == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ElementDetailScreen(
          elementName: name,
          element: element,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_analysis == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Analysis'), backgroundColor: Colors.transparent),
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Lesson Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textMain
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: isDark ? Colors.white : AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalysis,
        color: Theme.of(context).primaryColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Score (Assuming Widget handles its own theme or we pass colors)
              HeroScore(
                score: _analysis!.overallScore ?? 0.0,
                date: DateFormat('MMMM d, yyyy').format(_analysis!.createdAt),
                title: _recording?.title ?? 'Untitled Lesson',
              ),
              const SizedBox(height: 32),
              
              // Audio Player
              _buildAudioPlayerCard(isDark),
              const SizedBox(height: 32),

              // 2. Key Takeaways
              _buildSectionTitle('KEY TAKEAWAYS', isDark),
              const SizedBox(height: 16),
              KeyTakeawaysWidget(
                strengths: _analysis!.strengths,
                growthAreas: _analysis!.areasForImprovement,
                onSpeak: _speak,
                isSpeaking: _isSpeaking,
                currentSection: _currentlySpeakingSection,
              ),
              const SizedBox(height: 32),

              // 2.5 Transcript Placeholder
              _buildSectionTitle('TRANSCRIPT', isDark),
              const SizedBox(height: 16),
              _buildTranscriptPlaceholder(isDark),
              const SizedBox(height: 32),

              // 3. TEACH Framework
              _buildSectionTitle('TEACH FRAMEWORK', isDark),
              const SizedBox(height: 16),
              TeachGridWidget(
                analysis: _analysis!,
                onElementTap: _navigateToElementDetail,
              ),
              const SizedBox(height: 32),

              // 4. Science of Learning
              if (_analysis!.scienceOfLearning != null) ...[
                _buildSectionTitle('SCIENCE OF LEARNING', isDark),
                const SizedBox(height: 16),
                _buildScienceOfLearning(isDark),
                const SizedBox(height: 32),
              ],
              
              // 5. Recommendations
              if (_analysis!.recommendations.isNotEmpty) ...[
                 StickyActionCard(
                   title: _analysis!.recommendations.first.title,
                   description: _analysis!.recommendations.first.description,
                   example: _analysis!.recommendations.first.example,
                 ),
                 const SizedBox(height: 32),
              ],
              
              const SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_analysis != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(analysisId: _analysis!.id),
              ),
            );
          }
        },
        icon: Icon(Icons.support_agent_rounded),
        label: const Text('Talk to Coach'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.grey[400] : AppTheme.textSub,
        ),
      ),
    );
  }

  Widget _buildTranscriptPlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.blue.shade900 : Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade500, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.blue.shade200 : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transcripts will be available in a future update.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.blue.shade100 : Colors.blue.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAudioPlayerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
        boxShadow: isDark ? [] : [
           BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              color: Theme.of(context).primaryColor,
              iconSize: 32,
              onPressed: () async {
                if (_isPlaying) {
                  await _audioPlayer.pause();
                  setState(() => _isPlaying = false);
                } else {
                  if (_recording != null) {
                    final authProvider = context.read<AuthProvider>();
                    await _audioPlayer.pause();
                    
                    Source audioSource;
                    if (_recording!.fileUrl.startsWith('http')) {
                      final token = await authProvider.getToken();
                      String finalUrl = _recording!.fileUrl;
                      if (token != null) {
                         final separator = finalUrl.contains('?') ? '&' : '?';
                         finalUrl = '$finalUrl${separator}token=$token';
                      }
                      audioSource = UrlSource(finalUrl);
                    } else {
                      audioSource = DeviceFileSource(_recording!.fileUrl);
                    }
                    await _audioPlayer.play(audioSource);
                    setState(() => _isPlaying = true);
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson Audio',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textMain
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 4,
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor: isDark ? Colors.grey[700] : Colors.grey.shade200,
                    thumbColor: Theme.of(context).primaryColor,
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _playbackPosition.inMilliseconds.toDouble(),
                    max: (_playbackDuration.inMilliseconds > 0 
                        ? _playbackDuration.inMilliseconds 
                        : (_recording?.durationSeconds ?? 0) * 1000).toDouble() > 0 
                        ? (_playbackDuration.inMilliseconds > 0 
                            ? _playbackDuration.inMilliseconds.toDouble() 
                            : (_recording?.durationSeconds ?? 1) * 1000.0) 
                        : 1.0,
                    onChanged: (v) => _audioPlayer.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_playbackPosition), style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey)),
                      if (_playbackDuration.inMilliseconds > 0 || (_recording?.durationSeconds ?? 0) > 0)
                        Text(
                          _playbackDuration.inMilliseconds > 0 
                            ? _formatDuration(_playbackDuration)
                            : _formatDuration(Duration(seconds: _recording!.durationSeconds!)),
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey)
                        )
                      else
                        Text('--:--', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScienceOfLearning(bool isDark) {
    final sol = _analysis!.scienceOfLearning!;
    return Column(
      children: [
        _buildScienceCard('Clarity & Cognitive Load', sol.clarityAndCognitiveLoad, isDark),
        const SizedBox(height: 12),
        _buildScienceCard('Engagement & Retrieval', sol.engagementAndRetrieval, isDark),
        const SizedBox(height: 12),
        _buildScienceCard('Feedback & Metacognition', sol.feedbackAndMetacognition, isDark),
      ],
    );
  }

  Widget _buildScienceCard(String title, dynamic area, bool isDark) {
    if (area == null) return const SizedBox.shrink();
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
        boxShadow: isDark ? [] : [
           BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
        ]
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: isDark ? Colors.grey[400] : Colors.grey[600],
          iconColor: isDark ? Colors.white : AppTheme.textMain,
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppTheme.textMain)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.psychology, color: Colors.blue.shade500, size: 20),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isSpeaking && _currentlySpeakingSection == 'science_$title'
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_outlined,
                  color: _isSpeaking && _currentlySpeakingSection == 'science_$title'
                      ? Theme.of(context).primaryColor
                      : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                  size: 20,
                ),
                onPressed: () {
                  final combinedText = '${area.pros}. ${area.cons}. ${area.feedback}';
                  _speak(combinedText, 'science_$title');
                },
              ),
              Icon(
                Icons.expand_more,
                color: isDark ? Colors.grey[400] : Colors.grey.shade600,
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
            const SizedBox(height: 16),
            _buildScienceRow('PROS', area.pros, Colors.green, isDark),
            const SizedBox(height: 16),
            _buildScienceRow('CONS', area.cons, Colors.orange, isDark),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, size: 16, color: Colors.blue.shade500),
                      const SizedBox(width: 8),
                      Text('COACH FEEDBACK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade500, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MarkdownBody(
                    data: area.feedback,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: isDark ? Colors.grey[300] : AppTheme.textMain),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScienceRow(String label, String content, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 3, backgroundColor: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: isDark ? Colors.grey[300] : AppTheme.textMain),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// DETAILED SCREEN FOR EVIDENCE
class ElementDetailScreen extends StatefulWidget {
  final String elementName;
  final ElementAnalysis element;

  const ElementDetailScreen({
    super.key,
    required this.elementName,
    required this.element,
  });

  @override
  State<ElementDetailScreen> createState() => _ElementDetailScreenState();
}

class _ElementDetailScreenState extends State<ElementDetailScreen> {
  final FlutterTts _tts = FlutterTts();
  String _selectedBehavior = 'All';
  
  bool _isSpeaking = false;
  String? _currentlySpeakingSection;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String? text, String sectionId) async {
    if (text == null || text.isEmpty) return;

    if (_isSpeaking && _currentlySpeakingSection == sectionId) {
      await _tts.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingSection = null;
        });
      }
      return;
    }

    if (_isSpeaking) {
      await _tts.stop();
    }

    if (mounted) {
      setState(() {
        _isSpeaking = true;
        _currentlySpeakingSection = sectionId;
      });
    }

    final cleanText = text
        .replaceAll('*', '')
        .replaceAll('#', '')
        .replaceAll('**', '')
        .replaceAll('_', '')
        .replaceAll('`', '');

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingSection = null;
        });
      }
    });

    await _tts.speak(cleanText);
  }

  int _getEffectiveScore(ElementAnalysis element) {
    if (element.score == 1) {
      if (element.behaviors.isEmpty) {
         return 0; 
      }
      bool hasActualRating = false;
      for (var b in element.behaviors.values) {
        if (b.rating.toUpperCase() != 'N/A' && b.rating != '0') {
          hasActualRating = true;
          break;
        }
      }
      if (!hasActualRating) return 0;
    }
    return element.score;
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = widget.element.behaviors.keys.toList()..sort();
    final effectiveScore = _getEffectiveScore(widget.element);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final displayedKeys = _selectedBehavior == 'All' 
        ? sortedKeys 
        : sortedKeys.where((k) => k == _selectedBehavior).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.elementName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppTheme.textMain)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score Hero
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
                ],
                border: isDark ? Border.all(color: Colors.grey[700]!) : null,
              ),
              child: Column(
                children: [
                  Text(
                    effectiveScore > 0 ? effectiveScore.toString() : 'N/A',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: effectiveScore > 0 ? AppTheme.getScoreColor(effectiveScore) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Rationale
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 12),
                          Text('Rationale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppTheme.textMain)),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isSpeaking && _currentlySpeakingSection == 'rationale'
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                          color: _isSpeaking && _currentlySpeakingSection == 'rationale'
                              ? Theme.of(context).primaryColor
                              : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                        ),
                        onPressed: () => _speak(widget.element.rationale, 'rationale'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MarkdownBody(
                    data: widget.element.rationale,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(color: isDark ? Colors.grey[300] : AppTheme.textMain),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Behavior Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildChip('All', isDark),
                   ...sortedKeys.map((key) => _buildChip(key, isDark)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Behaviors List
            if (displayedKeys.isEmpty)
              const Text('No behaviors found.', style: TextStyle(color: Colors.grey)),

            ...displayedKeys.map((key) {
              final behavior = widget.element.behaviors[key]!;
              final sectionId = 'behavior_$key';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade100),
                  boxShadow: isDark ? [] : [
                     BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRatingColor(behavior.rating).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            behavior.rating, 
                            style: TextStyle(
                              color: _getRatingColor(behavior.rating), 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            key.replaceAll('_', ' ').toUpperCase(), 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppTheme.textMain),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isSpeaking && _currentlySpeakingSection == sectionId
                                ? Icons.stop_circle_outlined
                                : Icons.volume_up_outlined,
                            color: _isSpeaking && _currentlySpeakingSection == sectionId
                                ? Theme.of(context).primaryColor
                                : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                            size: 20,
                          ),
                          onPressed: () {
                            String textToRead = "Rating: ${behavior.rating}. ";
                            if (behavior.instancesFound.isNotEmpty) {
                              textToRead += "Evidence found: ${behavior.instancesFound.join('. ')}";
                            } else {
                              textToRead += behavior.evidence;
                            }
                            _speak(textToRead, sectionId);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
                    const SizedBox(height: 16),
                    
                    // Evidence Timeline
                    if (behavior.instancesFound.isNotEmpty)
                      ...behavior.instancesFound.asMap().entries.map((entry) {
                        final isLast = entry.key == behavior.instancesFound.length - 1;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Column(
                               children: [
                                 Container(
                                   width: 12,
                                   height: 12,
                                   decoration: BoxDecoration(
                                     color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                     shape: BoxShape.circle,
                                     border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                                   ),
                                 ),
                                 if (!isLast)
                                   Container(
                                     width: 2,
                                     height: 40,
                                     color: isDark ? Colors.grey[700] : Colors.grey.shade200,
                                   ),
                               ],
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Padding(
                                 padding: const EdgeInsets.only(bottom: 16.0),
                                 child: Text(
                                   '"${entry.value}"', 
                                   style: TextStyle(
                                     fontStyle: FontStyle.italic, 
                                     color: isDark ? Colors.grey[300] : AppTheme.textMain,
                                     height: 1.4,
                                   ),
                                 ),
                               ),
                             ),
                          ],
                        );
                      })
                    else 
                      Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Icon(Icons.format_quote_rounded, color: Colors.grey, size: 20),
                           const SizedBox(width: 8),
                           Expanded(child: Text(behavior.evidence, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
                         ],
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isDark) {
    final isSelected = _selectedBehavior == label;
    final displayLabel = label == 'All' ? 'All' : label.replaceAll('_', ' ');
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(displayLabel),
        selected: isSelected,
        onSelected: (selected) {
           if (selected) setState(() => _selectedBehavior = label);
        },
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : AppTheme.textSub),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : (isDark ? Colors.grey[700]! : Colors.grey.shade200))),
      ),
    );
  }

  Color _getRatingColor(String rating) {
    final r = rating.toUpperCase();
    if (r.contains('H')) return AppTheme.successColor;
    if (r.contains('M')) return AppTheme.warningColor;
    if (r.contains('L')) return AppTheme.errorColor;
    return Colors.grey;
  }
}
