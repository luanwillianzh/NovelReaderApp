// lib/screens/categories_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert'; // Para decodificar JSON
import 'package:http/http.dart' as http; // Para requisições HTTP
import 'genre_screen.dart'; // Importe a GenreScreen

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Alterado o tipo do Future para List<Map<String, String>> para armazenar id e name
  late Future<List<Map<String, String>>> _genresFuture;

  @override
  void initState() {
    super.initState();
    _genresFuture = _fetchGenres();
  }

  // Método para buscar gêneros, esperando List<List<dynamic>> e mapeando para List<Map<String, String>>
  Future<List<Map<String, String>>> _fetchGenres() async {
    final response = await http.get(
      Uri.parse('https://novel-reader-flask.vercel.app/api/genres_list'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> result =
          data['resultado']; // result é List<List<dynamic>>

      // Mapeia cada lista interna [id, name] para um Map {'id': id, 'name': name}
      return result.map((genreItem) {
        if (genreItem is List && genreItem.length >= 2) {
          return {
            'id': genreItem[0].toString(),
            'name': genreItem[1].toString(),
          };
        }
        return {'id': '', 'name': 'Gênero Inválido'}; // Retorno de fallback
      }).toList();
    } else {
      throw Exception('Falha ao carregar gêneros: ${response.statusCode}');
    }
  }

  // Método para recarregar a lista de gêneros
  void _reloadGenres() {
    setState(() {
      _genresFuture = _fetchGenres();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      // Não temos AppBar aqui pois a HomeScreen já gerencia a AppBar
      body: FutureBuilder<List<Map<String, String>>>(
        // Tipo do FutureBuilder ajustado
        future: _genresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colorScheme.error,
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Erro ao carregar gêneros: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _reloadGenres,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Nenhum gênero encontrado.',
                style: TextStyle(
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            );
          } else {
            final genres = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genreItem = genres[index];
                final genreId = genreItem['id']!; // O ID do gênero
                final genreName = genreItem['name']!; // O nome a ser exibido

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 16.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  color: colorScheme.surfaceVariant,
                  child: InkWell(
                    onTap: () {
                      // Navega para a GenreScreen passando o ID do gênero
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => GenreScreen(
                                genre: genreName,
                              ), // Passa o ID aqui
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              genreName, // Mostra o nome do gênero
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
