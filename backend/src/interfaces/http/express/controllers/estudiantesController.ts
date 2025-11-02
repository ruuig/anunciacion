import { Request, Response, NextFunction } from "express";
import { CreateEstudiante } from "../../../../application/use-cases/CreateEstudiante";
import { PostgresEstudiantesRepository } from "../../../../infrastructure/repositories/PostgresEstudiantesRepository";

const createUC = new CreateEstudiante(new PostgresEstudiantesRepository());

export async function createEstudiante(req: Request, res: Response, next: NextFunction) {
  try {
    const estudiante = await createUC.execute(req.body);
    res.status(201).json(estudiante);
  } catch (e) {
    next(e);
  }
}
