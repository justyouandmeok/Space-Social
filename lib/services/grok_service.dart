import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Cliente HTTP para la API de xAI Grok.
/// No incluye clave. Pasá la API key solo en runtime si la necesitás.
class GrokService {
  GrokService({this.apiKey, this.baseUrl = 'https://api.x.ai/v1'});

  final String? apiKey;
  final String baseUrl;

  bool get configured => apiKey != null && apiKey!.isNotEmpty;

  Future<String> chat(String prompt) async {
    if (!configured) {
      debugPrint('GrokService: falta API key');
      return '';
    }
    // Placeholder de cliente. No se llama solo.
    return jsonEncode({'prompt': prompt});
  }
}
