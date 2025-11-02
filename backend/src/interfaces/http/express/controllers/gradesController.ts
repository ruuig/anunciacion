import { Request, Response, NextFunction } from "express";
import { GetGrades } from "../../../../application/use-cases/GetGrades.js";
import { PostgresGradeRepository } from "../../../../infrastructure/repositories/PostgresGradeRepository.js";

const gradesUseCase = new GetGrades(new PostgresGradeRepository());

export async function listGrades(_req: Request, res: Response, next: NextFunction) {
  try {
    const grades = await gradesUseCase.execute();
    res.json(grades);
  } catch (error) {
    next(error);
  }
}
