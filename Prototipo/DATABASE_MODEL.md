# MODELO ENTIDAD-RELACIÓN - SISTEMA DE GESTIÓN ESCOLAR

## DESCRIPCIÓN GENERAL

El sistema requiere un modelo de base de datos relacional que soporte control de acceso basado en roles (RBAC), gestión académica completa, y administración financiera. El diseño debe priorizar la integridad referencial, la trazabilidad de acciones, y la escalabilidad para instituciones educativas de múltiples niveles.

---

## ENTIDADES PRINCIPALES

### 1. USUARIOS (users)

**Descripción**: Almacena toda la información del personal del colegio con control de acceso diferenciado.

**Atributos**:
- `id` (PK, UUID/INT): Identificador único del usuario
- `name` (VARCHAR 200, NOT NULL): Nombre completo del usuario
- `email` (VARCHAR 150, UNIQUE, NOT NULL): Correo electrónico para autenticación
- `phone` (VARCHAR 20): Teléfono de contacto
- `password_hash` (VARCHAR 255, NOT NULL): Contraseña encriptada
- `role_id` (FK, INT, NOT NULL): Referencia a la tabla de roles
- `status` (ENUM: 'active', 'inactive', DEFAULT 'active'): Estado del usuario
- `avatar_url` (VARCHAR 500): URL del avatar del usuario
- `last_login` (TIMESTAMP): Fecha y hora del último acceso
- `created_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- `updated_at` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP ON UPDATE)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (email)
- INDEX (role_id)
- INDEX (status)

**Validaciones**:
- Email debe tener formato válido
- Solo un usuario activo por email
- Password mínimo 8 caracteres al crear

---

### 2. ROLES (roles)

**Descripción**: Define los tres roles principales del sistema con sus características base.

**Atributos**:
- `id` (PK, INT): Identificador único del rol
- `name` (VARCHAR 50, UNIQUE, NOT NULL): Nombre del rol
- `description` (TEXT): Descripción del rol
- `level` (INT, NOT NULL): Nivel jerárquico (1: Director, 2: Secretaria, 3: Docente)
- `created_at` (TIMESTAMP)

**Datos fijos**:
```sql
1 | 'Director'    | 'Acceso total al sistema'                    | 1
2 | 'Secretaria'  | 'Gestión de estudiantes y pagos'            | 2
3 | 'Docente'     | 'Gestión de calificaciones y actividades'   | 3
```

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (name)

---

### 3. PERMISOS (permissions)

**Descripción**: Catálogo de permisos granulares del sistema.

**Atributos**:
- `id` (PK, INT): Identificador único del permiso
- `code` (VARCHAR 100, UNIQUE, NOT NULL): Código del permiso (ej: 'view_students', 'edit_grades')
- `module` (VARCHAR 50, NOT NULL): Módulo al que pertenece
- `description` (TEXT): Descripción del permiso
- `created_at` (TIMESTAMP)

**Ejemplos de permisos**:
- `view_all`, `edit_all`, `delete_all` (Director)
- `view_students`, `edit_students`, `manage_payments`, `view_reports` (Secretaria)
- `view_students`, `manage_grades`, `view_attendance`, `manage_activities` (Docente)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (code)
- INDEX (module)

---

### 4. ROLES_PERMISOS (role_permissions)

**Descripción**: Tabla intermedia para relación muchos-a-muchos entre roles y permisos.

**Atributos**:
- `id` (PK, INT): Identificador único
- `role_id` (FK, INT, NOT NULL): Referencia a roles
- `permission_id` (FK, INT, NOT NULL): Referencia a permissions
- `created_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (role_id, permission_id)
- INDEX (role_id)
- INDEX (permission_id)

**Constraints**:
- FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
- FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE

---

### 5. NIVELES_EDUCATIVOS (educational_levels)

**Descripción**: Catálogo de niveles educativos del colegio.

**Atributos**:
- `id` (PK, INT): Identificador único
- `name` (VARCHAR 50, UNIQUE, NOT NULL): Nombre del nivel
- `order` (INT, NOT NULL): Orden de secuencia
- `color_hex` (VARCHAR 7): Color para UI (ej: '#3B82F6')
- `active` (BOOLEAN, DEFAULT true)

