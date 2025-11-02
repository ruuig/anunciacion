import { Router } from "express";
import { createEstudiante } from "../controllers/estudiantesController";

const router = Router();

router.post("/", createEstudiante);

export default router;
