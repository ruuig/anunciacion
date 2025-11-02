export interface Parent {
  id: number;
  dpi?: string | null;
  nombre: string;
  relacion: string;  // padre, madre, tutor, etc.
  telefono: string;
  telefonoSecundario?: string | null;
  email?: string | null;
  direccion?: string | null;
  ocupacion?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface ParentStudent {
  id: number;
  parentId: number;
  studentId: number;
  esContactoPrincipal: boolean;
  esContactoEmergencia: boolean;
  createdAt: Date;
}
