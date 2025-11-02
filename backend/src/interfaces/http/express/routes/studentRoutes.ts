import { Router } from "express";
import { createStudent } from "../controllers/studentsController.js";

const router = Router();

router.post("/", createStudent);

export default router;
