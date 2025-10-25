# Configuración de PostgreSQL para el Sistema de Gestión Escolar Anunciación

## 🚀 Configuración de la Base de Datos

### 1. Instalar PostgreSQL
Si no tienes PostgreSQL instalado, descárgalo desde: https://www.postgresql.org/download/

### 2. Crear la Base de Datos
Ejecuta el script SQL `setup_postgresql.sql` en tu servidor PostgreSQL:

```bash
# Conectar a PostgreSQL como superusuario
psql -U postgres

# Ejecutar el script de configuración
\i setup_postgresql.sql
```

O puedes ejecutar directamente las instrucciones del script en pgAdmin o cualquier cliente PostgreSQL.

### 3. Configuración de la Aplicación
La aplicación ya está configurada para conectarse a:
- **Host:** localhost
- **Port:** 5432
- **Database:** sistema_escolar_dev
- **Username:** postgres
- **Password:** gtrudy502

### 4. Instalar Dependencias de Flutter
```bash
flutter pub get
```

### 5. Ejecutar la Aplicación
```bash
# Para web (Chrome recomendado)
flutter run -d chrome

# Para desktop
flutter run -d windows
```

## 🔧 Funcionalidades Incluidas

### ✅ Base de Datos PostgreSQL
- Conexión automática al iniciar la aplicación
- Creación automática de tablas si no existen
- Inserción de datos iniciales (roles y niveles educativos)

### ✅ Estructura de Tablas
- **Roles:** Administrador, Docente, Padre
- **Usuarios:** Con autenticación y roles
- **Niveles Educativos:** Preprimaria, Primaria, Básicos, Diversificado
- **Grados:** Con relación a niveles educativos
- **Secciones:** Con relación a grados
- **Estudiantes:** Con toda la información personal y académica
- **Padres:** Con información de contacto
- **Relaciones Estudiante-Padre:** Para múltiples padres por estudiante

### ✅ Usuario Administrador por Defecto
- **Usuario:** admin
- **Contraseña:** admin123
- **Rol:** Administrador

## 📋 Notas Importantes

1. **Esquema:** Todas las tablas están organizadas bajo el esquema `public`
2. **Autenticación:** La aplicación usa hash de contraseñas (SHA-256 con salt)
3. **Validaciones:** Incluye validaciones para números de teléfono guatemaltecos
4. **Relaciones:** Todas las foreign keys están correctamente configuradas

## 🐛 Solución de Problemas

### Error de Conexión
Si obtienes errores de conexión, verifica:
- PostgreSQL esté ejecutándose
- Credenciales correctas en `database_config.dart`
- Puerto 5432 esté disponible

### Error de Permisos
Si obtienes errores de permisos:
- Asegúrate de que el usuario postgres tenga permisos en la base de datos
- Verifica que la base de datos `sistema_escolar_dev` exista

### Error de Tablas
Si las tablas no se crean automáticamente:
- Ejecuta el script SQL manualmente
- Verifica que el usuario tenga permisos CREATE en la base de datos

## 📞 Soporte

Si encuentras problemas:
1. Verifica la configuración de PostgreSQL
2. Revisa los logs de la aplicación en la consola
3. Asegúrate de que todas las dependencias estén instaladas correctamente
