import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../data/models/recording.dart';
import '../../../data/providers/recording_provider.dart';
import '../../../data/services/api_service.dart';

class AnalysisErrorScreen extends StatefulWidget {
  final Recording recording;
  final String? localFilePath;

  const AnalysisErrorScreen({
    super.key,
    required this.recording,
    this.localFilePath,
  });

  @override
  State<AnalysisErrorScreen> createState() => _AnalysisErrorScreenState();
}

class _AnalysisErrorScreenState extends State<AnalysisErrorScreen> {
  bool _isRetrying = false;
  /// Once the teacher has triggered a retry, lock the button permanently
  /// to prevent multiple concurrent uploads of the same recording.
  bool _hasRetried = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Analysis Failed'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 32),

            // Error Title
            const Text(
              'Analysis Could Not Be Completed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Specific Error Message
            Text(
              _getFriendlyErrorMessage(),
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSub,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Action Buttons
            if (_isRetrying)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  if (_canRetry() && !_hasRetried) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isRetrying || _hasRetried) ? null : _handleRetry,
                        icon: Icon(Icons.refresh_rounded),
                        label: const Text('Retry Analysis'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleDelete,
                      icon: Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete Recording'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getFriendlyErrorMessage() {
    final reason = widget.recording.failureReason ?? 'unknown';

    // Prefer the raw error message from the backend when it's specific and helpful
    final rawMessage = widget.recording.errorMessage;

    switch (reason) {
      // ── Duration / length issues ───────────────────────────────────────────
      case 'too_short':
        return rawMessage?.isNotEmpty == true
            ? rawMessage!
            : 'Your recording is too short. Please record at least 30 seconds of classroom activity for a meaningful analysis.';

      // ── File issues ────────────────────────────────────────────────────────
      case 'file_too_small':
        return 'The audio file appears to be empty or corrupted. Please try recording again and make sure the recording saved successfully before submitting.';

      case 'file_too_large':
        return rawMessage?.isNotEmpty == true
            ? rawMessage!
            : 'Your recording file is too large. Please use a compressed audio format (M4A or MP3) to reduce the file size and try again.';

      // ── Audio quality issues ───────────────────────────────────────────────
      case 'poor_audio':
        return 'No classroom audio was detected in this recording. The microphone may have been blocked or too far from the teaching area. Please try again — place your device closer to where you are teaching.';

      case 'insufficient_content':
        return 'The AI could not detect enough classroom interaction to complete a full analysis. This can happen if the microphone was far from the action, or if most of the recording captured non-teaching activity. Try recording during an active teaching segment and place the device closer to you.';

      // ── AI / processing issues ─────────────────────────────────────────────
      case 'token_limit_exceeded':
        return 'The analysis generated too much detail and exceeded the AI processing limit. This can happen with very long recordings. Please try again — the AI will produce a more concise response.';

      case 'ai_service_error':
        return 'The AI analysis service is temporarily unavailable. Please wait a moment and tap "Retry Analysis" below.';

      case 'network_error':
        return 'We had trouble downloading your recording for analysis. Please check your internet connection and tap "Retry Analysis" below.';

      case 'system_error':
      case 'storage_error':
      case 'database_error':
        return 'A system error occurred while processing your recording. This is not related to your lesson. Please tap "Retry Analysis" — it usually succeeds on the second attempt.';

      default:
        return rawMessage?.isNotEmpty == true
            ? rawMessage!
            : 'An unexpected error occurred during analysis. Please tap "Retry Analysis" below.';
    }
  }

  bool _canRetry() {
    // We can always retry:
    // - If local file exists → re-upload fresh
    // - If not → re-trigger analysis on the audio already on S3
    return true;
  }

  Future<void> _handleRetry() async {
    // One-shot guard — prevents double-tap from creating duplicate recordings.
    if (_hasRetried || _isRetrying) return;
    setState(() {
      _isRetrying = true;
      _hasRetried = true; // Lock permanently — teacher must go back and try fresh
    });

    try {
      final provider = Provider.of<RecordingProvider>(context, listen: false);

      // Path A: local file exists → delete old (failed) record and re-upload fresh
      final hasLocalFile = widget.localFilePath != null &&
          File(widget.localFilePath!).existsSync();

      if (hasLocalFile) {
        // Delete the failed recording first so it doesn't accumulate
        await provider.deleteRecording(widget.recording.id);

        final success = await provider.uploadRecording(
          widget.localFilePath!,
          widget.recording.title ?? 'Retried Recording',
          widget.recording.description,
          widget.recording.subject,
          widget.recording.gradeLevel,
          widget.recording.language,
          widget.recording.durationSeconds ?? 0,
        );

        if (!success && mounted) {
          final errMsg = provider.error;
          throw Exception(
            errMsg != null && errMsg.isNotEmpty
                ? errMsg
                : 'Upload failed during retry',
          );
        }
      } else {
        // Path B: audio is already on the server — just re-trigger the analysis
        await ApiService().analyzeRecording(widget.recording.id);
        provider.startPollingIfNeeded();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis re-submitted. You will be notified when it is ready.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Re-enable retry on failure so the teacher can try again
      if (mounted) setState(() => _hasRetried = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<RecordingProvider>(context, listen: false)
            .deleteRecording(widget.recording.id);
        if (mounted) {
          Navigator.of(context).pop(); // Close error screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }
}
