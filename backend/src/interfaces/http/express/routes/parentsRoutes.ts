import { Router } from "express";
import { 
  createParent, 
  listParents, 
  getParent, 
  updateParent, 
  deleteParent,
  assignStudent,
  removeStudent,
  getParentStudents,
  getStudentParents
} from "../controllers/parentsController";

const router = Router();

// CRUD básico de padres
router.get("/", listParents);
router.get("/:id", getParent);
router.post("/", createParent);
router.put("/:id", updateParent);
router.delete("/:id", deleteParent);

// Relaciones con estudiantes
router.post("/:id/students", assignStudent);  // Asignar estudiante a padre
router.delete("/:id/students/:studentId", removeStudent);  // Remover estudiante de padre
router.get("/:id/students", getParentStudents);  // Obtener estudiantes de un padre
router.get("/students/:studentId/parents", getStudentParents);  // Obtener padres de un estudiante

export default router;
