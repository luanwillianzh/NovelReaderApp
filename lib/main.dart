import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necessário para MethodChannel
// Importação mantida
// Importação mantida

// Substitua pelos seus imports reais para as telas
import 'screens/novel_detail_screen.dart';
import 'screens/home_screen.dart'; // Sua tela inicial
import 'services/local_database_service.dart'; // Serviço de banco de dados local

void main() async {
  // Garante que os widgets do Flutter estejam inicializados antes de qualquer operação assíncrona
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o serviço de banco de dados local
  await LocalDatabaseService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Define o MethodChannel para comunicação com o código nativo.
  // O nome do canal ('com.thefool.novelreader/deep_linking') deve ser o mesmo usado no nativo.
  static const platform = MethodChannel('com.thefool.novelreader/deep_linking');

  @override
  void initState() {
    super.initState();
    // Configura o manipulador de chamadas de método para receber dados do nativo.
    platform.setMethodCallHandler(_handleMethodCall);
  }

  /// Manipula as chamadas de método recebidas do código nativo.
  /// Espera o método 'handleDeepLink' com o argumento 'novel_id'.
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'handleDeepLink') {
      // Converte os argumentos para um mapa de String para dynamic, garantindo segurança de tipo.
      final Map<String, dynamic> args = Map<String, dynamic>.from(
        call.arguments,
      );
      final String? novelId = args['novel_id'];
      // A lógica para 'chapter_id' foi removida, pois não será mais usada para navegação direta.

      // Verifica se um novelId foi fornecido
      if (novelId != null) {
        // Agora, se novelId for fornecido, sempre navega para a tela de detalhes da novel.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NovelDetailScreen(novelId: novelId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novel App',
      // --- Configuração do Tema Material You ---
      theme: ThemeData(
        // Habilita o Material 3, essencial para o Material You
        useMaterial3: true,
        // Define o tema como escuro. O Material You irá gerar um ColorScheme escuro
        brightness: Brightness.dark,
        // Define uma "semente" de cor. O Material You irá gerar todo o ColorScheme
        // com base nessa cor, criando uma paleta harmoniosa.
        // Usei Colors.blueGrey aqui, que se alinha com o que você já tinha,
        // mas você pode experimentar com outras cores para ver o efeito.
        colorSchemeSeed: Colors.blueGrey,

        // A propriedade primarySwatch não é mais a forma preferencial de definir
        // cores no Material 3, use colorSchemeSeed.
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Mantendo a fonte Inter
        // A cor de fundo principal do Scaffold será definida pelo ColorScheme.background
        // do tema gerado, que para o modo escuro será um cinza escuro.
        // Se você ABSOLUTAMENTE precisa de preto puro para AMOLED,
        // pode sobrescrever isso, mas vai contra a filosofia do Material You
        // de usar tons de cinza escuro para evitar "queima" de tela e dar profundidade.
        // Se ainda quiser preto puro, descomente a linha abaixo:
        // scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          // As cores do AppBar agora virão do ColorScheme.
          // surface para o fundo e onSurface para o texto/ícones.
          // Se você ABSOLUTAMENTE precisa de preto puro, descomente as linhas abaixo:
          // backgroundColor: Colors.black,
          // foregroundColor: Colors.white,
          centerTitle: false, // Mantendo à esquerda como no Mihon
          elevation: 0, // Sem sombra para um look mais plano (AMOLED friendly)
          // Formato do AppBar não é muito comum no Material You ou Mihon,
          // mas se você gosta, pode manter. Removido para simplificar com o Mihon.
          // shape: RoundedRectangleBorder(
          //   borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
          // ),
        ),
        cardTheme: CardThemeData(
          // As cores do Card agora virão do ColorScheme.surfaceVariant ou surface
          // para dar mais profundidade e usar a paleta do Material You.
          // Se você ABSOLUTAMENTE precisa de preto puro, descomente:
          // color: Colors.black,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              16,
            ), // Mais arredondado para Material You
          ),
          elevation: 5,
        ),
        // buttonTheme é uma propriedade legada, use ElevatedButton.styleFrom etc.
        // para estilizar botões individualmente, ou os temas de botões do Material 3
        // como ElevatedButtonThemeData, TextButtonThemeData, etc.
        // Para a barra de busca, já fizemos as alterações diretamente no TextField.

        // TextTheme: as cores do texto serão automaticamente ajustadas pelo ColorScheme.
        // Manter o fontFamily é bom, mas as cores já virão do tema.
        // Se precisar de overrides específicos para casos muito particulares,
        // pode usar TextTheme, mas evite sobrescrever todas as cores se quiser
        // a flexibilidade do Material You.
        // textTheme: const TextTheme(
        //   bodyLarge: TextStyle(color: Colors.white70),
        //   bodyMedium: TextStyle(color: Colors.white60),
        //   titleLarge: TextStyle(color: Colors.white),
        //   titleMedium: TextStyle(color: Colors.white),
        //   titleSmall: TextStyle(color: Colors.white54),
        // ),

        // IconTheme: as cores dos ícones também serão gerenciadas pelo ColorScheme.
        // Mas você pode definir um padrão se quiser.
        iconTheme: IconThemeData(
          color: Colors.blueGrey[200], // Ainda um bom padrão para o tema escuro
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
