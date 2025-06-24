import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:convert';

class IllusiaService {
  static const _baseUrl = 'https://illusia.com.br';

  static Future<List<Map<String, String>>> getLancamentos() async {
    final response = await http.get(Uri.parse('$_baseUrl/lancamentos/'));
    final document = parse(response.body);

    final updates = document.querySelectorAll('li._latest-updates');
    return updates.map((novel) {
      final aTag = novel.querySelector('a');
      final imgTag = novel.querySelector('img');
      return {
        'url': aTag?.attributes['href']?.split('/')[4] ?? '',
        'nome': aTag?.attributes['title'] ?? '',
        'cover': imgTag?.attributes['src'] ?? '',
      };
    }).toList();
  }

  static Future<Map<String, dynamic>> getNovelInfo(String novel) async {
    final response = await http.get(Uri.parse('$_baseUrl/story/$novel/'));
    final document = parse(response.body);

    final name =
        document.querySelector('.story__identity-title')?.text.trim() ?? '';
    final descSection = document.querySelector('section.story__summary');
    final desc = descSection?.text.trim() ?? '';
    final cover =
        document.querySelector('.webfeedsFeaturedVisual')?.attributes['src'] ??
        '';

    final chapters =
        document.querySelectorAll('.chapter-group__list a').map((a) {
          return {
            'title': a.text.trim(),
            'id':
                a.attributes['href']?.split(
                  '/',
                )[a.attributes['href']!.split('/').length - 2] ??
                '',
          };
        }).toList();

    final genres =
        document.querySelectorAll('._taxonomy-genre').map((a) {
          return {
            'id': a.attributes['href']?.split('/')[4] ?? '',
            'name': a.text.trim(),
          };
        }).toList();

    return {
      'nome': name,
      'desc': desc,
      'cover': cover,
      'chapters': chapters,
      'genres': genres,
    };
  }

  static Future<Map<String, String>> getChapter(
    String novel,
    String chapter,
  ) async {
    final url = '${_baseUrl}/story/${novel}/${chapter}/';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final doc = parse(response.body);
      final title =
          doc.querySelector(".chapter__story-link")?.text.trim() ?? '';
      final subtitle = doc.querySelector(".chapter__title")?.text.trim() ?? '';
      final content = doc.querySelector("#chapter-content")?.outerHtml ?? '';

      return {'title': title, 'subtitle': subtitle, 'content': content};
    } else {
      throw Exception('Erro ao carregar capítulo $chapter de $novel');
    }
  }

  static Future<List<Map<String, String>>> search(String text) async {
    final encoded = Uri.encodeComponent(text);
    final url =
        '$_baseUrl/?s=$encoded&post_type=fcn_story&sentence=0&orderby=modified&order=desc&age_rating=Any&story_status=Any&miw=0&maw=0&genres=&fandoms=&characters=&tags=&warnings=&authors=&ex_genres=&ex_fandoms=&ex_characters=&ex_tags=&ex_warnings=&ex_authors=';
    final response = await http.post(Uri.parse(url));
    final document = parse(response.body);

    final results = document.querySelectorAll('li.card');
    return results.map((li) {
      final aTag = li.querySelector('a');
      final imgTag = li.querySelector('img');
      return {
        'nome': aTag?.text.trim() ?? '',
        'url': aTag?.attributes['href']?.split('/')[4] ?? '',
        'cover': imgTag?.attributes['src'] ?? '',
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    final url =
        'https://raw.githubusercontent.com/luanwillianzh/Novel-Reader-Data/refs/heads/main/illusia.json';
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
