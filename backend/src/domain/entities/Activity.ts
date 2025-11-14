export interface Activity {
  id: number;
  nombre: string;
  descripcion?: string;
  materiaId: number;
  gradoId: number;
  docenteId: number;
  periodo: number;
  anoAcademico: number;
  ponderacion: number;
  fechaEntrega?: Date;
  fechaCreacion: Date;
  activo: boolean;
}

export interface ActivityGrade {
  id: number;
  actividadId: number;
  estudianteId: number;
  nota: number;
  observaciones?: string;
  fechaRegistro: Date;
  fechaActualizacion: Date;
}

export interface Grade {
  id: number;
  estudianteId: number;
  materiaId: number;
  gradoId: number;
  docenteId: number;
  periodo: number;
  notaFinal?: number;
  notaManual?: number;
  usarNotaManual: boolean;
  anoAcademico: number;
  observaciones?: string;
  fechaRegistro: Date;
  fechaActualizacion: Date;
}
