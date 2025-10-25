import 'package:anunciacion/src/presentation/screens/log_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      // Opción A: home directo a Login
      home: const LoginFrame(
        logoUrl:
            'https://scontent.fgua6-1.fna.fbcdn.net/v/t39.30808-6/305744111_461409942667352_3087119728415018752_n.jpg?_nc_cat=109&ccb=1-7&_nc_sid=6ee11a&_nc_ohc=L1ZwCRxY0CgQ7kNvwGgy34a&_nc_oc=AdlnPKC4belot2aKfspBLUDzvP95NbY_o2JBLji2XdmCe96ljaQDsDCVqAsGxmKzCBM&_nc_zt=23&_nc_ht=scontent.fgua6-1.fna&_nc_gid=n632Ofsz4YB9LojyUn-4rw&oh=00_AfeU7Jb8hjlud-g0DhDqQG0TKXav-C2Vlbvn8KqASxvTcg&oe=6902030A',
      ),
    );
  }
}

/*
// Archivo principal - Sistema de Gestión Escolar con Clean Architecture
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'clean_architecture_main.dart';

void main() {
  print('🚀 Iniciando Sistema de Gestión Escolar...');
  print('📊 Conexión a Clever Cloud PostgreSQL configurada');

  runApp(
    const ProviderScope(
      child: AnunciacionApp(),
    ),
  );
}
*/
