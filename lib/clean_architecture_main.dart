// Archivo principal con Clean Architecture configurada
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importar toda la estructura de Clean Architecture
import 'src/domain/domain.dart';
import 'src/infrastructure/infrastructure.dart';
import 'src/presentation/presentation.dart';
import 'src/presentation/providers/providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AnunciacionApp(),
    ),
  );
}

class AnunciacionApp extends StatelessWidget {
  const AnunciacionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestión Escolar - Anunciación',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Inicializar base de datos al iniciar la aplicación
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      final dbConfig = DatabaseConfig.instance;
      await dbConfig.database;
      print('✅ Base de datos inicializada correctamente');
    } catch (e) {
      print('❌ Error al inicializar base de datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Gestión Escolar'),
        actions: [
          if (userState.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(userProvider.notifier).logout();
              },
            ),
        ],
      ),
      body: userState.isAuthenticated ? _buildMainContent() : _buildLoginForm(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateUserDialog(context),
        tooltip: 'Crear Usuario',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildLoginForm() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    // Obtener userState dentro del scope del método
    final userState = ref.watch(userProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bienvenido al Sistema de Gestión Escolar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Usuario',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 24),
          if (userState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Text(
                userState.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: userState.isLoading
                  ? null
                  : () {
                      ref.read(userProvider.notifier).authenticate(
                            usernameController.text,
                            passwordController.text,
                          );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: userState.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Iniciar Sesión'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer(
      builder: (context, ref, child) {
        final userState = ref.watch(userProvider);
        final studentState = ref.watch(studentProvider);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Bienvenido, ${userState.currentUser?.name}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rol: ${userState.currentUser?.roleId}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              const Text(
                'Gestión de Estudiantes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: studentState.students.isEmpty
                    ? const Center(
                        child: Text('No hay estudiantes registrados'),
                      )
                    : ListView.builder(
                        itemCount: studentState.students.length,
                        itemBuilder: (context, index) {
                          final student = studentState.students[index];
                          return Card(
                            child: ListTile(
                              title: Text(student.name),
                              subtitle: Text(
                                'DPI: ${student.dpi.value} | Edad: ${student.age} años',
                              ),
                              trailing: Text(
                                'Grado: ${student.gradeId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (studentState.error != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(
                    studentState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final usernameController = TextEditingController();
        final passwordController = TextEditingController();

        return AlertDialog(
          title: const Text('Crear Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(userProvider.notifier).createUser(
                      name: nameController.text,
                      username: usernameController.text,
                      password: passwordController.text,
                      roleId: 1, // Administrador por defecto
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}
