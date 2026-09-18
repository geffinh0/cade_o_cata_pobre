import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/favoritos_dao.dart';
import 'providers/transporte_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'services/api_service.dart';
import 'services/realtime_service.dart';
import 'theme/app_typography.dart';

/// Ponto de Entrada do Aplicativo Móvel (Sistemas Distribuídos)
///
/// Injeta as dependências da arquitetura distribuída:
/// 1. ApiService (Cliente REST - Gateway Pattern)
/// 2. RealtimeService (Cliente WebSocket Socket.IO - Pub/Sub Pattern)
/// 3. FavoritosDao (Persistência Local Offline-First)
/// 4. TransporteProvider (Gerenciador de Estado Global Reativo)
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Detecção inteligente da URL padrão com base na plataforma de execução
  String baseUrlInicial = 'http://localhost:3000';
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    baseUrlInicial = 'http://10.0.2.2:3000'; // Alias do Android Emulator para o localhost do host
  }

  final apiService = ApiService(baseUrl: baseUrlInicial);
  final realtimeService = RealtimeService();
  final favoritosDao = FavoritosDao();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransporteProvider(
            apiService: apiService,
            realtimeService: realtimeService,
            favoritosDao: favoritosDao,
          ),
        ),
      ],
      child: const AppTransporte(),
    ),
  );
}

class AppTransporte extends StatelessWidget {
  const AppTransporte({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadê o Cata Pobre',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,

      // Tema Padrão: Glassmorphism Neutro (Padrão Apple HIG)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08090A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF264E36),
          secondary: Color(0xFF1E3A2B),
          surface: Color(0xFF141615),
          error: Color(0xFFFF453A),
        ),
        textTheme: AppTypography.textTheme(const Color(0xFFF5F5F7)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF08090A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF264E36),
          secondary: Color(0xFF1E3A2B),
          surface: Color(0xFF141615),
          error: Color(0xFFFF453A),
        ),
        textTheme: AppTypography.textTheme(const Color(0xFFF5F5F7)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
          ),
        ),
      ),

      home: const MainNavigationScreen(),
    );
  }
}
