import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'local_storage_service.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  final LocalStorageService _storage = LocalStorageService();

  ApiService._internal() {

    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBase,
      connectTimeout: const Duration(seconds: 600), // Hardcoded to force update
      receiveTimeout: const Duration(seconds: 600),
      sendTimeout: const Duration(seconds: 600),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.clearAll();
        }
        return handler.next(error);
      },
    ));
  }
  
  // Cleanup method (call when app is disposed if needed)
  void dispose() {
    _dio.close();
  }

  // Auth
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/auth/register', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/auth/me', data: data);
    return response.data;
  }

  Future<void> verifyEmail(String email, String code) async {
    await _dio.post(
      '/auth/verify-email',
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resendVerification(String email) async {
    await _dio.post(
      '/auth/resend-verification',
      data: {'email': email},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post(
      '/auth/reset-password',
      data: {'token': token, 'new_password': newPassword},
    );
  }

  // Recordings
  Future<Map<String, dynamic>> uploadRecording(
    String filePath,
    Map<String, String> metadata,
  ) async {
    final formData = FormData.fromMap({
      'audio': await MultipartFile.fromFile(filePath),
      ...metadata,
    });

    final response = await _dio.post('/recordings', data: formData);
    return response.data;
  }

  Future<List<dynamic>> getRecordings() async {
    final response = await _dio.get('/recordings');
    return response.data as List;
  }

  Future<Map<String, dynamic>> getRecording(String id) async {
    final response = await _dio.get('/recordings/$id');
    return response.data;
  }

  Future<void> deleteRecording(String id) async {
    await _dio.delete('/recordings/$id');
  }

  Future<Map<String, dynamic>> analyzeRecording(String recordingId) async {
    final response = await _dio.post('/recordings/$recordingId/analyze');
    return response.data;
  }

  // Analyses
  Future<List<dynamic>> getAnalyses() async {
    final response = await _dio.get('/analyses');
    return response.data as List;
  }

  Future<Map<String, dynamic>> getAnalysis(String analysisId) async {
    final response = await _dio.get('/analyses/$analysisId');
    return response.data;
  }

  // Chat
  Future<Map<String, dynamic>> createChatSession(String? analysisId) async {
    try {

      final response = await _dio.post(
        '/chat/sessions',
        data: {'analysis_id': analysisId},
      );

      return response.data;
    } catch (e) {

      if (e is DioException) {
        // No print statements here
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getChatSessions() async {
    final response = await _dio.get('/chat/sessions');
    return response.data as List;
  }

  Future<Map<String, dynamic>> getChatSession(String sessionId) async {
    final response = await _dio.get('/chat/sessions/$sessionId');
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage(
    String sessionId,
    String content,
  ) async {
    final response = await _dio.post(
      '/chat/sessions/$sessionId/messages',
      data: {'content': content},
    );
    return response.data;
  }

  Stream<String> streamChatResponse(String sessionId, String content) async* {
    
    try {
      final response = await _dio.post(
        '/chat/sessions/$sessionId/stream',
        data: {'content': content},
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      final stream = response.data.stream;
      await for (final chunk in stream) {
        // Decode chunk bytes to string
        final String text = String.fromCharCodes(chunk);

        
        // Parse SSE format
        // Format is usually "event: message\ndata: <content>\n\n"
        final lines = text.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data.isNotEmpty) {
              yield data;
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    await _dio.delete('/chat/sessions/$sessionId');
  }

  // Progress
  Future<Map<String, dynamic>> getProgress() async {
    final response = await _dio.get('/progress');
    return response.data;
  }

  Future<Map<String, dynamic>> getTrends() async {
    final response = await _dio.get('/progress/trends');
    return response.data;
  }
}
