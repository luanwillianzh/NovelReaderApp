// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting (add intl to pubspec.yaml if not present)
import '../services/local_database_service.dart';
import 'chapter_content_screen.dart';
import '../models.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;

  @override
  void initState() {
    super.initState();
    // Manually refresh the stream when the screen initializes to fetch latest data
    _localDatabaseService.refreshHistoryStream();
  }

  /// Método para exibir um diálogo de confirmação antes de limpar o histórico
  Future<void> _confirmClearHistory() async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // Cores do AlertDialog para Material You
          backgroundColor: colorScheme.surfaceVariant,
          title: Text(
            'Limpar Histórico?',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          content: Text(
            'Tem certeza de que deseja limpar todo o histórico de leitura?',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: colorScheme.primary,
                ), // Cor primária do tema
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Limpar',
                style: TextStyle(
                  color: colorScheme.error,
                ), // Cor de erro do tema
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _clearHistory();
    }
  }

  /// Método para limpar o histórico de leitura
  void _clearHistory() async {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    try {
      await _localDatabaseService.clearAllHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Histórico limpo com sucesso!'),
          backgroundColor:
              colorScheme
                  .tertiary, // Uma cor de sucesso do Material You, ou green se preferir
          behavior: SnackBarBehavior.floating, // Comportamento flutuante
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ), // Arredondado
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao limpar histórico: $e'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtenha o ColorScheme do tema atual
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Usa a cor de fundo do tema
      appBar: AppBar(
        backgroundColor:
            colorScheme.surface, // Usa a cor de superfície para o AppBar
        foregroundColor: colorScheme.onSurface, // Cor do texto/ícones no AppBar
        elevation: 0, // Sem sombra para um look mais plano (AMOLED friendly)
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: colorScheme.onSurface,
            ), // Ícone arredondado e cor do tema
            tooltip: 'Limpar Histórico',
            onPressed: _confirmClearHistory, // Chama o método de confirmação
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _localDatabaseService.getHistoryStream(),
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
                      'Erro ao carregar histórico: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        _localDatabaseService
                            .refreshHistoryStream(); // Tenta recarregar
                      },
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ), // Ícone arredondado
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
                'Nenhum histórico de leitura encontrado.',
                style: TextStyle(
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            );
          } else {
            final historyItems = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: historyItems.length,
              itemBuilder: (context, index) {
                final item = historyItems[index];
                final novelId = item['novelId'] as String;
                final novelName = item['novelName'] as String;
                final chapterId = item['chapterId'] as String;
                final chapterTitle = item['chapterTitle'] as String;
                final int? readAtMilliseconds = item['readAt'] as int?;

                // O try-catch para o DateFormat é uma boa prática
                String formattedDate;
                try {
                  formattedDate =
                      readAtMilliseconds != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              readAtMilliseconds,
                            ),
                          )
                          : 'Data desconhecida';
                } catch (e) {
                  formattedDate = 'Data inválida';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      16.0,
                    ), // Mais arredondado para Material You
                  ),
                  color:
                      colorScheme
                          .surfaceVariant, // Usa surfaceVariant para o fundo do Card
                  child: InkWell(
                    onTap: () async {
                      try {
                        final novel = await ApiService().fetchNovel(novelId);
                        final initialChapterIndex = novel.chapters.indexWhere(
                          (c) => c.id == chapterId,
                        );
                        if (initialChapterIndex != -1) {
                          await Navigator.push(
                            // Use await aqui para garantir que a tela atualize se necessário
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChapterContentScreen(
                                    novelId: novelId,
                                    chapterId: chapterId,
                                    chapterTitle: chapterTitle,
                                    chapters: novel.chapters,
                                    initialChapterIndex: initialChapterIndex,
                                  ),
                            ),
                          );
                          // Atualiza o histórico após retornar, caso o usuário tenha lido mais ou avançado
                          _localDatabaseService.refreshHistoryStream();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Capítulo não encontrado na novel. A novel pode ter sido atualizada.',
                              ),
                              backgroundColor: colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao carregar novel: $e'),
                            backgroundColor: colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            novelName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  colorScheme.onSurface, // Cor do texto no tema
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            chapterTitle,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  colorScheme
                                      .onSurfaceVariant, // Cor mais suave
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Lido em: $formattedDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ), // Cor mais discreta para a data
                            ),
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
