// Configuración de base de datos SQLite
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseConfig {
  static const String _databaseName = 'anunciacion.db';
  static const int _databaseVersion = 1;

  DatabaseConfig._privateConstructor();
  static final DatabaseConfig instance = DatabaseConfig._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Manejar migraciones futuras
  }

  Future<void> _createTables(Database db) async {
    // Tabla de roles
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT UNIQUE NOT NULL,
        descripcion TEXT,
        nivel INTEGER NOT NULL,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de permisos
    await db.execute('''
      CREATE TABLE permisos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        modulo TEXT NOT NULL,
        descripcion TEXT,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        telefono TEXT,
        rol_id INTEGER NOT NULL REFERENCES roles(id),
        estado TEXT DEFAULT 'activo',
        url_avatar TEXT,
        ultimo_acceso TEXT,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
        fecha_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de niveles educativos
    await db.execute('''
      CREATE TABLE niveles_educativos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT UNIQUE NOT NULL,
        orden INTEGER NOT NULL,
        color_hex TEXT,
        activo INTEGER DEFAULT 1
      )
    ''');

    // Tabla de grados
    await db.execute('''
      CREATE TABLE grados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        nivel_educativo_id INTEGER NOT NULL REFERENCES niveles_educativos(id),
        rango_edad TEXT,
        ano_academico TEXT NOT NULL,
        activo INTEGER DEFAULT 1,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
        fecha_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(nombre, ano_academico)
      )
    ''');

    // Tabla de secciones
    await db.execute('''
      CREATE TABLE secciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grado_id INTEGER NOT NULL REFERENCES grados(id),
        nombre TEXT NOT NULL,
        capacidad INTEGER,
        cantidad_estudiantes INTEGER DEFAULT 0,
        activo INTEGER DEFAULT 1,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(grado_id, nombre)
      )
    ''');

    // Tabla de materias
    await db.execute('''
      CREATE TABLE materias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT UNIQUE NOT NULL,
        codigo TEXT UNIQUE,
        descripcion TEXT,
        activo INTEGER DEFAULT 1,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de estudiantes
    await db.execute('''
      CREATE TABLE estudiantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dpi TEXT UNIQUE NOT NULL,
        nombre TEXT NOT NULL,
        fecha_nacimiento TEXT NOT NULL,
        genero TEXT,
        direccion TEXT,
        telefono TEXT,
        email TEXT,
        url_avatar TEXT,
        grado_id INTEGER NOT NULL REFERENCES grados(id),
        seccion_id INTEGER NOT NULL REFERENCES secciones(id),
        fecha_inscripcion TEXT NOT NULL,
        estado TEXT DEFAULT 'activo',
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
        fecha_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de padres
    await db.execute('''
      CREATE TABLE padres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dpi TEXT UNIQUE,
        nombre TEXT NOT NULL,
        relacion TEXT NOT NULL,
        telefono TEXT NOT NULL,
        telefono_secundario TEXT,
        email TEXT,
        direccion TEXT,
        ocupacion TEXT,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
        fecha_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de estudiantes_padres
    await db.execute('''
      CREATE TABLE estudiantes_padres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        estudiante_id INTEGER NOT NULL REFERENCES estudiantes(id),
        padre_id INTEGER NOT NULL REFERENCES padres(id),
        es_contacto_principal INTEGER DEFAULT 0,
        es_contacto_emergencia INTEGER DEFAULT 0,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(estudiante_id, padre_id)
      )
    ''');
  }

  Future<void> _insertInitialData(Database db) async {
    // Insertar roles básicos
    await db.insert('roles', {
      'nombre': 'Administrador',
      'descripcion': 'Administrador del sistema',
      'nivel': 1,
    });

    await db.insert('roles', {
      'nombre': 'Docente',
      'descripcion': 'Docente del colegio',
      'nivel': 2,
    });

    await db.insert('roles', {
      'nombre': 'Padre',
      'descripcion': 'Padre de familia',
      'nivel': 3,
    });

    // Insertar niveles educativos básicos
    await db.insert('niveles_educativos', {
      'nombre': 'Preprimaria',
      'orden': 1,
      'color_hex': '#FF6B6B',
    });

    await db.insert('niveles_educativos', {
      'nombre': 'Primaria',
      'orden': 2,
      'color_hex': '#4ECDC4',
    });

    await db.insert('niveles_educativos', {
      'nombre': 'Básicos',
      'orden': 3,
      'color_hex': '#45B7D1',
    });

    await db.insert('niveles_educativos', {
      'nombre': 'Diversificado',
      'orden': 4,
      'color_hex': '#96CEB4',
    });
  }
}
