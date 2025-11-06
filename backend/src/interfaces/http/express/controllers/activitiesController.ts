import { Request, Response, NextFunction } from "express";
import { PostgresActivityRepository } from "../../../../infrastructure/repositories/PostgresActivityRepository";

const repository = new PostgresActivityRepository();

// ============================================
// ACTIVIDADES
// ============================================

export async function createActivity(req: Request, res: Response, next: NextFunction) {
  try {
    const activity = await repository.createActivity(req.body);
    console.log(`✅ Activity created: ${activity.nombre}`);
    res.status(201).json(activity);
  } catch (error) {
    console.error('❌ Error creating activity:', error);
    next(error);
  }
}

export async function getActivities(req: Request, res: Response, next: NextFunction) {
  try {
    const { materiaId, gradoId, periodo, anoAcademico, docenteId } = req.query;
    
    if (!materiaId || !gradoId || !periodo || !anoAcademico) {
      return res.status(400).json({ 
        error: "materiaId, gradoId, periodo y anoAcademico son requeridos" 
      });
    }

    const activities = await repository.getActivities({
      materiaId: parseInt(materiaId as string),
      gradoId: parseInt(gradoId as string),
      periodo: periodo as string,
      anoAcademico: parseInt(anoAcademico as string),
      docenteId: docenteId ? parseInt(docenteId as string) : undefined
    });

    console.log(`📚 Found ${activities.length} activities`);
    res.json(activities);
  } catch (error) {
    console.error('❌ Error getting activities:', error);
    next(error);
  }
}

export async function updateActivity(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    const activity = await repository.updateActivity(id, req.body);
    console.log(`✅ Activity updated: ${activity.nombre}`);
    res.json(activity);
  } catch (error) {
    console.error('❌ Error updating activity:', error);
    next(error);
  }
}

export async function deleteActivity(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    await repository.deleteActivity(id);
    console.log(`✅ Activity deleted: ${id}`);
    res.status(204).send();
  } catch (error) {
    console.error('❌ Error deleting activity:', error);
    next(error);
  }
}

// ============================================
// CALIFICACIONES DE ACTIVIDADES
// ============================================

export async function setActivityGrade(req: Request, res: Response, next: NextFunction) {
  try {
    const grade = await repository.setActivityGrade(req.body);
    console.log(`✅ Activity grade set: Student ${grade.estudianteId}, Activity ${grade.actividadId}, Grade ${grade.nota}`);
    res.json(grade);
  } catch (error) {
    console.error('❌ Error setting activity grade:', error);
    next(error);
  }
}

export async function getActivityGrades(req: Request, res: Response, next: NextFunction) {
  try {
    const actividadId = parseInt(req.params.actividadId);
    const grades = await repository.getActivityGrades(actividadId);
    console.log(`📊 Found ${grades.length} grades for activity ${actividadId}`);
    res.json(grades);
  } catch (error) {
    console.error('❌ Error getting activity grades:', error);
    next(error);
  }
}

export async function getStudentActivityGrades(req: Request, res: Response, next: NextFunction) {
  try {
    const estudianteId = parseInt(req.params.estudianteId);
    const { materiaId, gradoId, periodo, anoAcademico } = req.query;
    
    if (!materiaId || !gradoId || !periodo || !anoAcademico) {
      return res.status(400).json({ 
        error: "materiaId, gradoId, periodo y anoAcademico son requeridos" 
      });
    }

    const grades = await repository.getStudentActivityGrades(estudianteId, {
      materiaId: parseInt(materiaId as string),
      gradoId: parseInt(gradoId as string),
      periodo: periodo as string,
      anoAcademico: parseInt(anoAcademico as string)
    });

    res.json(grades);
  } catch (error) {
    console.error('❌ Error getting student activity grades:', error);
    next(error);
  }
}

// ============================================
// CALIFICACIONES FINALES
// ============================================

export async function setManualGrade(req: Request, res: Response, next: NextFunction) {
  try {
    const grade = await repository.setManualGrade(req.body);
    console.log(`✅ Manual grade set: Student ${grade.estudianteId}, Grade ${grade.notaFinal}`);
    res.json(grade);
  } catch (error) {
    console.error('❌ Error setting manual grade:', error);
    next(error);
  }
}

export async function getGrades(req: Request, res: Response, next: NextFunction) {
  try {
    const { materiaId, gradoId, periodo, anoAcademico } = req.query;
    
    if (!materiaId || !gradoId || !periodo || !anoAcademico) {
      return res.status(400).json({ 
        error: "materiaId, gradoId, periodo y anoAcademico son requeridos" 
      });
    }

    const grades = await repository.getGrades({
      materiaId: parseInt(materiaId as string),
      gradoId: parseInt(gradoId as string),
      periodo: periodo as string,
      anoAcademico: parseInt(anoAcademico as string)
    });

    console.log(`📊 Found ${grades.length} final grades`);
    res.json(grades);
  } catch (error) {
    console.error('❌ Error getting grades:', error);
    next(error);
  }
}

export async function getStudentGrade(req: Request, res: Response, next: NextFunction) {
  try {
    const estudianteId = parseInt(req.params.estudianteId);
    const { materiaId, gradoId, periodo, anoAcademico } = req.query;
    
    if (!materiaId || !gradoId || !periodo || !anoAcademico) {
      return res.status(400).json({ 
        error: "materiaId, gradoId, periodo y anoAcademico son requeridos" 
      });
    }

    const grade = await repository.getStudentGrade(
      estudianteId,
      parseInt(materiaId as string),
      parseInt(gradoId as string),
      periodo as string,
      parseInt(anoAcademico as string)
    );

    if (!grade) {
      return res.status(404).json({ error: "Grade not found" });
    }

    res.json(grade);
  } catch (error) {
    console.error('❌ Error getting student grade:', error);
    next(error);
  }
}