**Datos típicos**:
```sql
1 | 'Preprimaria'  | 1 | '#EC4899' | true
2 | 'Primaria'     | 2 | '#3B82F6' | true
3 | 'Secundaria'   | 3 | '#10B981' | true
```

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (name)
- INDEX (order)

---

### 6. GRADOS (grades)

**Descripción**: Define los grados académicos con sus características específicas.

**Atributos**:
- `id` (PK, INT): Identificador único
- `name` (VARCHAR 100, NOT NULL): Nombre del grado (ej: '1ro Primaria')
- `level_id` (FK, INT, NOT NULL): Referencia a educational_levels
- `age_range` (VARCHAR 50): Rango de edad (ej: '6-7 años')
- `academic_year` (VARCHAR 9): Año académico (ej: '2024-2025')
- `active` (BOOLEAN, DEFAULT true)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- INDEX (level_id)
- INDEX (active)
- UNIQUE INDEX (name, academic_year)

**Constraints**:
- FOREIGN KEY (level_id) REFERENCES educational_levels(id) ON DELETE RESTRICT

---

### 7. SECCIONES (sections)

**Descripción**: Secciones dentro de cada grado (A, B, C, etc.).

**Atributos**:
- `id` (PK, INT): Identificador único
- `grade_id` (FK, INT, NOT NULL): Referencia a grades
- `name` (VARCHAR 10, NOT NULL): Nombre de la sección ('A', 'B', 'C')
- `capacity` (INT): Capacidad máxima de estudiantes
- `current_students` (INT, DEFAULT 0): Estudiantes actuales (calculado)
- `active` (BOOLEAN, DEFAULT true)
- `created_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- INDEX (grade_id)
- UNIQUE INDEX (grade_id, name)

**Constraints**:
- FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE
- CHECK (current_students >= 0)
- CHECK (current_students <= capacity OR capacity IS NULL)

---

### 8. MATERIAS (subjects)

**Descripción**: Catálogo de materias impartidas en el colegio.

**Atributos**:
- `id` (PK, INT): Identificador único
- `name` (VARCHAR 100, UNIQUE, NOT NULL): Nombre de la materia
- `code` (VARCHAR 20, UNIQUE): Código de la materia
- `description` (TEXT): Descripción de la materia
- `active` (BOOLEAN, DEFAULT true)
- `created_at` (TIMESTAMP)

**Ejemplos**:
- Matemáticas, Español, Ciencias Naturales, Estudios Sociales, Inglés, Educación Física, Arte, Computación

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (name)
- UNIQUE INDEX (code)

---

### 9. GRADOS_MATERIAS (grade_subjects)

**Descripción**: Relación entre grados y materias asignadas.

**Atributos**:
- `id` (PK, INT): Identificador único
- `grade_id` (FK, INT, NOT NULL): Referencia a grades
- `subject_id` (FK, INT, NOT NULL): Referencia a subjects
- `hours_per_week` (INT): Horas semanales de la materia
- `active` (BOOLEAN, DEFAULT true)
- `created_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (grade_id, subject_id)
- INDEX (grade_id)
- INDEX (subject_id)

**Constraints**:
- FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE
- FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT

---

### 10. DOCENTES_ASIGNACIONES (teacher_assignments)

**Descripción**: Asignación de docentes a grados y materias específicos.

**Atributos**:
- `id` (PK, INT): Identificador único
- `teacher_id` (FK, INT, NOT NULL): Referencia a users (solo role_id = 3)
- `grade_id` (FK, INT, NOT NULL): Referencia a grades
- `section_id` (FK, INT): Referencia a sections (opcional, puede ser NULL si enseña a todas)
- `subject_id` (FK, INT, NOT NULL): Referencia a subjects
- `academic_year` (VARCHAR 9, NOT NULL): Año académico
- `active` (BOOLEAN, DEFAULT true)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- INDEX (teacher_id)
- INDEX (grade_id)
- INDEX (subject_id)
- UNIQUE INDEX (teacher_id, grade_id, section_id, subject_id, academic_year)

**Constraints**:
- FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE
- FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE
- FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
- FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT
- CHECK: Verificar que teacher_id sea un usuario con role_id = 3

