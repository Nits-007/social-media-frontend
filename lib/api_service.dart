import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for Web/iOS
  static const String baseUrl = 'https://social-media-backend-mc01.onrender.com';

  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final _storage = const FlutterSecureStorage();

  ApiService() {
    // Interceptor: Add Token to every request if it exists
    _dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await _storage.read(key: 'token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    }, onError: (DioException e, handler) {
      // Optional: If 401 Unauthorized, you might want to trigger a logout here
      return handler.next(e);
    }));
  }

  // --- TOKEN MANAGEMENT ---
  Future<void> storeToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
  }

  // --- AUTH ---
  Future<String?> login(String email, String password) async {
    try {
      // NOTE: Adjust data format (JSON vs Form-Data) based on your backend expectation
      // If using OAuth2PasswordRequestForm in FastAPI, use FormData:
      // final formData = FormData.fromMap({'username': email, 'password': password});
      // final response = await _dio.post('/login', data: formData);

      // If using your Pydantic UserLogin schema (JSON):
      final response = await _dio
          .post('/login', data: {'email': email, 'password': password});

      // Ensure the key matches your backend response exactly (e.g. 'access_token' vs 'access token')
      final token =
          response.data['access_token'] ?? response.data['access token'];

      if (token != null) {
        await storeToken(token); // Save token immediately
      }
      return token;
    } on DioException catch (e) {
      if (e.response != null) {
        print("Server Error: ${e.response?.data}");
      }
      rethrow;
    }
  }

  Future<void> signup(String email, String password) async {
    await _dio.post('/users', data: {'email': email, 'password': password});
  }

  // --- POSTS ---

  Future<List<Post>> getPosts() async {
    final response = await _dio.get('/posts');

    return (response.data as List).map((x) => Post.fromJson(x)).toList();
  }

  Future<void> createPost(String title, String content, XFile? image) async {
    FormData formData = FormData.fromMap({
      'title': title,
      'content': content,
      'published': true,
    });

    if (image != null) {
      final bytes = await image.readAsBytes();
      // Add the file to the form data.
      // Key "file" must match `file: Optional[UploadFile] = File(None)` in FastAPI
      formData.files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(bytes, filename: image.name),
      ));
    }

    await _dio.post('/posts', data: formData);
  }

  Future<void> deletePost(int id) async => await _dio.delete('/posts/$id');

  Future<void> updatePost(
      int id, String title, String content, XFile? newImage) async {
    // Create FormData
    final formData = FormData.fromMap({
      'title': title,
      'content': content,
      'published': true,
    });

    // If there is a new image, attach it
    if (newImage != null) {
      // Use standard bytes reading for Web compatibility
      final bytes = await newImage.readAsBytes();
      formData.files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(bytes, filename: "update.png"),
      ));
    }

    // Send PUT request with FormData
    await _dio.put('/posts/$id', data: formData);
  }

  Future<void> votePost(int postId, int dir) async {
    await _dio.post('/votes', data: {'post_id': postId, 'dir': dir});
  }

  // --- USERS ---
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data);
  }

  Future<User> getUserById(int id) async {
    final response = await _dio.get('/users/$id');
    return User.fromJson(response.data);
  }

  Future<List<User>> searchUsers(String query) async {
    final response =
        await _dio.get('/users/', queryParameters: {'search': query});
    return (response.data as List).map((x) => User.fromJson(x)).toList();
  }

  Future<void> uploadProfileImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: file.name),
      });
      await _dio.post("/users/image", data: formData);
    } catch (e) {
      rethrow;
    }
  }
}
