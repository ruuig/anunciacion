import { Request, Response, NextFunction } from "express";
import { GetGrades } from "../../../../application/use-cases/GetGrades";
import { PostgresGradeRepository } from "../../../../infrastructure/repositories/PostgresGradeRepository";

const gradesUseCase = new GetGrades(new PostgresGradeRepository());
const gradeRepository = new PostgresGradeRepository();

export async function listGrades(_req: Request, res: Response, next: NextFunction) {
  try {
    const grades = await gradesUseCase.execute();
    res.json(grades);
  } catch (error) {
    next(error);
  }
}

// Asignar docente a grado
export async function assignTeacher(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = parseInt(req.params.gradeId);
    const { teacherId, anoAcademico } = req.body;
    await gradeRepository.assignTeacher(gradeId, teacherId, anoAcademico);
    res.status(201).json({ message: "Docente asignado exitosamente" });
  } catch (error) {
    next(error);
  }
}

// Remover docente de grado
export async function removeTeacher(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = parseInt(req.params.gradeId);
    const teacherId = parseInt(req.params.teacherId);
    const anoAcademico = req.query.anoAcademico as string || new Date().getFullYear().toString();
    await gradeRepository.removeTeacher(gradeId, teacherId, anoAcademico);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
}

// Obtener docentes de un grado
export async function getGradeTeachers(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = parseInt(req.params.gradeId);
    const anoAcademico = req.query.anoAcademico ? parseInt(req.query.anoAcademico as string) : new Date().getFullYear();
    console.log(`Getting teachers for grade ${gradeId}, year ${anoAcademico}`);
    const teachers = await gradeRepository.getGradeTeachers(gradeId, anoAcademico);
    console.log(`Found ${teachers.length} teachers:`, teachers);
    res.json(teachers);
  } catch (error) {
    console.error('Error getting grade teachers:', error);
    next(error);
  }
}

// Obtener grados asignados a un docente
export async function getTeacherGrades(req: Request, res: Response, next: NextFunction) {
  try {
    const teacherId = parseInt(req.params.teacherId);
    const now = new Date();
    // El año académico es el año actual
    const anoAcademico = req.query.anoAcademico ? parseInt(req.query.anoAcademico as string) : now.getFullYear();
    console.log(`📚 Getting grades for teacher ${teacherId}, year ${anoAcademico}`);
    
    if (isNaN(teacherId)) {
      return res.status(400).json({ error: "Invalid teacherId" });
    }
    
    const grades = await gradeRepository.getTeacherGrades(teacherId, anoAcademico);
    console.log(`✅ Found ${grades.length} grades for teacher ${teacherId}`);
    
    if (grades.length === 0) {
      console.log(`⚠️ No grades assigned to teacher ${teacherId} for year ${anoAcademico}`);
    }
    
    res.json(grades);
  } catch (error) {
    console.error('❌ Error getting teacher grades:', error);
    console.error('Stack:', error instanceof Error ? error.stack : 'No stack trace');
    next(error);
  }
}
