import { Router } from "express";
import { login } from "../controllers/authController";
import { me } from "../controllers/authMeController";

const router = Router();

router.post("/login", login);
router.get("/me", me);

export default router;
