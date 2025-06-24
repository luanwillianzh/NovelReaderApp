import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:convert';

class NovelManiaService {
  static const _baseUrl = 'https://novelmania.com.br';

  // Lançamentos na home
  static Future<List<Map<String, String>>> getLancamentos() async {
    final response = await http.get(Uri.parse(_baseUrl));
    final document = parse(response.body);

    final items = document.querySelectorAll(".novels .col-6");
    return items.map((i) {
      final a = i.querySelector("a");
      final h2 = i.querySelector("h2");
      final img = i.querySelector("img");
      return {
        'url': a?.attributes['href']?.split('/').last ?? '',
        'nome': h2?.text.trim() ?? '',
        'cover': img?.attributes['src'] ?? '',
      };
    }).toList();
  }

  // Detalhes da novel
  static Future<Map<String, dynamic>> getNovelInfo(String novelId) async {
    final response = await http.get(Uri.parse("$_baseUrl/novels/$novelId/"));
    final document = parse(response.body);

    final name =
        document
            .querySelector("h1.font-400.mb-2.wow.fadeInRight.mr-3")
            ?.text
            .trim() ??
        '';

    final descDiv = document.querySelector("div.text");
    final desc = descDiv?.text.trim() ?? '';

    final cover = document.querySelector(".img-responsive")?.attributes['src'];

    final chapters =
        document.querySelectorAll("ol.list-inline li a").map((a) {
          final strong = a.querySelector("strong");
          return {
            'title': strong?.text.trim() ?? '',
            'id': a.attributes['href']?.split('/').last ?? '',
          };
        }).toList();

    final genres =
        document.querySelectorAll(".list-tags a").map((a) {
          return {
            'id': a.attributes['href']?.split('/').last ?? '',
            'name': a.attributes['title'] ?? '',
          };
        }).toList();

    return {
      'nome': name,
      'desc': desc,
      'cover': cover ?? '',
      'chapters': chapters,
      'genres': genres,
    };
  }

  // Conteúdo de um capítulo
  static Future<Map<String, String>> getChapter(
    String novelId,
    String chapterId,
  ) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/novels/$novelId/capitulos/$chapterId"),
    );
    final document = parse(response.body);

    final title = document.querySelector("h3.mb-0");
    final subtitle = document.querySelector("h2.mt-0");

    final rawContent =
        document.querySelector("#chapter-content")?.outerHtml ?? '';
    final splitContent = rawContent.split("<div data-reactionable")[0];
    final cleanContent = splitContent
        .replaceFirst(title?.outerHtml ?? '', "")
        .replaceFirst(subtitle?.outerHtml ?? '', "");

    return {
      'title': title?.text.trim() ?? '',
      'subtitle': subtitle?.text.trim() ?? '',
      'content': cleanContent,
    };
  }

  // Busca de novels
  static Future<List<Map<String, String>>> search(String text) async {
    final encoded = Uri.encodeComponent(text);
    final url =
        "$_baseUrl/novels?titulo=$encoded&categoria=&nacionalidade=&status=&ordem=&commit=Pesquisar+novel";
    final response = await http.get(Uri.parse(url));
    final document = parse(response.body);

    final results = document.querySelectorAll(".top-novels");
    return results.map((a) {
      final h5 = a.querySelector("h5");
      final img = a.querySelector("img");
      final url =
          a.querySelector("a")?.attributes['href']?.split('/').last ?? '';
      return {
        'nome': h5?.text.trim() ?? '',
        'url': url,
        'cover': img?.attributes['src'] ?? '',
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final url =
        'https://raw.githubusercontent.com/luanwillianzh/Novel-Reader-Data/refs/heads/main/mania.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> all = json.decode(response.body);

      return all["resultado"]
          .map(
            (e) => {
              'nome': e.value['nome'],
              'url': e.value['url'],
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