---

### 11. ESTUDIANTES (students)

**Descripción**: Información completa de los estudiantes matriculados.

**Atributos**:
- `id` (PK, INT): Identificador único
- `dpi` (VARCHAR 20, UNIQUE, NOT NULL): DPI del estudiante
- `name` (VARCHAR 200, NOT NULL): Nombre completo
- `birth_date` (DATE, NOT NULL): Fecha de nacimiento
- `gender` (ENUM: 'M', 'F', 'Otro'): Género
- `address` (VARCHAR 500): Dirección completa
- `phone` (VARCHAR 20): Teléfono del estudiante
- `email` (VARCHAR 150): Correo electrónico
- `avatar_url` (VARCHAR 500): URL del avatar
- `grade_id` (FK, INT, NOT NULL): Grado actual
- `section_id` (FK, INT, NOT NULL): Sección actual
- `enrollment_date` (DATE, NOT NULL): Fecha de inscripción
- `status` (ENUM: 'active', 'inactive', 'graduated', 'transferred', DEFAULT 'active')
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (dpi)
- INDEX (grade_id, section_id)
- INDEX (status)
- INDEX (name) -- Para búsquedas

**Constraints**:
- FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE RESTRICT
- FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE RESTRICT

---

### 12. PADRES_FAMILIA (parents)

**Descripción**: Información de padres o tutores de los estudiantes.

**Atributos**:
- `id` (PK, INT): Identificador único
- `dpi` (VARCHAR 20, UNIQUE): DPI del padre/tutor
- `name` (VARCHAR 200, NOT NULL): Nombre completo
- `relationship` (VARCHAR 50, NOT NULL): Relación con el estudiante (Padre, Madre, Tutor, etc.)
- `phone` (VARCHAR 20, NOT NULL): Teléfono principal
- `phone_secondary` (VARCHAR 20): Teléfono secundario
- `email` (VARCHAR 150): Correo electrónico
- `address` (VARCHAR 500): Dirección
- `occupation` (VARCHAR 100): Ocupación
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (dpi)
- INDEX (phone)

---

### 13. ESTUDIANTES_PADRES (student_parents)

**Descripción**: Relación entre estudiantes y sus padres/tutores (muchos a muchos).

**Atributos**:
- `id` (PK, INT): Identificador único
- `student_id` (FK, INT, NOT NULL): Referencia a students
- `parent_id` (FK, INT, NOT NULL): Referencia a parents
- `is_primary_contact` (BOOLEAN, DEFAULT false): Contacto principal
- `is_emergency_contact` (BOOLEAN, DEFAULT false): Contacto de emergencia
- `created_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (student_id, parent_id)
- INDEX (student_id)
- INDEX (parent_id)

**Constraints**:
- FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
- FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE RESTRICT

---

### 14. PERIODOS_ACADEMICOS (academic_periods)

**Descripción**: Define los periodos académicos (bimestres, trimestres, etc.).

**Atributos**:
- `id` (PK, INT): Identificador único
- `name` (VARCHAR 50, NOT NULL): Nombre del periodo (ej: 'Primer Bimestre')
- `academic_year` (VARCHAR 9, NOT NULL): Año académico
- `start_date` (DATE, NOT NULL): Fecha de inicio
- `end_date` (DATE, NOT NULL): Fecha de fin
- `order` (INT, NOT NULL): Orden del periodo
- `active` (BOOLEAN, DEFAULT true)
- `created_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (name, academic_year)
- INDEX (academic_year, order)

**Constraints**:
- CHECK (end_date > start_date)

---

### 15. ACTIVIDADES (activities)

**Descripción**: Actividades académicas creadas por docentes (exámenes, tareas, proyectos, etc.).

