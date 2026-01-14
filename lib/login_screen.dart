import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart'; // <--- IMPORTANT: Import Dio for error handling
import '../auth_provider.dart';
import '../api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // --- LOGIN LOGIC ---
        await Provider.of<AuthProvider>(context, listen: false)
            .login(_emailController.text, _passwordController.text);
      } else {
        // --- SIGNUP LOGIC ---
        await ApiService()
            .signup(_emailController.text, _passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Log in now.")),
          );
          setState(() => _isLogin = true);
        }
      }
    } on DioException catch (e) {
      // --- HANDLE ERROR CODES ---
      if (mounted) {
        String errorMessage = "An error occurred";

        if (_isLogin) {
          // 401: Unauthorized (Wrong Password/Email)
          // 403: Forbidden
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            errorMessage = "Wrong credentials";
          }
        } else {
          // Signup Errors
          // 400: Bad Request (Often validation error)
          // 409: Conflict (Email already exists)
          if (e.response?.statusCode == 400 || e.response?.statusCode == 409) {
            errorMessage =
                "Use a different email"; // Specific message for duplicates
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.bubble_chart, size: 80, color: Colors.indigo),
              const SizedBox(height: 16),
              const Text(
                "SocialApp",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? "Login" : "Create Account",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin
                    ? "New here? Create an account"
                    : "Have an account? Log in"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
