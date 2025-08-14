// lib/services/api_service.dart
import 'dart:convert'; // For json.encode/decode if storing complex objects

import 'package:http/http.dart' as http;

import '../models.dart';
import './illusia_service.dart';
import './mania_service.dart';
import './central_service.dart';

class ApiService {
  Future<List<Lancamento>> fetchLancamentos() async {
    final results = <Lancamento>[];

    try {
      final illusia = await IllusiaService.getLancamentos();
      results.addAll(
        illusia.map(
          (item) => Lancamento(
            nome: item['nome']!,
            url: 'illusia-${item['url']}',
            cover: item['cover']!,
          ),
        ),
      );
    } catch (_) {
      // Consider logging the error for debugging purposes in a real application
    }

    try {
      final mania = await NovelManiaService.getLancamentos();
      results.addAll(
        mania.map(
          (item) => Lancamento(
            nome: item['nome']!,
            url: 'mania-${item['url']}',
            cover: item['cover']!,
          ),
        ),
      );
    } catch (_) {
      // Consider logging the error
    }

    try {
      final central = await CentralService.search(" ");
      results.addAll(
        central.map(
          (e) => Lancamento(
            nome: e['nome']!,
            url: 'central-${e['url']}',
            cover: e['cover']!,
          ),
        ),
      );
    } catch (_) {
      // Consider logging the error
    }

    return results;
  }

  /// Fetches and filters novels by a given genre from Illusia, Central, and Mania services.
  /// Returns a list of [GenreFilter] objects that match the specified genre.
  Future<List<GenreFilter>> fetchByGenre(String genre) async {
    // List to store all raw novel data as GenreFilter objects
    List<GenreFilter> allNovels = [];

    // Fetch from Illusia using direct HTTP request
    try {
      final illusiaResponse = await http.get(
        Uri.parse(
          "https://raw.githubusercontent.com/luanwillianzh/Novel-Reader-Data/refs/heads/main/illusia.json",
        ),
      );
      if (illusiaResponse.statusCode == 200) {
        final illusiaData =
            json.decode(illusiaResponse.body)["resultado"] as List;
        allNovels.addAll(
          illusiaData
              .map(
                (item) => GenreFilter(
                  nome: item['nome'],
                  url: 'illusia-${item['url']}',
                  cover: item['cover'],
                  genres: item.containsKey('genres') ? item['genres'] : [],
                ),
              )
              .toList(),
        );
      }
    } catch (e) {
      print('Erro ao buscar novels Illusia por gênero: $e');
    }

    // Fetch from Central (keeping existing CentralService.search)
    try {
      // Assuming CentralService.search(" ") returns List<Map<String, dynamic>>
      // where each map contains 'nome', 'url', 'cover', and 'genres' (List<List<String>>)
      final centralData = await CentralService.search(" ");
      allNovels.addAll(
        centralData
            .map(
              (item) => GenreFilter(
                nome: item['nome'],
                url: 'central-${item['url']}',
                cover: item['cover'],
                // Ensure 'genres' exists or default to an empty list
                genres: item.containsKey('genres') ? item['genres'] : [],
              ),
            )
            .toList(),
      );
    } catch (e) {
      print("Erro ao buscar dados da Central: $e");
    }

    // Fetch from Mania using direct HTTP request
    try {
      final maniaResponse = await http.get(
        Uri.parse(
          "https://raw.githubusercontent.com/luanwillianzh/Novel-Reader-Data/refs/heads/main/mania.json",
        ),
      );
      if (maniaResponse.statusCode == 200) {
        final maniaData = json.decode(maniaResponse.body)["resultado"] as List;
        allNovels.addAll(
          maniaData
              .map(
                (item) => GenreFilter(
                  nome: item['nome'],
                  url: 'mania-${item['url']}',
                  cover: item['cover'],
                  genres: item.containsKey('genres') ? item['genres'] : [],
                ),
              )
              .toList(),
        );
      }
    } catch (e) {
      print("Erro ao buscar dados de Mania: $e");
    }

    // Filter the combined list by genre
    final filteredResults =
        allNovels.where((novelData) {
          final novelGenres =
              novelData
                  .genres; // Access the genres list from GenreFilter object
          if (novelGenres is! List) {
            return false; // If 'genres' is null or not a list, exclude this novel
          }

          // Filtering logic:
          // The 'genres' field can come as List<String> (just the genre name)
          // or List<List<String>> (like in Central, where it's [id, name])
          return novelGenres.any((g) {
            if (g is String) {
              // Case where the genre is just the name (e.g., "Fantasy")
              return g.toLowerCase() == genre.toLowerCase();
            } else if (g is List && g.isNotEmpty && g[0] is String) {
              // Case where it's a List<String> like ["action", "Action"]
              // Check both the ID and the name for a match
              return g[0].toLowerCase() == genre.toLowerCase() ||
                  g[1].toLowerCase() == genre.toLowerCase();
            }
            return false; // If the format is unexpected, don't include
          });
        }).toList(); // Convert the iterable back to a list

    return filteredResults; // Returns List<GenreFilter>
  }