**Atributos**:
- `id` (PK, INT): Identificador único
- `name` (VARCHAR 200, NOT NULL): Nombre de la actividad
- `description` (TEXT): Descripción detallada
- `teacher_id` (FK, INT, NOT NULL): Docente que creó la actividad
- `subject_id` (FK, INT, NOT NULL): Materia
- `grade_id` (FK, INT, NOT NULL): Grado
- `section_id` (FK, INT, NOT NULL): Sección
- `period_id` (FK, INT, NOT NULL): Periodo académico
- `type` (ENUM: 'Examen', 'Tarea', 'Proyecto', 'Laboratorio', 'Presentación', 'Quiz', NOT NULL)
- `max_points` (DECIMAL(5,2), NOT NULL): Puntos máximos
- `weight_percentage` (DECIMAL(5,2)): Peso en la nota final del periodo
- `due_date` (DATE): Fecha de entrega/realización
- `status` (ENUM: 'pending', 'grading', 'completed', DEFAULT 'pending')
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- INDEX (teacher_id)
- INDEX (subject_id)
- INDEX (grade_id, section_id)
- INDEX (period_id)
- INDEX (due_date)
- INDEX (status)

**Constraints**:
- FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE RESTRICT
- FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT
- FOREIGN KEY (grade_id) REFERENCES grades(id) ON DELETE CASCADE
- FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
- FOREIGN KEY (period_id) REFERENCES academic_periods(id) ON DELETE RESTRICT
- CHECK (max_points > 0)
- CHECK (weight_percentage >= 0 AND weight_percentage <= 100)

---

### 16. CALIFICACIONES_ACTIVIDADES (activity_grades)

**Descripción**: Calificaciones de estudiantes en actividades específicas.

**Atributos**:
- `id` (PK, INT): Identificador único
- `activity_id` (FK, INT, NOT NULL): Referencia a activities
- `student_id` (FK, INT, NOT NULL): Referencia a students
- `points_earned` (DECIMAL(5,2)): Puntos obtenidos
- `grade_percentage` (DECIMAL(5,2)): Porcentaje de calificación (calculado)
- `comments` (TEXT): Comentarios del docente
- `graded_by` (FK, INT, NOT NULL): Usuario que calificó
- `graded_at` (TIMESTAMP): Fecha y hora de calificación
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (activity_id, student_id)
- INDEX (activity_id)
- INDEX (student_id)
- INDEX (graded_by)

**Constraints**:
- FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE
- FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
- FOREIGN KEY (graded_by) REFERENCES users(id) ON DELETE RESTRICT
- CHECK (points_earned >= 0)
- CHECK (points_earned <= (SELECT max_points FROM activities WHERE id = activity_id))

**Triggers**:
- Calcular `grade_percentage` automáticamente: (points_earned / max_points) * 100
- Actualizar `status` de la actividad cuando todos los estudiantes estén calificados

---

### 17. CALIFICACIONES_PERIODO (period_grades)

**Descripción**: Calificaciones finales por materia en cada periodo académico.

**Atributos**:
- `id` (PK, INT): Identificador único
- `student_id` (FK, INT, NOT NULL): Referencia a students
- `subject_id` (FK, INT, NOT NULL): Referencia a subjects
- `period_id` (FK, INT, NOT NULL): Referencia a academic_periods
- `grade` (DECIMAL(5,2), NOT NULL): Nota final del periodo (0-100)
- `is_passing` (BOOLEAN): Si aprobó (grade >= 70)
- `comments` (TEXT): Observaciones del docente
- `registered_by` (FK, INT, NOT NULL): Usuario que registró
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (student_id, subject_id, period_id)
- INDEX (student_id)
- INDEX (subject_id, period_id)
- INDEX (period_id)

**Constraints**:
- FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
- FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE RESTRICT
- FOREIGN KEY (period_id) REFERENCES academic_periods(id) ON DELETE RESTRICT
- FOREIGN KEY (registered_by) REFERENCES users(id) ON DELETE RESTRICT
- CHECK (grade >= 0 AND grade <= 100)

**Triggers**:
- Calcular `is_passing` automáticamente: grade >= 70
- Puede calcularse automáticamente desde las calificaciones de actividades según el weight_percentage

---

### 18. ASISTENCIAS (attendance)

**Descripción**: Registro de asistencia diaria de estudiantes con control de entrada y salida.

