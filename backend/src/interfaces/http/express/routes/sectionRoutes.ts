import { Router } from "express";
import { listSectionsByGrade } from "../controllers/sectionsController.js";

const router = Router();

router.get("/grado/:gradeId", listSectionsByGrade);

export default router;
