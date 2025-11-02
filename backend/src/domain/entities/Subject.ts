export interface Subject {
  id: number;
  nombre: string;
  codigo?: string | null;
  descripcion?: string | null;
  activo: boolean;
  createdAt: Date;
}

export interface SubjectWithTeachers extends Subject {
  teachers: {
    id: number;
    nombre: string;
  }[];
}
