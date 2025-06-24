// lib/screens/chapter_content_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/local_database_service.dart';

class ChapterContentScreen extends StatefulWidget {
  final String novelId;
  final String chapterId;
  final String chapterTitle;
  final List<ChapterSummary> chapters;
  final int initialChapterIndex;

  const ChapterContentScreen({
    super.key,
    required this.novelId,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapters,
    required this.initialChapterIndex,
  });

  @override
  State<ChapterContentScreen> createState() => _ChapterContentScreenState();
}

class _ChapterContentScreenState extends State<ChapterContentScreen> {
  late Future<Chapter> _chapterFuture;
  final ApiService _apiService = ApiService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;
  late int _currentChapterIndex;
  double _fontSize = 16.0;
  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 32.0;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex;
    _fetchChapterContent();
    _loadFontSize();
  }

  Future<void> _addChapterToHistory() async {
    try {
      final novel = await _apiService.fetchNovel(widget.novelId);
      final chapterSummary = novel.chapters[_currentChapterIndex];
      _localDatabaseService.addChapterToHistory(novel, chapterSummary);
    } catch (e) {
      print('Error logging chapter to history: $e');
    }
  }

  void _fetchChapterContent() {
    setState(() {
      _chapterFuture = _apiService.fetchChapter(
        widget.novelId,
        widget.chapters[_currentChapterIndex].id,
      );
    });
    _chapterFuture.then((_) => _addChapterToHistory());
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('reader_font_size') ?? 16.0;
      if (_fontSize < _minFontSize) _fontSize = _minFontSize;
      if (_fontSize > _maxFontSize) _fontSize = _maxFontSize;
    });
  }

  Future<void> _saveFontSize(double newSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reader_font_size', newSize);
  }

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < _maxFontSize) {
        _fontSize += 2.0;
        _saveFontSize(_fontSize);
      }
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > _minFontSize) {
        _fontSize -= 2.0;
        _saveFontSize(_fontSize);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obter o ColorScheme do tema atual.
    // Garanta que seu MaterialApp esteja configurado com useMaterial3: true e um ColorScheme.fromSeed.
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final prevChapter =
        _currentChapterIndex > 0
            ? widget.chapters[_currentChapterIndex - 1]
            : null;
    final nextChapter =
        _currentChapterIndex < widget.chapters.length - 1
            ? widget.chapters[_currentChapterIndex + 1]
            : null;

    return Scaffold(
      // Usar a cor de fundo do ColorScheme para consistência com Material You.
      // surfaceContainerHighest é uma boa opção para fundos escuros em AMOLED.
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        // Pure black app bar para AMOLED
        backgroundColor: Colors.black,
        foregroundColor: colorScheme.onSurface, // Texto e ícones contrastantes
        elevation: 0, // Sem sombra para AMOLED
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Ícone padrão do Material Design
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: 'Voltar para novel',
        ),
        title: Text(
          'Voltar para novel',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant, // Cor mais suave para o título
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<Chapter>(
        future: _chapterFuture,
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
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _fetchChapterContent,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            colorScheme.primary, // Cor primária do tema
                        foregroundColor:
                            colorScheme
                                .onPrimary, // Texto contrastante na cor primária
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
          } else if (!snapshot.hasData) {
            return Center(
              child: Text(
                'Conteúdo do capítulo não encontrado.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            );
          } else {
            final chapter = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: SelectionArea(
                    // NEW: Envolve o conteúdo principal com SelectionArea
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            chapter.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  colorScheme
                                      .onSurface, // Cor principal do texto
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            chapter.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color:
                                  colorScheme
                                      .onSurfaceVariant, // Cor mais suave para o subtítulo
                            ),
                          ),
                          Divider(
                            height: 30,
                            thickness: 1.5,
                            color: colorScheme.outlineVariant, // Divisor sutil
                          ),
                          Html(
                            data: chapter.content,
                            style: {
                              "p": Style(
                                fontSize: FontSize(_fontSize),
                                lineHeight: LineHeight.em(1.5),
                                textAlign: TextAlign.justify,
                                color: colorScheme.onSurface,
                              ),
                              "body": Style(color: colorScheme.onSurface),
                              "h1": Style(color: colorScheme.onSurface),
                              "h2": Style(color: colorScheme.onSurface),
                              "h3": Style(color: colorScheme.onSurface),
                              "h4": Style(color: colorScheme.onSurface),
                              "h5": Style(color: colorScheme.onSurface),
                              "h6": Style(color: colorScheme.onSurface),
                              "a": Style(
                                color: colorScheme.primary,
                              ), // Links com a cor primária
                              "img": Style(display: Display.block),
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Footer (sticky bottom)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant,
                      ), // Borda para o rodapé
                    ),
                    color:
                        colorScheme
                            .surfaceContainer, // Um pouco mais claro que o fundo para diferenciação
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão Capítulo Anterior
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              prevChapter != null
                                  ? () {
                                    setState(() {
                                      _currentChapterIndex--;
                                    });
                                    _fetchChapterContent();
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                colorScheme
                                    .primaryContainer, // Cor do container primário
                            foregroundColor:
                                colorScheme
                                    .onPrimaryContainer, // Texto no container primário
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.arrow_back), // Ícone Material Design
                              SizedBox(width: 4),
                              Text('Anterior'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Controles de Fonte
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline,
                          ), // Borda com cor de outline
                          borderRadius: BorderRadius.circular(8),
                          color:
                              colorScheme
                                  .surfaceContainerHigh, // Um pouco mais escuro para os controles
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _decreaseFontSize,
                              icon: const Icon(Icons.remove),
                              color:
                                  _fontSize > _minFontSize
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(
                                        0.38,
                                      ), // Desabilitado
                              tooltip: 'Diminuir tamanho da fonte',
                            ),
                            Text(
                              '${_fontSize.toInt()}px',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            IconButton(
                              onPressed: _increaseFontSize,
                              icon: const Icon(Icons.add),
                              color:
                                  _fontSize < _maxFontSize
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurface.withOpacity(
                                        0.38,
                                      ), // Desabilitado
                              tooltip: 'Aumentar tamanho da fonte',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botão Próximo Capítulo
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              nextChapter != null
                                  ? () {
                                    setState(() {
                                      _currentChapterIndex++;
                                    });
                                    _fetchChapterContent();
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Próximo'),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                              ), // Ícone Material Design
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
