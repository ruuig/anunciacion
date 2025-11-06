import { Router } from "express";
import { listGrades, assignTeacher, removeTeacher, getGradeTeachers, getTeacherGrades } from "../controllers/gradesController";

const router = Router();

router.get("/", listGrades);
router.get("/teacher/:teacherId", getTeacherGrades);
router.get("/:gradeId/teachers", getGradeTeachers);
router.post("/:gradeId/teachers", assignTeacher);
router.delete("/:gradeId/teachers/:teacherId", removeTeacher);

export default router;