**Atributos**:
- `id` (PK, INT): Identificador único
- `student_id` (FK, INT, NOT NULL): Referencia a students
- `date` (DATE, NOT NULL): Fecha de asistencia
- `entry_time` (TIME): Hora de entrada
- `exit_time` (TIME): Hora de salida
- `status` (ENUM: 'present', 'absent', 'late', 'excused', 'departed', DEFAULT 'present')
- `entry_method` (ENUM: 'qr', 'manual', 'biometric'): Método de registro de entrada
- `exit_method` (ENUM: 'qr', 'manual', 'biometric'): Método de registro de salida
- `authorized_by` (FK, INT): Usuario que autorizó (para salidas tempranas)
- `notes` (TEXT): Notas adicionales
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (student_id, date)
- INDEX (student_id)
- INDEX (date)
- INDEX (status)

**Constraints**:
- FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
- FOREIGN KEY (authorized_by) REFERENCES users(id) ON DELETE SET NULL
- CHECK (exit_time IS NULL OR exit_time > entry_time OR entry_time IS NULL)

---

### 19. CONCEPTOS_PAGO (payment_concepts)

**Descripción**: Catálogo de conceptos de pago del colegio.

**Atributos**:
- `id` (PK, INT): Identificador único
- `name` (VARCHAR 100, UNIQUE, NOT NULL): Nombre del concepto
- `description` (TEXT): Descripción del concepto
- `default_amount` (DECIMAL(10,2)): Monto por defecto
- `type` (ENUM: 'monthly', 'annual', 'one_time', 'optional'): Tipo de concepto
- `active` (BOOLEAN, DEFAULT true)
- `created_at` (TIMESTAMP)

**Ejemplos**:
- Colegiatura Mensual, Inscripción Anual, Materiales, Eventos Especiales, Seguro Estudiantil

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (name)
- INDEX (type)

---

### 20. PAGOS (payments)

**Descripción**: Registro de pagos realizados por estudiantes.

**Atributos**:
- `id` (PK, INT): Identificador único
- `student_id` (FK, INT, NOT NULL): Referencia a students
- `concept_id` (FK, INT, NOT NULL): Referencia a payment_concepts
- `amount` (DECIMAL(10,2), NOT NULL): Monto pagado
- `payment_date` (DATE, NOT NULL): Fecha del pago
- `payment_method` (ENUM: 'cash', 'transfer', 'card', 'check', 'deposit'): Método de pago
- `reference_number` (VARCHAR 100): Número de referencia/transacción
- `receipt_number` (VARCHAR 100, UNIQUE): Número de recibo generado
- `document_type` (ENUM: 'manual', 'uploaded_pdf'): Tipo de registro
- `document_url` (VARCHAR 500): URL del PDF subido (si aplica)
- `status` (ENUM: 'pending', 'verified', 'rejected', DEFAULT 'pending'): Estado del pago
- `comments` (TEXT): Comentarios adicionales
- `registered_by` (FK, INT, NOT NULL): Usuario que registró (secretaria)
- `verified_by` (FK, INT): Usuario que verificó
- `verified_at` (TIMESTAMP): Fecha de verificación
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- INDEX (student_id)
- INDEX (concept_id)
- INDEX (payment_date)
- INDEX (status)
- INDEX (registered_by)
- UNIQUE INDEX (receipt_number)

**Constraints**:
- FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE RESTRICT
- FOREIGN KEY (concept_id) REFERENCES payment_concepts(id) ON DELETE RESTRICT
- FOREIGN KEY (registered_by) REFERENCES users(id) ON DELETE RESTRICT
- FOREIGN KEY (verified_by) REFERENCES users(id) ON DELETE SET NULL
- CHECK (amount > 0)
- CHECK: Verificar que registered_by y verified_by sean usuarios con role_id = 2 (Secretaria)

---

### 21. ESTADO_CUENTA_ESTUDIANTE (student_account_status)

**Descripción**: Estado de cuenta consolidado por estudiante (vista materializada o tabla calculada).

**Atributos**:
- `id` (PK, INT): Identificador único
- `student_id` (FK, INT, UNIQUE, NOT NULL): Referencia a students
- `total_charged` (DECIMAL(10,2), DEFAULT 0): Total cargado
- `total_paid` (DECIMAL(10,2), DEFAULT 0): Total pagado
- `balance` (DECIMAL(10,2), DEFAULT 0): Saldo (charged - paid)
- `last_payment_date` (DATE): Fecha del último pago
- `payment_status` (ENUM: 'up_to_date', 'pending', 'overdue', DEFAULT 'up_to_date')
- `updated_at` (TIMESTAMP)

