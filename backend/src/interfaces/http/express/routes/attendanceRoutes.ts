import { Router } from "express";
import { 
  registerEntry, 
  registerExit, 
  getTodayAttendance,
  getTodayStats
} from "../controllers/attendanceController";

const router = Router();

router.post("/entry", registerEntry);
router.post("/exit", registerExit);
router.get("/today", getTodayAttendance);
router.get("/stats", getTodayStats);

export default router;
