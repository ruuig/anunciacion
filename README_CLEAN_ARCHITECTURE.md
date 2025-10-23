# Sistema de Gestión Escolar - Anunciación

## 📋 Implementación de Clean Architecture

Este proyecto implementa un **Sistema de Gestión Escolar** siguiendo los principios de **Clean Architecture** en Flutter.

### 🏗️ Estructura del Proyecto

```
lib/src/
├── domain/                          # Capa de Dominio (Entidades y Lógica de Negocio)
│   ├── entities/                    # Entidades del dominio
│   │   ├── user.dart               # Usuario del sistema
│   │   ├── student.dart            # Estudiante
│   │   ├── parent.dart             # Padre/Tutor
│   │   ├── grade.dart              # Grado académico
│   │   ├── section.dart            # Sección
│   │   ├── subject.dart            # Materia
│   │   ├── role.dart               # Rol de usuario
│   │   └── entities.dart           # Export de todas las entidades
│   ├── value_objects/               # Objetos de Valor inmutables
│   │   ├── dpi.dart                # DPI guatemalteco
│   │   ├── email.dart              # Email validado
│   │   ├── phone.dart              # Teléfono guatemalteco
│   │   ├── password.dart           # Password con hash
│   │   ├── money.dart              # Monto monetario
│   │   ├── percentage.dart         # Porcentaje
│   │   ├── gender.dart             # Género
│   │   ├── user_status.dart        # Estado del usuario
│   │   ├── address.dart            # Dirección
│   │   └── value_objects.dart      # Export de todos los VO
│   ├── repositories/                # Interfaces de repositorios
│   │   ├── base_repository.dart     # Interfaz base
│   │   ├── user_repository.dart    # Repositorio de usuarios
│   │   ├── student_repository.dart # Repositorio de estudiantes
│   │   ├── grade_repository.dart   # Repositorio de grados
│   │   └── repositories.dart       # Export de repositorios
│   └── use_cases/                   # Casos de uso (Lógica de negocio)
│       ├── authenticate_user.dart  # Autenticación de usuario
│       ├── create_user.dart        # Crear usuario
│       ├── create_student.dart     # Crear estudiante
│       ├── get_user_profile.dart   # Obtener perfil de usuario
│       └── use_cases.dart          # Export de casos de uso
├── application/                     # Capa de Aplicación (Casos de uso)
│   ├── use_cases/                   # Implementaciones de casos de uso
│   └── interfaces/                  # Interfaces de servicios
├── infrastructure/                  # Capa de Infraestructura (DB, APIs)
│   ├── db/                         # Configuración de base de datos
│   │   ├── database_config.dart    # Configuración SQLite
│   │   └── database_helper.dart    # Helper para operaciones DB
│   ├── repositories/               # Implementaciones de repositorios
│   │   ├── user_repository_impl.dart    # SQLite User Repository
│   │   ├── student_repository_impl.dart # SQLite Student Repository
│   │   ├── grade_repository_impl.dart   # SQLite Grade Repository
│   │   └── section_repository_impl.dart # SQLite Section Repository
│   └── services/                   # Servicios externos
└── presentation/                    # Capa de Presentación (UI)
    ├── providers/                   # State Management con Riverpod
    │   ├── user_provider.dart       # Provider para usuarios
    │   ├── student_provider.dart    # Provider para estudiantes
    │   └── providers.dart           # Export de providers
    └── controllers/                 # Controladores de UI
```

### 🎯 Características Implementadas

#### ✅ Value Objects
- **DPI**: Validación de DPI guatemalteco (13 dígitos)
- **Email**: Validación de email con email_validator
- **Phone**: Formato de teléfono guatemalteco (+502)
- **Password**: Hash SHA-256 con salt
- **Money**: Manejo de montos monetarios en GTQ
- **Percentage**: Porcentajes entre 0-100
- **Gender**: Género (masculino, femenino, otro)
- **UserStatus**: Estados de usuario (activo, inactivo, suspendido)
- **Address**: Dirección con formato estructurado

#### ✅ Entidades del Dominio
- **User**: Usuario del sistema con roles y permisos
- **Student**: Estudiante con información académica
- **Parent**: Padre/Tutor con información de contacto
- **Grade**: Grado académico con nivel educativo
- **Section**: Sección dentro de un grado
- **Subject**: Materia/Asignatura
- **Role**: Roles del sistema (Admin, Docente, Padre)

#### ✅ Casos de Uso
- **AuthenticateUserUseCase**: Autenticación de usuarios
- **CreateUserUseCase**: Crear nuevos usuarios
- **GetUserProfileUseCase**: Obtener perfil de usuario
- **CreateStudentUseCase**: Crear estudiantes
- **GetStudentsByGradeUseCase**: Obtener estudiantes por grado
- **GetSectionsByGradeUseCase**: Obtener secciones por grado

#### ✅ Infraestructura
- **SQLite Database**: Base de datos local con esquema completo
- **Repository Pattern**: Implementaciones concretas de repositorios
- **Database Migration**: Scripts de creación de tablas

#### ✅ State Management
- **Riverpod**: Gestión de estado reactivo
- **UserProvider**: Manejo del estado de autenticación
- **StudentProvider**: Manejo del estado de estudiantes

### 🚀 Instalación y Uso

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

### 📊 Base de Datos

El sistema incluye un esquema de base de datos SQLite completo que incluye:

- **Usuarios y Seguridad**: roles, permisos, usuarios
- **Estructura Educativa**: niveles, grados, secciones, materias
- **Personas**: estudiantes, padres, relaciones
- **Académico**: periodos, actividades, calificaciones
- **Financiero**: pagos, estado de cuenta
- **Control**: asistencias, auditoría

### 🎨 UI/UX

La aplicación incluye:
- **Pantalla de login**: Autenticación de usuarios
- **Dashboard principal**: Vista general del sistema
- **Gestión de estudiantes**: CRUD de estudiantes
- **Gestión de usuarios**: Crear y administrar usuarios
- **Responsive Design**: Adaptable a diferentes pantallas

### 🛠️ Tecnologías Utilizadas

- **Flutter**: Framework UI
- **Dart**: Lenguaje de programación
- **SQLite**: Base de datos local
- **Riverpod**: State Management
- **Clean Architecture**: Patrón arquitectural
- **Repository Pattern**: Patrón de acceso a datos
- **Value Objects**: Objetos de dominio inmutables

### 📝 Notas de Desarrollo

Este proyecto sigue los principios SOLID y Clean Architecture:

1. **Independencia de Framework**: El dominio no depende de Flutter
2. **Testabilidad**: Fácil de testear cada capa por separado
3. **Mantenibilidad**: Código organizado y escalable
4. **Separación de Responsabilidades**: Cada capa tiene un propósito claro

### 🔄 Próximos Pasos

- [ ] Implementar casos de uso restantes
- [ ] Completar todas las implementaciones de repositorios
- [ ] Agregar más pantallas de UI
- [ ] Implementar notificaciones
- [ ] Agregar reportes y estadísticas
- [ ] Tests unitarios e integración

### 📞 Contacto

Desarrollado para **Colegio Anunciación** - Sistema de Gestión Escolar Integral.
