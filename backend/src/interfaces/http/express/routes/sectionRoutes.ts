import { Router } from "express";
import { listSectionsByGrade } from "../controllers/sectionsController";

const router = Router();

router.get("/grado/:gradeId", listSectionsByGrade);

export default router;
