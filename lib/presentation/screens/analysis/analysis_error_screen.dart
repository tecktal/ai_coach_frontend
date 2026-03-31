import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../../data/models/recording.dart';
import '../../../data/providers/recording_provider.dart';

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
                  if (_canRetry()) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleRetry,
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
    
    switch (reason) {
      case 'too_short':
        return 'The recording is too short. AI Coach needs at least 1 minute of classroom audio to provide meaningful feedback.';
      case 'insufficient_content':
        return 'We couldn\'t detect enough clear teaching content in this audio. This might happen if the classroom was too noisy or the teacher\'s voice wasn\'t clear.';
      case 'file_too_small':
        return 'The audio file appears to be empty or corrupted.';
      case 'network_error':
        return 'We had trouble downloading your recording. Please check your internet connection and try again.';
      case 'token_limit_exceeded':
        return 'The specific analysis required too much detail and exceeded the AI token limit. Please try again with this local recording.';
      case 'ai_service_error':
        return 'Our AI service is temporarily unavailable. Please try again in a few moments.';
      default:
        return widget.recording.errorMessage ?? 'An unexpected error occurred during analysis. Please try again.';
    }
  }

  bool _canRetry() {
    // We can only retry if we have the local file path or if it's a transient server error
    // For now, checks if local file exists
    if (widget.localFilePath != null) {
      return File(widget.localFilePath!).existsSync();
    }
    return false; 
  }

  Future<void> _handleRetry() async {
    if (widget.localFilePath == null) return;
    
    setState(() => _isRetrying = true);
    
    try {
      final provider = Provider.of<RecordingProvider>(context, listen: false);
      
      final title = widget.recording.title ?? 'Retried Recording';
      final desc = widget.recording.description;
      final subject = widget.recording.subject;
      final grade = widget.recording.gradeLevel;
      final language = widget.recording.language ?? 'en';
      final duration = widget.recording.durationSeconds ?? 0;
      
      // Delete old failed record first
      await provider.deleteRecording(widget.recording.id);
      
      // Upload anew
      final success = await provider.uploadRecording(
        widget.localFilePath!,
        title,
        desc,
        subject,
        grade,
        language,
        duration,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retry successful! Analyzing again.')),
        );
        Navigator.of(context).pop();
      } else if (!success) {
        throw Exception(provider.error ?? 'Upload failed during retry');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry failed: $e')),
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