  Future<Novel> fetchNovel(String novelId) async {
    if (novelId.startsWith('illusia-')) {
      final id = novelId.replaceFirst('illusia-', '');
      final data = await IllusiaService.getNovelInfo(id);
      final genres =
          (data['genres'] as List)
              .map((g) => Genre(id: g['id'], name: g['name']))
              .toList();
      final chapters =
          (data['chapters'] as List)
              .map((c) => ChapterSummary(title: c['title'], id: c['id']))
              .toList();
      return Novel(
        id: novelId,
        nome: data['nome'],
        desc: data['desc'],
        cover: data['cover'],
        genres: genres,
        chapters: chapters,
      );
    } else if (novelId.startsWith('mania-')) {
      final id = novelId.replaceFirst('mania-', '');
      final data = await NovelManiaService.getNovelInfo(id);
      final genres =
          (data['genres'] as List)
              .map((g) => Genre(id: g['id'], name: g['name']))
              .toList();
      final chapters =
          (data['chapters'] as List)
              .map((c) => ChapterSummary(title: c['title'], id: c['id']))
              .toList();
      return Novel(
        id: novelId,
        nome: data['nome'],
        desc: data['desc'],
        cover: data['cover'],
        genres: genres,
        chapters: chapters,
      );
    } else if (novelId.startsWith('central-')) {
      final id = novelId.replaceFirst('central-', '');
      final data = await CentralService.getNovelInfo(id);
      final genres =
          (data['genres'] as List)
              .map((g) => Genre(id: g[0], name: g[1]))
              .toList();
      final chapters =
          (data['chapters'] as List)
              .map((c) => ChapterSummary(title: c[0], id: c[1]))
              .toList();
      return Novel(
        id: novelId,
        nome: data['nome'],
        desc: data['desc'],
        cover: data['cover'],
        genres: genres,
        chapters: chapters,
      );
    } else {
      throw Exception('Fonte desconhecida para novelId: $novelId');
    }
  }

  Future<Chapter> fetchChapter(String novelId, String chapterId) async {
    if (novelId.startsWith('illusia-')) {
      final id = novelId.replaceFirst('illusia-', '');
      final data = await IllusiaService.getChapter(id, chapterId);
      return Chapter.fromJson(data);
    } else if (novelId.startsWith('mania-')) {
      final id = novelId.replaceFirst('mania-', '');
      final data = await NovelManiaService.getChapter(id, chapterId);
      return Chapter.fromJson(data);
    } else if (novelId.startsWith('central-')) {
      final id = novelId.replaceFirst('central-', '');
      final data = await CentralService.getChapter(id, chapterId);
      return Chapter.fromJson(data);
    } else {
      throw Exception('Fonte desconhecida para capítulo');
    }
  }

  Future<List<Lancamento>> searchLancamentos(String query) async {
    final results = <Lancamento>[];

    try {
      final illusia = await IllusiaService.search(query);
      results.addAll(
        illusia.map(
          (e) => Lancamento(
            nome: e['nome']!,
            url: 'illusia-${e['url']}',
            cover: e['cover']!,
          ),
        ),
      );
    } catch (_) {
      // Consider logging the error
    }

    try {
      final mania = await NovelManiaService.search(query);
      results.addAll(
        mania.map(
          (e) => Lancamento(
            nome: e['nome']!,
            url: 'mania-${e['url']}',
            cover: e['cover']!,
          ),
        ),
      );
    } catch (_) {
      // Consider logging the error
    }

    try {
      final central = await CentralService.search(query);
      results.addAll(
        central.map(
          (e) => Lancamento(
            nome: e['nome']!,
            url: 'central-${e['url']}',
            cover: e['cover']!,
          ),
        ),
      );
    } catch (_) {
      // Consider logging the error
    }

    return results;
  }
}
