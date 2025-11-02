export interface Estudiante {
  id: number;
  name: string;
  birthDate: Date;
  gender?: string | null;
  address?: string | null;
  phone?: string | null;
  email?: string | null;
  avatarUrl?: string | null;
  gradeId: number;
  sectionId: number;
  enrollmentDate: Date;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}
