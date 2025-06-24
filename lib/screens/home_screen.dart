// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'novel_detail_screen.dart';
import 'favorite_screen.dart'; // Import FavoriteScreen
import 'history_screen.dart'; // Import HistoryScreen
import 'categories_screen.dart';

// TELAS DE TESTE PARA A NAVEGAÇÃO INFERIOR (MANTIDAS SE ESTIVEREM EM SEPARADO)
// Se você já tem estes arquivos, não precisa manter as classes aqui.
// Removendo ExploreScreen e MoreScreen daqui, assumindo que são arquivos separados.
// Se não forem, você pode descomentar e ajustar.

/*
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tela de Explorar',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
*/
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tela Mais (Configurações, etc.)',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}

// FIM DAS TELAS DE TESTE

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista de widgets para a navegação inferior
  // Nova ordem: Biblioteca, Explorar, Histórico, Categorias, Mais
  static final List<Widget> _widgetOptions = <Widget>[
    const FavoriteScreen(), // 0: Biblioteca
    ExploreContent(), // 1: Explorar
    const HistoryScreen(), // 2: Histórico
    const CategoriesScreen(), // 3: Categorias (NOVO)
    const MoreScreen(), // 4: Mais
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Helper para obter o título da AppBar baseado no índice selecionado
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Minha Biblioteca';
      case 1:
        return 'Explorar Novels';
      case 2:
        return 'Histórico de Leitura';
      case 3: // NOVO CASO
        return 'Categorias';
      case 4:
        return 'Mais Opções';
      default:
        return 'Leitor de Novels';
    }
  }

  // Helper para obter o subtítulo da AppBar baseado no índice selecionado
  String _getAppBarSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Suas novels favoritas';
      case 1:
        return 'Descubra e leia novas novels';
      case 2:
        return 'Relembre suas últimas leituras';
      case 3: // NOVO CASO
        return 'Encontre novels por gênero';
      case 4:
        return 'Configurações e outras opções';
      default:
        return 'Descubra e leia suas novels favoritas';
    }
  }

  // Helper para obter o ícone principal da AppBar baseado no índice selecionado
  IconData _getAppBarIcon() {
    switch (_selectedIndex) {
      case 0:
        return Icons.collections_bookmark_rounded; // Biblioteca
      case 1:
        return Icons.explore_rounded; // Explorar
      case 2:
        return Icons.history_rounded; // Histórico
      case 3: // NOVO CASO
        return Icons.category_rounded; // Ícone para Categorias
      case 4:
        return Icons.more_horiz_rounded; // Mais
      default:
        return Icons.library_books;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            // Ao tocar no título da AppBar, volta para a tela "Explorar" (índice 1)
            setState(() {
              _selectedIndex = 1;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getAppBarIcon(), // Ícone dinâmico
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getAppBarTitle(), // Título dinâmico
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                _getAppBarSubtitle(), // Subtítulo dinâmico
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        actions: [],
      ),
      body: SafeArea(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        animationDuration: const Duration(milliseconds: 500),
        indicatorColor: colorScheme.secondaryContainer,
        surfaceTintColor: colorScheme.surfaceTint,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: Icon(
              Icons.collections_bookmark_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.collections_bookmark_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Biblioteca',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.explore_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.explore_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.history_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.history_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Histórico',
          ),
          // --- NOVO ITEM: Categorias ---
          NavigationDestination(
            icon: Icon(
              Icons.category_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.category_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Categorias',
          ),
          // --- FIM NOVO ITEM ---
          NavigationDestination(
            icon: Icon(
              Icons.more_horiz_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            selectedIcon: Icon(
              Icons.more_horiz_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

// Renomeado de _HomeContent para ExploreContent
class ExploreContent extends StatefulWidget {
  @override
  _ExploreContentState createState() => _ExploreContentState();
}

class _ExploreContentState extends State<ExploreContent> {
  late Future<List<Lancamento>> _lancamentosFuture;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _lancamentosFuture = _apiService.fetchLancamentos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _lancamentosFuture = _apiService.fetchLancamentos();
      } else {
        _lancamentosFuture = _apiService.searchLancamentos(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar novels...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _performSearch(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Buscar'),
                  ),
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
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Lancamento>>(
              future: _lancamentosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
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
                            'Erro: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _lancamentosFuture =
                                    _apiService.fetchLancamentos();
                              });
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
                      'Nenhuma novel encontrada.',
                      style: TextStyle(
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  );
                } else {
                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                          childAspectRatio: 2 / 3.5,
                        ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final lancamento = snapshot.data![index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => NovelDetailScreen(
                                    novelId: lancamento.url,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
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
                                    'https://novel-reader-flask.vercel.app/proxy-cover/?url=${Uri.encodeComponent(lancamento.cover)}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: colorScheme.secondaryContainer,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            size: 50,
                                            color:
                                                colorScheme
                                                    .onSecondaryContainer,
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
                                                loadingProgress
                                                            .expectedTotalBytes !=
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
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  lancamento.nome,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
