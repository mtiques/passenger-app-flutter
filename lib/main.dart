import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  runApp(
    const ProviderScope(child: PassengerApp()),
  );
}

// ✅ Cambiar a ConsumerWidget para acceder a Riverpod
class PassengerApp extends ConsumerWidget {
  const PassengerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Obtener router desde el provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Passenger App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router, // ✅ Viene del provider
      debugShowCheckedModeBanner: false,
    );
  }
}
