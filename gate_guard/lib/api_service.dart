import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.1.10:5000/api";
  // static const String baseUrl = "http://192.168.20.175:5000/api";

  static Future<Map<String, dynamic>?> loginUser(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchDashboardData(
      String userId, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dashboard'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'role': role}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<List<dynamic>> fetchCardScans(
      String userId, String role, List<dynamic> userCards) async {
    final response = await http.post(
      Uri.parse('$baseUrl/card-scans'),
      headers: {'Content-Type': 'application/json'},
      body:
          jsonEncode({'userId': userId, 'role': role, 'userCards': userCards}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
      print(response.body);
    }
    return [];
  }
}
