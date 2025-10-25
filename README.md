# 🎓 Sistema de Gestión Escolar - Anunciación

Aplicación Flutter con Clean Architecture para gestión escolar conectada a PostgreSQL en Clever Cloud.

## 🚀 Inicio Rápido

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Ejecutar la aplicación
```bash
flutter run
```

### 3. Verificar conexión
- Toca el icono **🌐** en la barra superior
- Verifica que la conexión a Clever Cloud funcione

## 📊 Base de Datos

- **PostgreSQL** en Clever Cloud
- **Credenciales hardcodeadas** para desarrollo rápido
- **SSL habilitado** para conexiones seguras
- **Schema public por defecto** (sin modificaciones automáticas)
- **Sin ejecución automática de SQL** - respeta base de datos existente

## 🧪 Tests

```bash
# Ejecutar tests de conexión
flutter test test/database_connection_test.dart

# Ejecutar todos los tests
flutter test
```

## 🔧 Configuración

- Credenciales en `lib/src/infrastructure/db/database_config.dart`
- Template seguro en `lib/src/infrastructure/db/database_config_template.dart`
- No requiere variables de entorno (hardcodeado)

## 📁 Estructura

```
lib/
├── clean_architecture_main.dart    # Aplicación principal
├── main.dart                      # Punto de entrada
├── database_test_screen.dart      # Test de conexión
└── src/
    └── infrastructure/
        └── db/
            ├── database_config.dart           # Conexión BD
            └── database_config_template.dart  # Template
```

## 🎯 Características

- ✅ Clean Architecture
- ✅ Conexión PostgreSQL (Clever Cloud)
- ✅ Test de conectividad integrado
- ✅ Manejo seguro de credenciales
- ✅ Sin dependencias externas de configuración

## 🚨 Solución de Problemas

### Error "Too Many Connections" (53300)

Si recibes el error **53300: too many connections for role**:

1. **Ejecuta el limpiador de emergencia**:
```bash
dart run emergency_clean.dart
```

2. **O usa el limpiador de conexiones**:
```bash
dart run force_clean_connections.dart
```

3. **Si persiste, espera y reinicia**:
   - Espera 2-3 minutos para que se liberen conexiones
   - Reinicia completamente Flutter
   - Verifica en el panel de Clever Cloud

4. **Scripts disponibles**:
   - `emergency_clean.dart` - Limpieza agresiva automática
   - `force_clean_connections.dart` - Múltiples intentos con espera
   - `test_login.dart` - Verificación específica del login

### Scripts de Diagnóstico

```bash
# Verificar login
dart run test_login.dart

# Probar conexión
dart run test_db_config.dart

# Limpiar conexiones
dart run clean_connections.dart

# Emergencia (más agresivo)
dart run emergency_clean.dart
```

### Credenciales de Base de Datos

- **Host**: bbisaulqlodvucjcmkwk-postgresql.services.clever-cloud.com
- **Database**: bbisaulqlodvucjcmkwk
- **User**: upaubg9taprssjvha045
- **SSL**: require

*Nota: Las credenciales están hardcodeadas en el código para desarrollo rápido*
