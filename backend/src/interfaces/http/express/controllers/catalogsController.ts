import { Request, Response, NextFunction } from "express";
import { GetNiveles } from "../../../../application/use-cases/GetNiveles";
import { GetGrados } from "../../../../application/use-cases/GetGrados";
import { GetSeccionesByGrade } from "../../../../application/use-cases/GetSeccionesByGrade";
import { PostgresNivelesRepository } from "../../../../infrastructure/repositories/PostgresNivelesRepository";
import { PostgresGradosRepository } from "../../../../infrastructure/repositories/PostgresGradosRepository";
import { PostgresSeccionesRepository } from "../../../../infrastructure/repositories/PostgresSeccionesRepository";

const nivelesUC = new GetNiveles(new PostgresNivelesRepository());
const gradosUC = new GetGrados(new PostgresGradosRepository());
const seccionesUC = new GetSeccionesByGrade(new PostgresSeccionesRepository());

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
