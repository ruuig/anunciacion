import { Router } from "express";
import { listGrades } from "../controllers/gradesController.js";

const router = Router();

router.get("/", listGrades);

export default router;