**Índices**:
- PRIMARY KEY (id)
- UNIQUE INDEX (student_id)
- INDEX (payment_status)

**Constraints**:
- FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE

**Triggers**:
- Actualizar automáticamente al registrar nuevos pagos

---

### 22. AUDITORIA (audit_log)

**Descripción**: Registro de auditoría para trazabilidad de acciones críticas.

**Atributos**:
- `id` (PK, BIGINT): Identificador único
- `user_id` (FK, INT, NOT NULL): Usuario que realizó la acción
- `action` (VARCHAR 100, NOT NULL): Tipo de acción (CREATE, UPDATE, DELETE, LOGIN, etc.)
- `table_name` (VARCHAR 100, NOT NULL): Tabla afectada
- `record_id` (INT): ID del registro afectado
- `old_values` (JSON): Valores anteriores (para UPDATE/DELETE)
- `new_values` (JSON): Valores nuevos (para CREATE/UPDATE)
- `ip_address` (VARCHAR 45): Dirección IP
- `user_agent` (VARCHAR 500): Agente de usuario
- `created_at` (TIMESTAMP, NOT NULL)

**Índices**:
- PRIMARY KEY (id)
- INDEX (user_id)
- INDEX (table_name, record_id)
- INDEX (action)
- INDEX (created_at)

**Constraints**:
- FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL

**Nota**: Esta tabla crece constantemente, considerar particionamiento por fecha.

---

## RELACIONES PRINCIPALES

### Relaciones 1:N (Uno a Muchos)

1. **roles → users** (1:N)
   - Un rol puede tener múltiples usuarios
   - Cada usuario tiene exactamente un rol

2. **educational_levels → grades** (1:N)
   - Un nivel educativo contiene múltiples grados
   - Cada grado pertenece a un nivel

3. **grades → sections** (1:N)
   - Un grado puede tener múltiples secciones
   - Cada sección pertenece a un grado

4. **grades → students** (1:N)
   - Un grado tiene múltiples estudiantes
   - Cada estudiante está en un grado

5. **sections → students** (1:N)
   - Una sección tiene múltiples estudiantes
   - Cada estudiante está en una sección

6. **users (docente) → activities** (1:N)
   - Un docente puede crear múltiples actividades
   - Cada actividad es creada por un docente

7. **students → attendance** (1:N)
   - Un estudiante tiene múltiples registros de asistencia
   - Cada registro pertenece a un estudiante

8. **students → payments** (1:N)
   - Un estudiante puede tener múltiples pagos
   - Cada pago pertenece a un estudiante

### Relaciones N:M (Muchos a Muchos)

1. **roles ↔ permissions** (N:M)
   - Tabla intermedia: role_permissions
   - Un rol puede tener múltiples permisos
   - Un permiso puede estar en múltiples roles

2. **grades ↔ subjects** (N:M)
   - Tabla intermedia: grade_subjects
   - Un grado tiene múltiples materias
   - Una materia se imparte en múltiples grados

3. **teachers ↔ grades/subjects** (N:M)
   - Tabla intermedia: teacher_assignments
   - Un docente puede enseñar múltiples materias en múltiples grados
   - Un grado/materia puede ser impartido por múltiples docentes

4. **students ↔ parents** (N:M)
   - Tabla intermedia: student_parents
   - Un estudiante puede tener múltiples padres/tutores
   - Un padre puede tener múltiples hijos estudiantes

5. **activities ↔ students** (N:M con datos)
   - Tabla intermedia: activity_grades
   - Una actividad tiene calificaciones de múltiples estudiantes
   - Un estudiante tiene calificaciones en múltiples actividades
   - La relación almacena la calificación obtenida

---

## CONSIDERACIONES TÉCNICAS

### Integridad Referencial

1. **Restricciones de eliminación**:
   - `ON DELETE RESTRICT`: Para roles, subjects, grades cuando tienen dependencias
   - `ON DELETE CASCADE`: Para sections, activities, attendance cuando el padre se elimina
   - `ON DELETE SET NULL`: Para campos opcionales de auditoría

