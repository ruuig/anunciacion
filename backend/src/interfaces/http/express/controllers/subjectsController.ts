import { Request, Response, NextFunction } from "express";
import { PostgresSubjectRepository } from "../../../../infrastructure/repositories/PostgresSubjectRepository";

const repository = new PostgresSubjectRepository();

export async function listSubjects(_req: Request, res: Response, next: NextFunction) {
  try {
    const subjects = await repository.findAll();
    res.json(subjects);
  } catch (e) {
    next(e);
  }
}

export async function getSubject(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    const subject = await repository.findById(id);
    if (!subject) {
      return res.status(404).json({ error: "Materia no encontrada" });
    }
    res.json(subject);
  } catch (e) {
    next(e);
  }
}

export async function createSubject(req: Request, res: Response, next: NextFunction) {
  try {
    const subject = await repository.create(req.body);
    res.status(201).json(subject);
  } catch (e) {
    next(e);
  }
}

export async function updateSubject(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    const subject = await repository.update(id, req.body);
    res.json(subject);
  } catch (e) {
    next(e);
  }
}

export async function deleteSubject(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    await repository.delete(id);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}

// Asignar docente a materia
export async function assignTeacher(req: Request, res: Response, next: NextFunction) {
  try {
    const subjectId = parseInt(req.params.id);
    const { teacherId } = req.body;
    await repository.assignTeacher(subjectId, teacherId);
    res.status(201).json({ message: "Docente asignado exitosamente" });
  } catch (e) {
    next(e);
  }
}

// Remover docente de materia
export async function removeTeacher(req: Request, res: Response, next: NextFunction) {
  try {
    const subjectId = parseInt(req.params.id);
    const teacherId = parseInt(req.params.teacherId);
    await repository.removeTeacher(subjectId, teacherId);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}

// Obtener docentes de una materia
export async function getSubjectTeachers(req: Request, res: Response, next: NextFunction) {
  try {
    const subjectId = parseInt(req.params.id);
    const teachers = await repository.getTeachersBySubject(subjectId);
    res.json(teachers);
  } catch (e) {
    next(e);
  }
}

// Asignar materia y docente a un grado
export async function assignToGrade(req: Request, res: Response, next: NextFunction) {
  try {
    await repository.assignToGrade(req.body);
    res.status(201).json({ message: "Materia asignada al grado exitosamente" });
  } catch (e) {
    next(e);
  }
}

// Obtener materias de un grado
export async function getGradeSubjects(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = parseInt(req.params.gradeId);
    const anoAcademico = req.query.anoAcademico as string || new Date().getFullYear().toString();
    const subjects = await repository.getGradeSubjects(gradeId, anoAcademico);
    res.json(subjects);
  } catch (e) {
    next(e);
  }
}

// Remover materia de un grado
export async function removeSubjectFromGrade(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = parseInt(req.params.gradeId);
    const subjectId = parseInt(req.params.subjectId);
    const anoAcademico = req.query.anoAcademico as string || new Date().getFullYear().toString();
    await repository.removeFromGrade(gradeId, subjectId, anoAcademico);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}

export async function getTeacherSubjects(req: Request, res: Response, next: NextFunction) {
  try {
    const teacherId = parseInt(req.params.teacherId);
    
    console.log(`📚 Getting subjects for teacher ${teacherId}`);
    const subjects = await repository.getTeacherSubjects(teacherId);
    console.log(`✅ Found ${subjects.length} subjects`);
    res.json(subjects);
  } catch (e) {
    console.error('❌ Error getting teacher subjects:', e);
    next(e);
  }
}
