import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class CentralService {
  static const _baseUrl =
      'https://raw.githubusercontent.com/luanwillianzh/Novel-Reader-Data/refs/heads/main';

  static Future<Map<String, dynamic>> getNovelInfo(String novelId) async {
    final url = '$_baseUrl/$novelId/info.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erro ao carregar info.json da novel $novelId');
    }
  }

  static Future<Map<String, String>> getChapter(
    String novelId,
    String chapterId,
  ) async {
    final url = '$_baseUrl/$novelId/$chapterId.html';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final doc = parse(response.body);
      final title = doc.querySelector("h1")?.text.trim() ?? '';
      final subtitle = doc.querySelector("h2")?.text.trim() ?? '';
      final content =
          doc.querySelector("div.epcontent.entry-content")?.outerHtml ?? '';

      return {'title': title, 'subtitle': subtitle, 'content': content};
    } else {
      throw Exception('Erro ao carregar capítulo $chapterId de $novelId');
    }
  }

  static Future<List<Map<String, dynamic>>> search(String text) async {
    final url = '$_baseUrl/info.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> all = json.decode(response.body);
      final query = Uri.decodeFull(text).toLowerCase();

      return all.entries
          .where((e) => e.value.toString().toLowerCase().contains(query))
          .map(
            (e) => {
              'nome': e.value['nome'],
              'url': e.key,
              'cover': e.value['cover'],
              'genres': e.value['genres'],
            },
          )
          .toList();
    } else {
      throw Exception('Erro ao buscar dados');
    }
  }
}
