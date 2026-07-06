import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "",
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    // Android emulator can access host machine localhost via 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return "http://10.0.2.2:5001";
    }

    // Web, iOS simulator, macOS, Windows and Linux default to local loopback.
    return "http://127.0.0.1:5001";
  }

  static Future<Map<String, dynamic>> login(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email}),
          )
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid login response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<List<dynamic>> getSlots({String status = "ALL"}) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/slots?status=${status.toUpperCase()}"))
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      throw Exception("Invalid slots response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<List<dynamic>> getVehiclesForUser(int userId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/users/$userId/vehicles"))
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      throw Exception("Invalid vehicles response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<List<dynamic>> getNotifications(int userId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/notifications/$userId"))
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      throw Exception("Invalid notifications response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/users/$userId/profile"))
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid profile response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<Map<String, dynamic>> markNotificationRead(int notificationId) async {
    try {
      final response = await http
          .patch(
            Uri.parse("$baseUrl/notifications/$notificationId/read"),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid mark-as-read response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<Map<String, dynamic>> bookSlot(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/book"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid booking response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<Map<String, dynamic>> pay(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/pay"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid payment response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static Future<Map<String, dynamic>> extend(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/extend"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      final decoded = _decodeResponse(response);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      throw Exception("Invalid extension response");
    } catch (error) {
      throw Exception(_friendlyError(error));
    }
  }

  static dynamic _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      if (decoded is Map<String, dynamic> && decoded["error"] != null) {
        throw Exception(decoded["error"].toString());
      }
      throw Exception("Request failed with status ${response.statusCode}");
    }

    return decoded;
  }

  static String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst("Exception: ", "");
    final lower = raw.toLowerCase();
    final bool isConnectivityError =
        lower.contains("failed to fetch") ||
        lower.contains("connection refused") ||
        lower.contains("failed host lookup") ||
        lower.contains("socketexception") ||
        lower.contains("clientexception") ||
        lower.contains("timed out");

    if (isConnectivityError) {
      return "Cannot connect to backend at $baseUrl. "
          "If needed, pass --dart-define=API_BASE_URL=http://<your-ip>:5001";
    }
    return raw;
  }
}
