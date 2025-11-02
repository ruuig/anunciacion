import { Router } from "express";
import { getNiveles, getGrados, getSecciones } from "../controllers/catalogsController";

const router = Router();

router.get("/niveles", getNiveles);
router.get("/grados", getGrados);
router.get("/secciones/:gradeId", getSecciones);

export default router;
