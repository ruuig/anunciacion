import { Request, Response, NextFunction } from "express";
import { GetSectionsByGrade } from "../../../../application/use-cases/GetSectionsByGrade.js";
import { PostgresSectionRepository } from "../../../../infrastructure/repositories/PostgresSectionRepository.js";

const sectionsUseCase = new GetSectionsByGrade(new PostgresSectionRepository());

export async function listSectionsByGrade(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = Number(req.params.gradeId);
    const sections = await sectionsUseCase.execute(gradeId);
    res.json(sections);
  } catch (error) {
    next(error);
  }
}
