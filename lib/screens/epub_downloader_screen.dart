// lib/screens/epub_downloader_screen.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // Import Uint8List
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Mantido, mas file_picker é preferível para salvar
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart'; // For saving the file
import '../models.dart';
import '../services/api_service.dart';

class EpubDownloaderScreen extends StatefulWidget {
  final Novel novel;

  const EpubDownloaderScreen({super.key, required this.novel});

  @override
  State<EpubDownloaderScreen> createState() => _EpubDownloaderScreenState();
}

class _EpubDownloaderScreenState extends State<EpubDownloaderScreen> {
  int? _startChapterIndex;
  int? _endChapterIndex;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  bool _isGenerating = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Definir o capítulo inicial como 1 e o final como o último capítulo por padrão
    _startChapterIndex = 0; // O índice é baseado em 0, então o 1º capítulo é 0
    _endChapterIndex = widget.novel.chapters.length - 1;
  }

  Future<void> _generateEpub() async {
    if (_startChapterIndex == null || _endChapterIndex == null) {
      _showSnackBar(
        'Por favor, selecione os capítulos de início e fim.',
        isError: true,
      );
      return;
    }
    if (_startChapterIndex! > _endChapterIndex!) {
      _showSnackBar(
        'O capítulo inicial não pode ser maior que o final.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Iniciando download...';
    });

    try {
      final selectedChapters = widget.novel.chapters.sublist(
        _startChapterIndex!,
        _endChapterIndex! + 1,
      );
      final totalChapters = selectedChapters.length;

      final archive = Archive();

      // Add mimetype file (must be first and uncompressed)
      archive.addFile(
        ArchiveFile.noCompress(
          'mimetype',
          'application/epub+zip'.length,
          'application/epub+zip'.codeUnits,
        ),
      );

      // Add META-INF/container.xml
      archive.addFile(
        ArchiveFile(
          'META-INF/container.xml',
          '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>'''.trim().length,
          '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>'''.trim().codeUnits,
        ),
      );

      // Fetch chapter contents and add to archive
      final List<Map<String, String>> chapterXhtmls = [];
      for (int i = 0; i < totalChapters; i++) {
        final chapterSummary = selectedChapters[i];
        try {
          final chapterContent = await _apiService.fetchChapter(
            widget.novel.id,
            chapterSummary.id,
          );
          final xhtmlContent = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="pt">
<head><title>${chapterSummary.title}</title></head>
<body><h1>${chapterContent.title}</h1><h2>${chapterContent.subtitle}</h2><hr />${chapterContent.content}</body>
</html>''';
          chapterXhtmls.add({
            'slug': chapterSummary.id,
            'title': chapterSummary.title,
            'xhtml': xhtmlContent,
          });
          archive.addFile(
            ArchiveFile(
              'OEBPS/${chapterSummary.id}.xhtml',
              utf8.encode(xhtmlContent).length,
              utf8.encode(xhtmlContent),
            ),
          );

          setState(() {
            _downloadProgress = (i + 1) / totalChapters;
            _downloadStatus =
                'Baixando capítulo ${i + 1} de $totalChapters (${(_downloadProgress * 100).toInt()}%)';
          });
        } catch (e) {
          print('Error fetching chapter ${chapterSummary.title}: $e');
          // Optionally, skip this chapter or add a placeholder
        }
      }

      // Add cover image if available
      String coverManifestItem = '';
      if (widget.novel.cover.isNotEmpty) {
        try {
          final coverResponse = await http.get(
            Uri.parse(
              'https://novel-reader-flask.vercel.app/proxy-cover/?url=${Uri.encodeComponent(widget.novel.cover)}',
            ),
          );
          if (coverResponse.statusCode == 200) {
            archive.addFile(
              ArchiveFile(
                'OEBPS/cover.jpg',
                coverResponse.bodyBytes.length,
                coverResponse.bodyBytes,
              ),
            );
            coverManifestItem =
                '<item id="cover" href="cover.jpg" media-type="image/jpeg" properties="cover-image"/>';
          } else {
            print('Failed to load cover image: ${coverResponse.statusCode}');
          }
        } catch (e) {
          print('Error fetching cover image: $e');
        }
      }

      // Generate manifest and spine for content.opf
      String manifestItems = '';
      String spineItems = '';
      String tocNavPoints = '';

      for (int i = 0; i < chapterXhtmls.length; i++) {
        final ch = chapterXhtmls[i];
        manifestItems +=
            '<item id="${ch['slug']}" href="${ch['slug']}.xhtml" media-type="application/xhtml+xml"/>';
        spineItems += '<itemref idref="${ch['slug']}"/>';
        tocNavPoints += '''
      <navPoint id="navPoint-${i + 1}" playOrder="${i + 1}">
        <navLabel><text>${ch['title']}</text></navLabel>
        <content src="${ch['slug']}.xhtml"/>
      </navPoint>''';
      }

      // Add content.opf
      final opfContent =
          '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookId">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="BookId">${widget.novel.nome.toLowerCase().replaceAll(' ', '-')}</dc:identifier>
    <dc:title>${widget.novel.nome}</dc:title>
    <dc:language>pt</dc:language>
    <dc:description>${widget.novel.desc}</dc:description>
    <dc:subject>${widget.novel.genres.map((g) => g.name).join(', ')}</dc:subject>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    $coverManifestItem
    $manifestItems
  </manifest>
  <spine toc="ncx">
    $spineItems
  </spine>
</package>'''.trim();
      archive.addFile(
        ArchiveFile(
          'OEBPS/content.opf',
          utf8.encode(opfContent).length,
          utf8.encode(opfContent),
        ),
      );

      // Add toc.ncx
      final ncxContent =
          '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN"
  "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="${widget.novel.nome.toLowerCase().replaceAll(' ', '-')}" />
  </head>
  <docTitle><text>${widget.novel.nome}</text></docTitle>
  <navMap>
    $tocNavPoints
  </navMap>
</ncx>'''.trim();
      archive.addFile(
        ArchiveFile(
          'OEBPS/toc.ncx',
          utf8.encode(ncxContent).length,
          utf8.encode(ncxContent),
        ),
      );

      setState(() {
        _downloadStatus = 'Compactando EPUB...';
      });

      final zipData = ZipEncoder().encode(archive);
      final epubBytes = Uint8List.fromList(zipData);

      setState(() {
        _downloadStatus = 'Salvando arquivo...';
      });

      // Use file_picker to let the user select a save location, passing bytes directly
      final String fileName = '${widget.novel.nome.replaceAll(' ', '_')}.epub';
      String? outputPath = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['epub'],
        bytes: epubBytes, // Pass the bytes directly here
      );

      if (outputPath != null) {
        setState(() {
          _downloadStatus = 'EPUB gerado com sucesso!';
          _downloadProgress = 1.0;
        });
        _showSnackBar('EPUB salvo em: $outputPath', isError: false);
      } else {
        setState(() {
          _downloadStatus = 'Download cancelado.';
          _downloadProgress = 0.0;
        });
        _showSnackBar('Download cancelado.', isError: true);
      }
    } catch (e) {
      setState(() {
        _downloadStatus = 'Erro ao gerar EPUB: $e';
        _downloadProgress = 0.0;
      });
      _showSnackBar('Erro ao gerar EPUB: $e', isError: true);
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // Adicionando um parâmetro `isError` para a SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor:
            isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.tertiary,
        behavior: SnackBarBehavior.floating, // Estilo Material You
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ), // Estilo Material You
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Usa a cor de fundo do tema
      appBar: AppBar(
        backgroundColor:
            colorScheme.surface, // Usa a cor de superfície para o AppBar
        foregroundColor: colorScheme.onSurface, // Cor do texto/ícones no AppBar
        elevation: 0, // Sem sombra para um look mais plano (AMOLED friendly)
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onSurface,
          ), // Ícone arredondado e cor do tema
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Baixar EPUB',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título da Novel
            Text(
              'Baixar ${widget.novel.nome}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface, // Cor do texto do tema
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Dropdown de Capítulo Inicial
            _buildChapterDropdown(colorScheme, _startChapterIndex, (newValue) {
              setState(() {
                _startChapterIndex = newValue;
                if (_startChapterIndex! > _endChapterIndex!) {
                  _endChapterIndex = _startChapterIndex;
                }
              });
            }, 'Capítulo Inicial'),
            const SizedBox(height: 12),
            // Dropdown de Capítulo Final
            _buildChapterDropdown(colorScheme, _endChapterIndex, (newValue) {
              setState(() {
                _endChapterIndex = newValue;
                if (_endChapterIndex! < _startChapterIndex!) {
                  _startChapterIndex = _endChapterIndex;
                }
              });
            }, 'Capítulo Final'),
            const SizedBox(height: 24),
            // Seção de Progresso ou Botão de Gerar
            _isGenerating
                ? Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest, // Cor de fundo do tema
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary, // Cor de progresso do tema
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Arredondar a barra de progresso
                    ),
                    const SizedBox(height: 12), // Mais espaçamento
                    Text(
                      _downloadStatus,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 14,
                      ), // Cor do texto do tema
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
                : ElevatedButton.icon(
                  // Usando ElevatedButton.icon
                  onPressed: _generateEpub,
                  icon: Icon(
                    Icons.download_rounded,
                    color: colorScheme.onPrimary,
                  ), // Ícone arredondado
                  label: const Text('Gerar EPUB'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colorScheme.primary, // Cor primária do tema
                    foregroundColor:
                        colorScheme.onPrimary, // Cor do texto do tema
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Mais arredondado
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18, // Um pouco mais de padding vertical
                    ),
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ), // Full width button
                    elevation: 0, // Sem sombra para look Material You
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // Widget separado para construir os Dropdowns
  Widget _buildChapterDropdown(
    ColorScheme colorScheme,
    int? currentValue,
    ValueChanged<int?> onChanged,
    String hintText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Aumenta padding
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.4), // Fundo do tema
        borderRadius: BorderRadius.circular(16), // Mais arredondado
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.5),
        ), // Borda do tema
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: currentValue,
          dropdownColor: colorScheme.surface, // Cor do dropdown do tema
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
          ), // Cor do texto do tema
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: colorScheme.onSurfaceVariant,
          ), // Ícone do tema
          onChanged: onChanged,
          items: List.generate(widget.novel.chapters.length, (index) {
            return DropdownMenuItem(
              value: index,
              child: Text(
                'Capítulo ${index + 1}: ${widget.novel.chapters[index].title}', // Melhorando o texto
              ),
            );
          }),
          hint: Text(
            hintText,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}
