import { Request, Response, NextFunction } from "express";
import { CreateStudent } from "../../../../application/use-cases/CreateStudent";
import { PostgresStudentRepository } from "../../../../infrastructure/repositories/PostgresStudentRepository";

const studentRepository = new PostgresStudentRepository();
const createStudentUseCase = new CreateStudent(studentRepository);

export async function createStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const student = await createStudentUseCase.execute(req.body);
    res.status(201).json(student);
  } catch (error) {
    next(error);
  }
}

export async function getStudentsByGrade(req: Request, res: Response, next: NextFunction) {
  try {
    const gradeId = parseInt(req.query.gradeId as string);
    if (!gradeId) {
      // Si no hay gradeId, devolver todos los estudiantes
      const students = await studentRepository.findAll();
      return res.json(students);
    }
    const students = await studentRepository.findByGradeAndSection(gradeId);
    res.json(students);
  } catch (error) {
    next(error);
  }
}