2. **Restricciones de actualización**:
   - Usar `ON UPDATE CASCADE` en claves foráneas para sincronización

3. **Validaciones a nivel de base de datos**:
   - CHECK constraints para rangos de valores (calificaciones 0-100)
   - UNIQUE constraints para evitar duplicados
   - NOT NULL para campos obligatorios

### Seguridad

1. **Control de acceso por rol**:
   - Implementar vistas específicas por rol (view_director, view_secretary, view_teacher)
   - Stored procedures para operaciones sensibles (registro de pagos, modificación de calificaciones)
   - Row-level security para que docentes solo vean sus grados asignados

2. **Encriptación**:
   - Passwords: bcrypt o argon2
   - Datos sensibles en reposo: cifrado AES-256 para DPIs, información financiera

3. **Auditoría**:
   - Triggers automáticos en tablas críticas (payments, period_grades, students)
   - Registro de todos los accesos a información de pagos

### Performance

1. **Índices estratégicos**:
   - Índices compuestos para búsquedas frecuentes (grade_id, section_id)
   - Full-text search para búsqueda de nombres
   - Índices en fechas para reportes

2. **Vistas materializadas**:
   - Promedios por estudiante/grado/materia
   - Estados de cuenta consolidados
   - Estadísticas de asistencia

3. **Particionamiento**:
   - Tabla attendance por rango de fechas (mensual o trimestral)
   - Tabla audit_log por año académico
   - Tabla payments por año

4. **Desnormalización selectiva**:
   - Campos calculados (student_count en sections, is_passing en period_grades)
   - Triggers para mantener sincronización

### Escalabilidad

1. **Año académico**:
   - Todas las entidades académicas deben incluir academic_year
   - Permite mantener histórico completo
   - Facilita migración de estudiantes entre años

2. **Soft deletes**:
   - Considerar agregar `deleted_at` en lugar de eliminar físicamente
   - Especialmente importante en students, users, grades

3. **Multitenancy** (futuro):
   - Si se planea soportar múltiples colegios, agregar `school_id` como prefijo en todas las tablas

---

## CONSULTAS CRÍTICAS A OPTIMIZAR

### 1. Dashboard del Director
```sql
-- Total de estudiantes activos por nivel
SELECT el.name, COUNT(s.id) 
FROM students s
JOIN grades g ON s.grade_id = g.id
JOIN educational_levels el ON g.level_id = el.id
WHERE s.status = 'active'
GROUP BY el.id, el.name;
```

### 2. Grados asignados a un Docente
```sql
-- Grados donde enseña un docente específico
SELECT DISTINCT g.name, sec.name as section, sub.name as subject
FROM teacher_assignments ta
JOIN grades g ON ta.grade_id = g.id
LEFT JOIN sections sec ON ta.section_id = sec.id
JOIN subjects sub ON ta.subject_id = sub.id
WHERE ta.teacher_id = ? AND ta.active = true
AND ta.academic_year = '2024-2025';
```

### 3. Estudiantes con filtros
```sql
-- Lista de estudiantes con filtro por grado y sección
SELECT s.*, g.name as grade_name, sec.name as section_name,
       p.name as parent_name, p.phone as parent_phone
FROM students s
JOIN grades g ON s.grade_id = g.id
JOIN sections sec ON s.section_id = sec.id
LEFT JOIN student_parents sp ON s.id = sp.student_id AND sp.is_primary_contact = true
LEFT JOIN parents p ON sp.parent_id = p.id
WHERE g.id = ? AND sec.id = ? AND s.status = 'active'
ORDER BY s.name;
```

### 4. Calificaciones de un estudiante
```sql
-- Boleta de calificaciones de un estudiante en un periodo
SELECT sub.name as subject, pg.grade, pg.is_passing, pg.comments
FROM period_grades pg
JOIN subjects sub ON pg.subject_id = sub.id
WHERE pg.student_id = ? AND pg.period_id = ?
ORDER BY sub.name;
```

