import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/jisho_response.dart';

class JishoApiService {
  static const String _baseUrl = 'https://jisho.org/api/v1/search/words';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<JishoResponse?> searchWords(String keyword) async {
    try {
      if (keyword.trim().isEmpty) {
        return null;
      }

      final encodedKeyword = Uri.encodeComponent(keyword.trim());
      final url = Uri.parse('$_baseUrl?keyword=$encodedKeyword');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Flutter-Dictionary-App/1.0',
          'Accept': 'application/json',
          'Accept-Encoding': 'gzip, deflate, br',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return JishoResponse.fromJson(jsonData);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: $e');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static String getKeywordFromUrl(String keyword) {
    return '$_baseUrl?keyword=${Uri.encodeComponent(keyword)}';
  }
}