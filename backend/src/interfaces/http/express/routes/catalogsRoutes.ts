import { Router } from "express";
import { 
  getNiveles, 
  getGrados, 
  getSecciones,
  createGrado,
  updateGrado,
  deleteGrado,
  createSeccion,
  updateSeccion,
  deleteSeccion
} from "../controllers/catalogsController";
import {
  assignTeacher,
  removeTeacher,
  getGradeTeachers
} from "../controllers/gradesController";

const router = Router();

// Niveles
router.get("/niveles", getNiveles);

// Grados
router.get("/grados", getGrados);
router.post("/grados", createGrado);
router.put("/grados/:id", updateGrado);
router.delete("/grados/:id", deleteGrado);

// Docentes en grados
router.post("/grados/:gradeId/teachers", assignTeacher);
router.delete("/grados/:gradeId/teachers/:teacherId", removeTeacher);
router.get("/grados/:gradeId/teachers", getGradeTeachers);

// Secciones
router.get("/secciones/:gradeId", getSecciones);
router.post("/secciones", createSeccion);
router.put("/secciones/:id", updateSeccion);
router.delete("/secciones/:id", deleteSeccion);

export default router;
