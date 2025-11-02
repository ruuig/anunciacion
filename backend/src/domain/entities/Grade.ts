export interface Grade {
  id: number;
  name: string;
  educationalLevelId: number | null;
  ageRange?: string | null;
  academicYear: string;
  active: boolean;
  createdAt: Date;
  updatedAt: Date;
}
