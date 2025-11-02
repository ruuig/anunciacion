export interface Section {
  id: number;
  gradeId: number;
  name: string;
  capacity?: number | null;
  studentCount: number;
  active: boolean;
  createdAt: Date;
}
