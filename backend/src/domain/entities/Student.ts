export interface Student {
  id: number;
  codigo: string;  // Código único del estudiante
  dpi: string;     // DPI/CUI del estudiante
  name: string;
  birthDate: Date;
  gender?: string | null;
  address?: string | null;
  phone?: string | null;
  email?: string | null;
  avatarUrl?: string | null;
  gradeId: number;  // ID del grado que incluye la sección (ej: "Primero A")
  enrollmentDate: Date;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}
