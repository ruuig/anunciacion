export interface User {
  id: number;
  name: string;
  username: string;
  password: string;
  phone?: string | null;
  roleId: number;
  status: string;
  avatarUrl?: string | null;
  lastAccess?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}
