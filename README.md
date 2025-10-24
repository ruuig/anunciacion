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

## 📝 Notas

- **No se ejecuta SQL automáticamente**
- **Base de datos existente se respeta**
- **Solo verificación de conectividad**
- **Schema public por defecto** (sin prefijo necesario)
- **Credenciales hardcodeadas para desarrollo**

¡Listo para usar! 🎉
