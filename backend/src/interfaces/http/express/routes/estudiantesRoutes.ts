import { Router } from "express";
import { createEstudiante, listEstudiantes, updateEstudiante, deleteEstudiante, getEstudiante } from "../controllers/estudiantesController";

const router = Router();

router.get("/", listEstudiantes);
router.get("/:id", getEstudiante);
router.post("/", createEstudiante);
router.put("/:id", updateEstudiante);
router.delete("/:id", deleteEstudiante);

export default router;
