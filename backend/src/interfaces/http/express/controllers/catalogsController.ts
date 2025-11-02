import { Request, Response, NextFunction } from "express";
import { GetNiveles } from "../../../../application/use-cases/GetNiveles";
import { GetGrados } from "../../../../application/use-cases/GetGrados";
import { GetSeccionesByGrade } from "../../../../application/use-cases/GetSeccionesByGrade";
import { PostgresNivelesRepository } from "../../../../infrastructure/repositories/PostgresNivelesRepository";
import { PostgresGradosRepository } from "../../../../infrastructure/repositories/PostgresGradosRepository";
import { PostgresSeccionesRepository } from "../../../../infrastructure/repositories/PostgresSeccionesRepository";

const nivelesUC = new GetNiveles(new PostgresNivelesRepository());
const gradosRepository = new PostgresGradosRepository();
const gradosUC = new GetGrados(gradosRepository);
const seccionesRepository = new PostgresSeccionesRepository();
const seccionesUC = new GetSeccionesByGrade(seccionesRepository);

export async function getNiveles(_req: Request, res: Response, next: NextFunction) {
  try {
    const niveles = await nivelesUC.execute();
    res.json(niveles);
  } catch (e) {
    next(e);
  }
}

export async function getGrados(_req: Request, res: Response, next: NextFunction) {
  try {
    const grados = await gradosUC.execute();
    res.json(grados);
  } catch (e) {
    next(e);
  }
}

export async function getSecciones(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = Number(req.params.gradeId);
    const secciones = await seccionesUC.execute(gradeId);
    res.json(secciones);
  } catch (e) {
    next(e);
  }
}

// CREATE Grado
export async function createGrado(req: Request, res: Response, next: NextFunction) {
  try {
    const grado = await gradosRepository.create(req.body);
    res.status(201).json(grado);
  } catch (e) {
    next(e);
  }
}

// UPDATE Grado
export async function updateGrado(req: Request, res: Response, next: NextFunction) {
  try {
    const id = Number(req.params.id);
    const grado = await gradosRepository.update(id, req.body);
    res.json(grado);
  } catch (e) {
    next(e);
  }
}

// DELETE Grado
export async function deleteGrado(req: Request, res: Response, next: NextFunction) {
  try {
    const id = Number(req.params.id);
    await gradosRepository.delete(id);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}

// CREATE Seccion
export async function createSeccion(req: Request, res: Response, next: NextFunction) {
  try {
    const seccion = await seccionesRepository.create(req.body);
    res.status(201).json(seccion);
  } catch (e) {
    next(e);
  }
}

// UPDATE Seccion
export async function updateSeccion(req: Request, res: Response, next: NextFunction) {
  try {
    const id = Number(req.params.id);
    const seccion = await seccionesRepository.update(id, req.body);
    res.json(seccion);
  } catch (e) {
    next(e);
  }
}

// DELETE Seccion
export async function deleteSeccion(req: Request, res: Response, next: NextFunction) {
  try {
    const id = Number(req.params.id);
    await seccionesRepository.delete(id);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}
