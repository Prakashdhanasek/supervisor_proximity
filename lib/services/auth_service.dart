import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class AuthResponse {
  final String token;
  final String fullName;
  final String email;
  final String role;
  final String expiresAt;

  const AuthResponse({
    required this.token,
    required this.fullName,
    required this.email,
    required this.role,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'],
    fullName: json['fullName'],
    email: json['email'],
    role: json['role'],
    expiresAt: json['expiresAt'],
  );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _base = 'https://proximity-driver-api.prod-app.in/api';

  String? _token;
  String? _fullName;
  String? _email;

  String? get fullName => _fullName;
  String? get email => _email;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final data = await TokenStorage.get();
    _token = data['token'];
    _fullName = data['fullName'];
    _email = data['email'];
  }

  Map<String, String> get authHeaders => {
        'accept': '*/*',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get authJsonHeaders => {
        ...authHeaders,
        'Content-Type': 'application/json',
      };

  Future<AuthResponse> login({required String email, required String password}) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'accept': '*/*', 'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = AuthResponse.fromJson(json.decode(res.body));
      _token = data.token;
      _fullName = data.fullName;
      _email = data.email;
      await TokenStorage.save(data.token, fullName: data.fullName, email: data.email);
      return data;
    }

    final body = json.decode(res.body);
    throw Exception(body['message'] ?? 'Login failed (${res.statusCode})');
  }

  Future<void> logout() async {
    _token = null;
    _fullName = null;
    _email = null;
    await TokenStorage.clear();
  }
}
