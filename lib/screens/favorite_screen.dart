// lib/screens/favorite_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/local_database_service.dart';
import 'novel_detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;

  @override
  void initState() {
    super.initState();
    // Manually refresh the stream when the screen initializes to fetch latest data
    _localDatabaseService.refreshFavoritesStream();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenha o ColorScheme do tema atual
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Usa a cor de fundo do tema
      body: StreamBuilder<List<Novel>>(
        stream: _localDatabaseService.getFavoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ), // Cor do primário do tema
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded, // Ícone arredondado
                      color: colorScheme.error, // Cor de erro do tema
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Erro ao carregar favoritos: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        _localDatabaseService
                            .refreshFavoritesStream(); // Tenta recarregar
                      },
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
                'Nenhuma novel na sua biblioteca.', // Texto atualizado
                style: TextStyle(
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            );
          } else {
            final favoriteNovels = snapshot.data!;
            // --- Alteração principal: Usando GridView.builder ---
            return GridView.builder(
              padding: const EdgeInsets.all(16.0), // Padding do grid
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    2, // 2 colunas, padrão para Mihon e boa visualização
                crossAxisSpacing: 16.0, // Espaçamento horizontal
                mainAxisSpacing: 16.0, // Espaçamento vertical
                childAspectRatio:
                    2 / 3.5, // Proporção da capa, ajustada para caber texto
              ),
              itemCount: favoriteNovels.length,
              itemBuilder: (context, index) {
                final novel = favoriteNovels[index];
                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => NovelDetailScreen(novelId: novel.id),
                      ),
                    );
                    // Atualiza a lista quando retornar da tela de detalhes
                    _localDatabaseService.refreshFavoritesStream();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceVariant, // Fundo do item do grid
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Bordas arredondadas
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(
                            0.15,
                          ), // Sombra sutil
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
                            top: Radius.circular(
                              16,
                            ), // Arredondamento superior da imagem
                          ),
                          child: AspectRatio(
                            aspectRatio:
                                2 /
                                3, // Proporção da imagem (capa de mangá/novel)
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
                                  color: colorScheme.surfaceVariant,
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
                            maxLines: 2, // Permite duas linhas para o nome
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Removida a descrição longa para um layout mais limpo de grid
                        // Você pode adicionar um texto menor, como o último capítulo lido, se disponível no modelo Novel
                        // Se você quiser mostrar a descrição, o layout de lista original pode ser melhor.
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
