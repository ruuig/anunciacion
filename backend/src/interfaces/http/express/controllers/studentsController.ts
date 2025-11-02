import { Request, Response, NextFunction } from "express";
import { CreateStudent } from "../../../../application/use-cases/CreateStudent.js";
import { PostgresStudentRepository } from "../../../../infrastructure/repositories/PostgresStudentRepository.js";

const createStudentUseCase = new CreateStudent(new PostgresStudentRepository());

export async function createStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const student = await createStudentUseCase.execute(req.body);
    res.status(201).json(student);
  } catch (error) {
    next(error);
  }
}
