import { Router } from "express";
import * as subjectsController from "../controllers/subjectsController";

const router = Router();

// CRUD básico de materias
router.get("/", subjectsController.listSubjects);
router.get("/:id", subjectsController.getSubject);
router.post("/", subjectsController.createSubject);
router.put("/:id", subjectsController.updateSubject);
router.delete("/:id", subjectsController.deleteSubject);

// Gestión de docentes en materias
router.post("/:id/teachers", subjectsController.assignTeacher);
router.delete("/:id/teachers/:teacherId", subjectsController.removeTeacher);
router.get("/:id/teachers", subjectsController.getSubjectTeachers);

// Gestión de materias en grados
router.post("/assign-to-grade", subjectsController.assignToGrade);
router.get("/grade/:gradeId", subjectsController.getGradeSubjects);
router.get("/teacher/:teacherId", subjectsController.getTeacherSubjects);
router.delete("/grade/:gradeId/subject/:subjectId", subjectsController.removeSubjectFromGrade);

export default router;
