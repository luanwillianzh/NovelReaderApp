// lib/screens/novel_detail_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'chapter_content_screen.dart';
import 'epub_downloader_screen.dart';
import 'dart:async';
import '../services/local_database_service.dart';
import 'genre_screen.dart'; // Importe a GenreScreen

class NovelDetailScreen extends StatefulWidget {
  final String novelId;

  const NovelDetailScreen({super.key, required this.novelId});

  @override
  State<NovelDetailScreen> createState() => _NovelDetailScreenState();
}

class _NovelDetailScreenState extends State<NovelDetailScreen> {
  late Future<Novel> _novelFuture;
  final ApiService _apiService = ApiService();
  final TextEditingController _chapterSearchController =
      TextEditingController();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  List<ChapterSummary> _originalChapters = [];
  List<ChapterSummary> _filteredChapters = [];
  bool _isChapterOrderReversed = false;
  bool _isFavorited = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchNovelAndFavorites();

    _chapterSearchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _filterAndSortChapters();
      });
    });
  }

  Future<void> _fetchNovelAndFavorites() async {
    setState(() {
      _novelFuture = _apiService.fetchNovel(widget.novelId);
    });
    _novelFuture
        .then((novel) async {
          final isFav = await _localDb.isNovelFavorited(novel.id);
          setState(() {
            _originalChapters = novel.chapters;
            _filteredChapters = List.from(_originalChapters);
            _isFavorited = isFav;
          });
        })
        .catchError((error) {
          print('Failed to load novel or favorite status: $error');
        });
  }

  @override
  void dispose() {
    _chapterSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _filterAndSortChapters() {
    final query = _chapterSearchController.text.toLowerCase();
    List<ChapterSummary> tempFilteredList;
    if (query.isEmpty) {
      tempFilteredList = List.from(_originalChapters);
    } else {
      tempFilteredList =
          _originalChapters
              .where((chapter) => chapter.title.toLowerCase().contains(query))
              .toList();
    }

    setState(() {
      if (_isChapterOrderReversed) {
        _filteredChapters = tempFilteredList.reversed.toList();
      } else {
        _filteredChapters = tempFilteredList;
      }
    });
  }

  void _toggleChapterOrder() {
    setState(() {
      _isChapterOrderReversed = !_isChapterOrderReversed;
      _filterAndSortChapters();
    });
  }

  void _toggleFavorite(Novel novel) async {
    await _localDb.toggleFavorite(novel);
    final isFav = await _localDb.isNovelFavorited(novel.id);
    setState(() {
      _isFavorited = isFav;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorited ? 'Adicionado à biblioteca!' : 'Removido da biblioteca.',
        ),
        backgroundColor:
            _isFavorited
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
        title: const Text('Detalhes da Novel'),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          FutureBuilder<Novel>(
            future: _novelFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                final novel = snapshot.data!;
                return IconButton(
                  onPressed: () => _toggleFavorite(novel),
                  icon: Icon(
                    _isFavorited
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        _isFavorited
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                  ),
                  tooltip:
                      _isFavorited
                          ? 'Remover da biblioteca'
                          : 'Adicionar à biblioteca',
                );
              }
              return Container();
            },
          ),
        ],
      ),
      body: FutureBuilder<Novel>(
        future: _novelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error, colorScheme);
          } else if (!snapshot.hasData) {
            return Center(
              child: Text(
                'Novel não encontrada.',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            );
          } else {
            final novel = snapshot.data!;
            return CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: _buildNovelCover(
                              novel.cover,
                              colorScheme,
                              width: 160,
                              height: 240,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            novel.nome,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          _buildChapterCount(
                            novel.chapters.length,
                            colorScheme,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            novel.desc,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (novel.genres.isNotEmpty)
                            _buildGenres(
                              novel.genres,
                              colorScheme,
                            ), // Chama _buildGenres
                          const SizedBox(height: 16),
                          _buildActionButtons(novel, colorScheme),
                          const SizedBox(height: 24),
                          _buildChaptersHeader(colorScheme),
                          const SizedBox(height: 16),
                          _buildChapterSearchField(colorScheme),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ]),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final chapter = _filteredChapters[index];
                      final originalIndex = _originalChapters.indexOf(chapter);
                      return Column(
                        children: [
                          ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            tileColor: colorScheme.surfaceContainerHighest,
                            title: Text(
                              chapter.title,
                              style: TextStyle(color: colorScheme.onSurface),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChapterContentScreen(
                                        novelId: novel.id,
                                        chapterId: chapter.id,
                                        chapterTitle: chapter.title,
                                        chapters: _originalChapters,
                                        initialChapterIndex: originalIndex,
                                      ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }, childCount: _filteredChapters.length),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            );
          }
        },
      ),
    );
  }

  /// Builds the error state widget.
  Widget _buildErrorState(Object? error, ColorScheme colorScheme) {
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
              'Erro: $error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.error, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchNovelAndFavorites,
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
  }

  /// Builds the novel cover widget.
  Widget _buildNovelCover(
    String coverUrl,
    ColorScheme colorScheme, {
    double width = 200,
    double height = 300,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          coverUrl,
          fit: BoxFit.cover,
          cacheWidth: width.toInt(),
          cacheHeight: height.toInt(),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: colorScheme.secondaryContainer,
              child: Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  size: width / 2.5,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: colorScheme.surfaceContainerHighest,
              child: Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the chapter count widget.
  Widget _buildChapterCount(int count, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '$count capítulos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the genres widget.
  Widget _buildGenres(List<Genre> genres, ColorScheme colorScheme) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children:
          genres.map((genre) {
            return GestureDetector(
              // Adicionado GestureDetector
              onTap: () {
                // Navega para a GenreScreen ao clicar no gênero
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => GenreScreen(
                          genre: genre.name,
                        ), // Passa o nome do gênero
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(999),
                  color: colorScheme.surfaceContainerHighest,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  genre.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  /// Builds the action buttons (Start Reading, Download EPUB).
  Widget _buildActionButtons(Novel novel, ColorScheme colorScheme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _localDb.getHistory(),
      builder: (context, snapshot) {
        String buttonText = 'Ler Agora';
        ChapterSummary? continueChapter;

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final history = snapshot.data!;
          final lastRead = history.firstWhere(
            (entry) => entry['novelId'] == novel.id,
            orElse: () => {},
          );
          if (lastRead.isNotEmpty) {
            buttonText = 'Continuar';
            continueChapter = novel.chapters.firstWhere(
              (chapter) => chapter.id == lastRead['chapterId'],
              orElse: () => novel.chapters.first,
            );
          }
        }

        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chrome_reader_mode_rounded),
                label: Text(buttonText),
                onPressed: () {
                  if (novel.chapters.isNotEmpty) {
                    final chapter = continueChapter ?? novel.chapters.first;
                    final chapterIndex = novel.chapters.indexOf(chapter);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChapterContentScreen(
                              novelId: novel.id,
                              chapterId: chapter.id,
                              chapterTitle: chapter.title,
                              chapters: novel.chapters,
                              initialChapterIndex: chapterIndex,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Nenhum capítulo disponível para leitura.',
                        ),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Baixar EPUB'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EpubDownloaderScreen(novel: novel),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the header for the chapters section.
  Widget _buildChaptersHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Capítulos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        IconButton(
          icon: Icon(
            _isChapterOrderReversed
                ? Icons.sort_rounded
                : Icons.sort_by_alpha_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: _toggleChapterOrder,
          tooltip:
              _isChapterOrderReversed ? 'Ordem Original' : 'Inverter Ordem',
        ),
      ],
    );
  }

  /// Builds the chapter search text field.
  Widget _buildChapterSearchField(ColorScheme colorScheme) {
    return TextField(
      controller: _chapterSearchController,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Buscar capítulo...',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
    );
  }
}

// O widget ExpandableText não é mais necessário para a descrição principal neste layout.
// Se não for usado em nenhum outro lugar, você pode removê-lo completamente.
/*
class ExpandableText extends StatefulWidget {
  // ... (código do ExpandableText)
}
*/
