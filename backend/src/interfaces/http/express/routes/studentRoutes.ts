import { Router } from "express";
import { createStudent, getStudentsByGrade } from "../controllers/studentsController";

const router = Router();

router.get("/", getStudentsByGrade);
router.post("/", createStudent);

export default router;
