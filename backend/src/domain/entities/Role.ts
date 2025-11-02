export interface Role {
  id: number;
  name: string;
  description?: string | null;
  level: number;
  createdAt: Date;
}
