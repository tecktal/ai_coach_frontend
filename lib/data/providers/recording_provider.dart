import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording.dart';
import '../services/api_service.dart';

/// Called when a recording's status changes during polling.
/// [recording] is the updated recording.
/// [previousStatus] is what it was before.
typedef RecordingStatusCallback = void Function(
    Recording recording, String previousStatus);

class RecordingProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  SharedPreferences? _prefs;
  static const String _localPathKeyPrefix = 'local_path_';

  List<Recording> _recordings = [];
  bool _isLoading = false;
  String? _error;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Polling
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 12);
  RecordingStatusCallback? onStatusChanged;

  // Track which recording IDs we've already notified about so we don't
  // fire duplicate notifications for the same terminal state.
  final Set<String> _notifiedIds = {};

  List<Recording> get recordings => _recordings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;

  bool get hasProcessingRecordings => _recordings.any(
      (r) => r.isProcessing || r.isPending);

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ── Polling ──────────────────────────────────────────────────────────────

  /// Start polling if there are recordings in a non-terminal state.
  void startPollingIfNeeded() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    if (!hasProcessingRecordings) return;
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (!hasProcessingRecordings) {
      stopPolling();
      return;
    }

    try {
      final response = await _api.getRecordings();
      final updated = response.map((r) => Recording.fromJson(r)).toList();

      // Build a map of previous statuses
      final prevMap = {for (var r in _recordings) r.id: r.status};

      _recordings = updated;
      notifyListeners();

      // Fire callbacks for status changes
      for (final r in updated) {
        final prev = prevMap[r.id];
        if (prev != null && prev != r.status) {
          // Only notify once per terminal state
          final isTerminal = r.isCompleted || r.isFailed || r.isInsufficientAudio;
          if (isTerminal && _notifiedIds.contains(r.id)) continue;
          if (isTerminal) _notifiedIds.add(r.id);
          onStatusChanged?.call(r, prev);
        }
      }

      // Stop polling if nothing left to watch
      if (!hasProcessingRecordings) stopPolling();
    } catch (_) {
      // Silently ignore poll errors
    }
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> loadRecordings({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      await _initPrefs();
      final response = await _api.getRecordings();
      _recordings = response.map((r) => Recording.fromJson(r)).toList();
      if (!silent) _isLoading = false;
      notifyListeners();

      // Auto-start polling if needed
      startPollingIfNeeded();
    } catch (e) {
      _error = e.toString();
      if (!silent) _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadRecording(
    String filePath,
    String title,
    String? description,
    String? subject,
    String? gradeLevel,
    String language,
    int durationSeconds,
  ) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    _error = null;
    notifyListeners();

    try {
      final metadata = {
        'title': title,
        if (description != null) 'description': description,
        if (subject != null) 'subject': subject,
        if (gradeLevel != null) 'grade_level': gradeLevel,
        'language': language,
        'duration_seconds': durationSeconds.toString(),
      };

      final response = await _api.uploadRecording(filePath, metadata);
      final recording = Recording.fromJson(response);

      // Save local path for retry capabilities
      await _initPrefs();
      await _prefs?.setString('$_localPathKeyPrefix${recording.id}', filePath);

      _recordings.insert(0, recording);

      _isUploading = false;
      _uploadProgress = 1.0;
      notifyListeners();

      // Start polling for this new recording
      startPollingIfNeeded();

      return true;
    } catch (e) {
      _error = e.toString();
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecording(String id) async {
    try {
      await _api.deleteRecording(id);

      await _initPrefs();
      await _prefs?.remove('$_localPathKeyPrefix$id');

      _recordings.removeWhere((r) => r.id == id);
      _notifiedIds.remove(id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Recording? getRecordingById(String id) {
    try {
      return _recordings.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  String? getLocalFilePath(String id) {
    return _prefs?.getString('$_localPathKeyPrefix$id');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
