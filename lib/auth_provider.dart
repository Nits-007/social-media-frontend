import 'package:flutter/material.dart';
import '../api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  
  bool _isAuthenticated = false;
  bool _isLoading = true; // Apps starts in loading state

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Called immediately in main.dart
  Future<void> tryAutoLogin() async {
    final token = await _api.getToken();
    
    if (token != null && token.isNotEmpty) {
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      await _api.login(email, password); // API service saves the token
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _api.logout(); // Clear token from storage
    _isAuthenticated = false;
    notifyListeners();
  }
}