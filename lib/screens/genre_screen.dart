// lib/screens/genre_screen.dart
import 'package:flutter/material.dart';
import '../models.dart'; // Certifique-se de que os modelos estão corretos
import '../services/api_service.dart'; // Importe o ApiService
import 'novel_detail_screen.dart'; // Para navegar para os detalhes da novel

class GenreScreen extends StatefulWidget {
  final String genre; // Parâmetro para o gênero

  const GenreScreen({super.key, required this.genre});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  late Future<List<dynamic>> _novelsByGenreFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Inicializa o Future para buscar novels pelo gênero
    _novelsByGenreFuture = _apiService.fetchByGenre(widget.genre);
  }

  // Método para recarregar a lista (útil para o botão de tentar novamente)
  void _reloadNovels() {
    setState(() {
      _novelsByGenreFuture = _apiService.fetchByGenre(widget.genre);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          widget.genre, // Título da AppBar é o nome do gênero
          style: TextStyle(color: colorScheme.onSurface),
        ),
        centerTitle: true,
        leading: IconButton(
          // Adiciona um botão de voltar
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _novelsByGenreFuture, // Usa o Future do API Service
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
                      'Erro ao carregar novels de ${widget.genre}: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed:
                          _reloadNovels, // Tenta recarregar ao pressionar
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
                'Nenhuma novel encontrada para o gênero ${widget.genre}.',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            );
          } else {
            final novelsByGenre = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 2 / 3.5, // Mantém a proporção com descrição
              ),
              itemCount: novelsByGenre.length,
              itemBuilder: (context, index) {
                final novel = novelsByGenre[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => NovelDetailScreen(novelId: novel.url),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Image.network(
                              novel.cover,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colorScheme.secondaryContainer,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image_rounded,
                                      color: colorScheme.onSecondaryContainer,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            8.0,
                            8.0,
                            8.0,
                            4.0,
                          ),
                          child: Text(
                            novel.nome,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Removida a descrição da novel, pois Lancamento não tem 'desc'
                        // se precisar, fetch novel.desc usando novel.url e passar como param
                        // ou carregar a novel completa aqui (menos eficiente para listas grandes)
                        // A propriedade 'desc' não existe no modelo Lancamento, apenas em Novel.
                        // Para exibir a descrição aqui, você precisaria:
                        // 1. Alterar o modelo Lancamento para incluir 'desc', ou
                        // 2. Fazer uma chamada adicional à API (fetchNovel) para cada item,
                        //    o que não é eficiente para um grid.
                        // Por enquanto, vamos omitir a descrição, como na ExploreScreen.
                      ],
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
