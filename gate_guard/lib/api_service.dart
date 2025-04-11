import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // static const String baseUrl = "http://192.168.1.9:5000/api"; // Home WIFI
  // static const String baseUrl =
  //     "http://192.168.20.175:5000/api"; // Mobile Physical
  // static const String baseUrl =
  //     "http://192.168.187.132:5000/api"; // Mobile Hotspot
  static const String baseUrl =
      "https://gateguard-api.onrender.com/api"; // Cloud Server

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
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchAuthorizedCards() async {
    final String url = "$baseUrl/info/authorized-cards";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse.cast<Map<String, dynamic>>();
      } else {
        print("Failed to fetch authorized cards: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching authorized cards: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/info/users'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Ensure each item in the list is a Map<String, dynamic>
        return data.map((user) => user as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserCards(
      String userId) async {
    final String url = '$baseUrl/info/users/$userId/cards';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(responseData['cards']);
      } else {
        print('Failed to fetch user cards: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching user cards: $e');
      return [];
    }
  }

  static Future<bool> createAuthorizedCard(
      String cardUid, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create/authorized-card'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'card_uid': cardUid,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 201) {
        return true; // Successfully created
      } else {
        print('Failed to authorize card: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error creating authorized card: $e');
      return false;
    }
  }

  static Future<bool> createUser(
      String name, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create/user'), // Replace with your actual endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      if (response.statusCode == 201) {
        return true; // User created successfully
      } else {
        print("Failed to create user: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  static Future<bool> updateAuthorizedCard(
      String cardId, String cardUid, String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update-remove/authorized-card/$cardId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"card_uid": cardUid, "user_id": userId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error updating card: $e");
      return false;
    }
  }

  static Future<bool> deleteAuthorizedCard(String cardId) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/update-remove/authorized-card/$cardId'));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error deleting card: $e");
      return false;
    }
  }

  static Future<bool> updateUser(String userId, String name, String email,
      String role, String? password) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update-remove/user/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "role": role,
          if (password != null && password.isNotEmpty)
            "password": password, // Only send password if provided
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error updating user: $e");
      return false;
    }
  }

  static Future<bool> deleteUser(String userId) async {
    try {
      final response =
          await http.delete(Uri.parse('$baseUrl/update-remove/user/$userId'));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error deleting user: $e");
      return false;
    }
  }
}
