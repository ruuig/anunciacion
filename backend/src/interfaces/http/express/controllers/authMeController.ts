import { Request, Response } from "express";
import { PostgresUserRepository } from "../../../../infrastructure/repositories/PostgresUserRepository";

const userRepo = new PostgresUserRepository();

export async function me(req: Request, res: Response) {
  const userId = Number(req.query.userId);
  if (!userId) {
    return res.status(400).json({ error: "userId requerido" });
  }

  const user = await userRepo.findById(userId);
  if (!user) {
    return res.status(404).json({ error: "Usuario no encontrado" });
  }

  res.json(user);
}
