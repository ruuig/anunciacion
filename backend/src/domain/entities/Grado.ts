export interface Grado {
  id: number;
  name: string;
  educationalLevelId: number;
  ageRange?: string | null;
  academicYear: string;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}
