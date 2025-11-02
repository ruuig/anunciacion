import { Request, Response, NextFunction } from "express";
import { CreateEstudiante } from "../../../../application/use-cases/CreateEstudiante";
import { UpdateEstudiante } from "../../../../application/use-cases/UpdateEstudiante";
import { PostgresEstudiantesRepository } from "../../../../infrastructure/repositories/PostgresEstudiantesRepository";

const repository = new PostgresEstudiantesRepository();
const createUC = new CreateEstudiante(repository);
const updateUC = new UpdateEstudiante(repository);

export async function createEstudiante(req: Request, res: Response, next: NextFunction) {
  try {
    const estudiante = await createUC.execute(req.body);
    res.status(201).json(estudiante);
  } catch (e) {
    next(e);
  }
}

export async function listEstudiantes(_req: Request, res: Response, next: NextFunction) {
  try {
    const estudiantes = await repository.findAll();
    res.json(estudiantes);
  } catch (e) {
    next(e);
  }
}

export async function getEstudiante(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    const estudiante = await repository.findById(id);
    if (!estudiante) {
      return res.status(404).json({ error: "Estudiante no encontrado" });
    }
    res.json(estudiante);
  } catch (e) {
    next(e);
  }
}

export async function updateEstudiante(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    const estudiante = await updateUC.execute(id, req.body);
    res.json(estudiante);
  } catch (e) {
    next(e);
  }
}

export async function deleteEstudiante(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    await repository.delete(id);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}
