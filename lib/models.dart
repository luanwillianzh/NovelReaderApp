import 'dart:convert'; // For json.encode/decode if storing complex objects

class Lancamento {
  final String nome;
  final String url; // This 'url' is actually the novel_id
  final String cover;

  Lancamento({required this.nome, required this.url, required this.cover});

  factory Lancamento.fromJson(Map<String, dynamic> json) {
    return Lancamento(
      nome: json['nome'],
      url: json['url'],
      cover: json['cover'],
    );
  }
}

class GenreFilter {
  final String nome;
  final String url;
  final String cover;
  final List genres;

  GenreFilter({
    required this.nome,
    required this.url,
    required this.cover,
    required this.genres,
  });

  factory GenreFilter.fromJson(Map<String, dynamic> json) {
    return GenreFilter(
      nome: json['nome'],
      url: json['url'],
      cover: json['cover'],
      genres: json['genres'],
    );
  }
}

class Novel {
  final String id; // Added novel ID field
  final String nome;
  final String desc;
  final String cover;
  final List<Genre> genres;
  final List<ChapterSummary> chapters;

  Novel({
    required this.id, // Made ID required
    required this.nome,
    required this.desc,
    required this.cover,
    required this.genres,
    required this.chapters,
  });

  factory Novel.fromJson(Map<String, dynamic> json, String novelId) {
    var genresFromJson = json['genres'] as List;
    List<Genre> genreList =
        genresFromJson.map((i) => Genre.fromJson(i)).toList();

    var chaptersFromJson = json['chapters'] as List;
    List<ChapterSummary> chapterList =
        chaptersFromJson.map((i) => ChapterSummary.fromJson(i)).toList();

    return Novel(
      id: novelId, // Assigning the novelId passed from ApiService
      nome: json['nome'],
      desc: json['desc'],
      cover: json['cover'],
      genres: genreList,
      chapters: chapterList,
    );
  }

  // Convert Novel object to a map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'desc': desc,
      'cover': cover,
      // Store complex types (lists of objects) as JSON strings
      'genres': json.encode(genres.map((g) => [g.id, g.name]).toList()),
      'chapters': json.encode(chapters.map((c) => [c.title, c.id]).toList()),
    };
  }

  // Create Novel object from a map (SQLite data)
  factory Novel.fromMap(Map<String, dynamic> map) {
    List<dynamic> genresDecoded = json.decode(map['genres']);
    List<Genre> genreList =
        genresDecoded.map((g) => Genre.fromJson(g as List<dynamic>)).toList();

    List<dynamic> chaptersDecoded = json.decode(map['chapters']);
    List<ChapterSummary> chapterList =
        chaptersDecoded
            .map((c) => ChapterSummary.fromJson(c as List<dynamic>))
            .toList();

    return Novel(
      id: map['id'],
      nome: map['nome'],
      desc: map['desc'],
      cover: map['cover'],
      genres: genreList,
      chapters: chapterList,
    );
  }
}

class Genre {
  final String id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(List<dynamic> json) {
    return Genre(id: json[0], name: json[1]);
  }
}

class ChapterSummary {
  final String title;
  final String id; // This 'id' is actually the chapter_id

  ChapterSummary({required this.title, required this.id});

  factory ChapterSummary.fromJson(List<dynamic> json) {
    return ChapterSummary(title: json[0], id: json[1]);
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'id': id};
  }

  factory ChapterSummary.fromMap(Map<String, dynamic> map) {
    return ChapterSummary(title: map['title'], id: map['id']);
  }
}

class Chapter {
  final String title;
  final String subtitle;
  final String content;

  Chapter({required this.title, required this.subtitle, required this.content});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'],
      subtitle: json['subtitle'],
      content: json['content'],
    );
  }
}
