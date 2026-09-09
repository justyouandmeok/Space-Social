import 'dart:convert';
import 'package:http/http.dart' as http;

class GrokService {
  static const String _baseUrl = 'https://api.x.ai/v1/chat/completions';
  final String apiKey;

  GrokService({required this.apiKey});

  bool get ready => apiKey.isNotEmpty;

  Future<String> generateCaption(String promptTopic) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'grok-3',
        'messages': [
          {
            'role': 'system',
            'content':
                'Eres un generador de subtítulos creativos para Instagram con hashtags relevantes y tono actual. Respondé solo el caption, en español.',
          },
          {
            'role': 'user',
            'content': 'Escribe un caption para una foto sobre: $promptTopic',
          }
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return (data['choices'][0]['message']['content'] as String).trim();
    }
    throw Exception('Error al conectar con Grok: ${response.statusCode}');
  }

  Future<bool> isAppropriate(String text) async {
    if (!ready || text.trim().isEmpty) return true;
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'grok-3',
        'messages': [
          {
            'role': 'system',
            'content': 'Respondé solo SI o NO. SI = contenido apropiado para una red social pública. NO = odio, violencia explícita o abuso.',
          },
          {'role': 'user', 'content': text},
        ],
        'temperature': 0,
      }),
    );
    if (response.statusCode != 200) return true;
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final out = (data['choices'][0]['message']['content'] as String).toUpperCase();
    return out.contains('SI') || out.contains('SÍ') || out.contains('YES');
  }
}
