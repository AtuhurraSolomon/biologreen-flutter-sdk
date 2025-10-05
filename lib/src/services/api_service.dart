import 'dart:convert';
import 'package:http/http.dart' as http;

// --- Data Models ---
// It's good practice to define the data structures the service will work with.

/// Represents the successful JSON response from the BioLogreen API.
class FaceAuthResponse {
  final int userId;
  final bool isNewUser;
  final Map<String, dynamic>? customFields;

  FaceAuthResponse({
    required this.userId,
    required this.isNewUser,
    this.customFields,
  });

  factory FaceAuthResponse.fromJson(Map<String, dynamic> json) {
    return FaceAuthResponse(
      userId: json['user_id'] as int,
      isNewUser: json['is_new_user'] as bool,
      customFields: json['custom_fields'] as Map<String, dynamic>?,
    );
  }
}

// --- Custom Exception ---
// This makes error handling specific and robust for the developer using the SDK.

/// A custom exception to represent errors returned from the BioLogreen API.
class BioLogreenApiException implements Exception {
  final String message;
  final int statusCode;

  BioLogreenApiException(this.message, this.statusCode);

  @override
  String toString() => 'BioLogreenApiException (Status $statusCode): $message';
}

// --- API Service ---
// This class encapsulates all network logic.

class ApiService {
  final String _apiKey;
  final String _baseUrl;

  ApiService({
    required String apiKey,
    String baseUrl = 'https://api.biologreen.com/v1',
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl;

  /// Performs a POST request for the signup endpoint.
  Future<FaceAuthResponse> signup({
    required String imageBase64,
    Map<String, dynamic>? customFields,
  }) async {
    final body = {
      'image_base64': imageBase64,
      if (customFields != null) 'custom_fields': customFields,
    };
    return _post('/auth/signup-face', body);
  }

  /// Performs a POST request for the login endpoint.
  Future<FaceAuthResponse> login({required String imageBase64}) async {
    final body = {'image_base64': imageBase64};
    return _post('/auth/login-face', body);
  }

  /// Private helper to handle the actual HTTP POST request and error handling.
  Future<FaceAuthResponse> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$_baseUrl$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': _apiKey,
        },
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        // If the server returns an error, parse the 'detail' message
        // and throw our robust, custom exception.
        final errorMessage =
            responseBody['detail'] ?? 'An unknown API error occurred.';
        throw BioLogreenApiException(errorMessage, response.statusCode);
      }

      // If successful, parse the response into our data model.
      return FaceAuthResponse.fromJson(responseBody);
    } catch (e) {
      // Re-throw our known API exceptions, otherwise wrap the error for clarity.
      if (e is BioLogreenApiException) {
        rethrow;
      }
      // This catches lower-level issues like network errors or JSON parsing failures.
      throw Exception(
          'Failed to communicate with the BioLogreen API: ${e.toString()}');
    }
  }
}
