class Recording {
  final String id;
  final String userId;
  final String? title;
  final String? description;
  final String fileUrl;
  final int? fileSizeBytes;
  final int? durationSeconds;
  final String recordingType;
  final String? subject;
  final String? gradeLevel;
  final String language;
  final String status;
  final String? failureReason; // too_short, insufficient_content, service_error, etc.
  final String? errorMessage; // Human-readable error message
  final DateTime? recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recording({
    required this.id,
    required this.userId,
    this.title,
    this.description,
    required this.fileUrl,
    this.fileSizeBytes,
    this.durationSeconds,
    required this.recordingType,
    this.subject,
    this.gradeLevel,
    required this.language,
    required this.status,
    this.failureReason,
    this.errorMessage,
    this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      fileUrl: json['file_url'],
      fileSizeBytes: json['file_size_bytes'],
      durationSeconds: json['duration_seconds'],
      recordingType: json['recording_type'] ?? 'audio',
      subject: json['subject'],
      gradeLevel: json['grade_level'],
      language: json['language'] ?? 'en',
      status: json['status'],
      failureReason: json['failure_reason'],
      errorMessage: json['error_message'],
      recordedAt: json['recorded_at'] != null 
          ? DateTime.parse(json['recorded_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isInsufficientAudio => status == 'insufficient_audio';

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Analysis';
      case 'processing':
        return 'Analyzing...';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'insufficient_audio':
        return 'Recording Too Short';
      default:
        return status;
    }
  }

  String get durationDisplay {
    if (durationSeconds == null) return 'Unknown';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