### 5. Asistencia con filtros
```sql
-- Estudiantes presentes filtrados por grado/sección en una fecha
SELECT s.name, s.avatar_url, g.name as grade, sec.name as section,
       a.entry_time, a.exit_time, a.status
FROM attendance a
JOIN students s ON a.student_id = s.id
JOIN grades g ON s.grade_id = g.id
JOIN sections sec ON s.section_id = sec.id
WHERE a.date = CURDATE()
  AND g.id = ? 
  AND sec.id = ?
  AND a.status IN ('present', 'late')
ORDER BY a.entry_time;
```

### 6. Estado de pagos
```sql
-- Estado de cuenta de un estudiante
SELECT sas.*, s.name as student_name
FROM student_account_status sas
JOIN students s ON sas.student_id = s.id
WHERE sas.student_id = ?;

-- Detalle de pagos
SELECT p.*, pc.name as concept_name, u.name as registered_by_name
FROM payments p
JOIN payment_concepts pc ON p.concept_id = pc.id
JOIN users u ON p.registered_by = u.id
WHERE p.student_id = ?
ORDER BY p.payment_date DESC;
```

### 7. Actividades y calificaciones
```sql
-- Actividades de un docente con progreso
SELECT a.*, 
       COUNT(ag.id) as students_graded,
       (SELECT COUNT(*) FROM students WHERE grade_id = a.grade_id 
        AND section_id = a.section_id AND status = 'active') as total_students,
       AVG(ag.grade_percentage) as average_grade
FROM activities a
LEFT JOIN activity_grades ag ON a.id = ag.activity_id
WHERE a.teacher_id = ? AND a.period_id = ?
GROUP BY a.id
ORDER BY a.due_date DESC;
```

---

## TRIGGERS RECOMENDADOS

### 1. Actualizar contador de estudiantes en secciones
```sql
CREATE TRIGGER update_section_student_count
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW
-- Actualizar sections.current_students
```

### 2. Calcular grade_percentage en activity_grades
```sql
CREATE TRIGGER calculate_grade_percentage
BEFORE INSERT OR UPDATE ON activity_grades
FOR EACH ROW
-- NEW.grade_percentage = (NEW.points_earned / activity.max_points) * 100
```

### 3. Actualizar estado de actividad
```sql
CREATE TRIGGER update_activity_status
AFTER INSERT OR UPDATE ON activity_grades
FOR EACH ROW
-- Si todos los estudiantes están calificados, cambiar status a 'completed'
```

### 4. Auditoría de pagos
```sql
CREATE TRIGGER audit_payments
AFTER INSERT OR UPDATE OR DELETE ON payments
FOR EACH ROW
-- Insertar en audit_log con old_values y new_values
```

### 5. Actualizar student_account_status
```sql
CREATE TRIGGER update_student_balance
AFTER INSERT OR UPDATE ON payments
FOR EACH ROW
-- Recalcular total_paid y balance en student_account_status
```

---

## SECUENCIA DE IMPLEMENTACIÓN

### Fase 1: Estructura Base (Usuarios y Permisos)
1. roles
2. permissions
3. role_permissions
4. users
5. audit_log

### Fase 2: Estructura Académica
6. educational_levels
7. grades
8. sections
9. subjects
10. grade_subjects
11. teacher_assignments

### Fase 3: Estudiantes
12. students
13. parents
14. student_parents

### Fase 4: Evaluación
15. academic_periods
16. activities
17. activity_grades
18. period_grades

### Fase 5: Operaciones
19. attendance
20. payment_concepts
21. payments
22. student_account_status

---

## DATOS SEMILLA (SEED DATA)

### Roles
- Director, Secretaria, Docente

### Permisos base
- view_all, edit_all, delete_all, manage_users, manage_grades, manage_students, manage_payments, view_reports, view_students, edit_students, view_attendance, manage_activities

### Niveles educativos
- Preprimaria, Primaria, Secundaria

### Materias comunes
- Matemáticas, Español, Ciencias Naturales, Estudios Sociales, Inglés, Educación Física, Arte, Computación

### Conceptos de pago
- Colegiatura Mensual, Inscripción Anual, Materiales Escolares, Eventos Especiales, Seguro Estudiantil

### Usuario administrador inicial
- email: admin@colegio.edu
- role: Director
- Todos los permisos
