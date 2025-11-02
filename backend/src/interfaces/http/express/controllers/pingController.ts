import { Request, Response } from "express";
import { pool } from "../../../../config/database";

export async function ping(req: Request, res: Response) {
  try {
    await pool.query("SELECT 1");
    res.json({ ok: true, db: "up" });
  } catch (e) {
    res.json({ ok: true, db: "down" });
  }
}
