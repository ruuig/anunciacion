import { Router } from "express";
import * as activitiesController from "../controllers/activitiesController";

const router = Router();

// ============================================
// RUTAS DE ACTIVIDADES
// ============================================
router.post("/", activitiesController.createActivity);
router.get("/", activitiesController.getActivities);
router.put("/:id", activitiesController.updateActivity);
router.delete("/:id", activitiesController.deleteActivity);

// ============================================
// RUTAS DE CALIFICACIONES DE ACTIVIDADES
// ============================================
router.post("/grades", activitiesController.setActivityGrade);
router.get("/:actividadId/grades", activitiesController.getActivityGrades);
router.get("/student/:estudianteId/grades", activitiesController.getStudentActivityGrades);

// ============================================
// RUTAS DE CALIFICACIONES FINALES
// ============================================
router.post("/final-grades", activitiesController.setManualGrade);
router.get("/final-grades", activitiesController.getGrades);
router.get("/student/:estudianteId/final-grade", activitiesController.getStudentGrade);

export default router;
