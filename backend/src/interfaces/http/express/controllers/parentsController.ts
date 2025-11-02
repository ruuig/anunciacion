import { Request, Response, NextFunction } from "express";
import { CreateParent } from "../../../../application/use-cases/CreateParent";
import { UpdateParent } from "../../../../application/use-cases/UpdateParent";
import { PostgresParentRepository } from "../../../../infrastructure/repositories/PostgresParentRepository";

const repository = new PostgresParentRepository();
const createUC = new CreateParent(repository);
const updateUC = new UpdateParent(repository);

export async function createParent(req: Request, res: Response, next: NextFunction) {
  try {
    const parent = await createUC.execute(req.body);
    res.status(201).json(parent);
  } catch (e) {
    next(e);
  }
}

export async function listParents(_req: Request, res: Response, next: NextFunction) {
  try {
    const parents = await repository.findAll();
    res.json(parents);
  } catch (e) {
    next(e);
  }
}

export async function getParent(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    const parent = await repository.findById(id);
    if (!parent) {
      return res.status(404).json({ error: "Padre no encontrado" });
    }
    res.json(parent);
  } catch (e) {
    next(e);
  }
}

export async function updateParent(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    const parent = await updateUC.execute(id, req.body);
    res.json(parent);
  } catch (e) {
    next(e);
  }
}

export async function deleteParent(req: Request, res: Response, next: NextFunction) {
  try {
    const id = parseInt(req.params.id);
    await repository.delete(id);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}

// Asignar estudiante a padre
export async function assignStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const parentId = parseInt(req.params.id);
    const { studentId, isPrimary, isEmergency } = req.body;
    
    const relation = await repository.assignStudent(parentId, studentId, isPrimary, isEmergency);
    res.status(201).json(relation);
  } catch (e) {
    next(e);
  }
}

// Remover estudiante de padre
export async function removeStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const parentId = parseInt(req.params.id);
    const studentId = parseInt(req.params.studentId);
    
    await repository.removeStudent(parentId, studentId);
    res.status(204).send();
  } catch (e) {
    next(e);
  }
}

// Obtener estudiantes de un padre
export async function getParentStudents(req: Request, res: Response, next: NextFunction) {
  try {
    const parentId = parseInt(req.params.id);
    const studentIds = await repository.getStudentsByParent(parentId);
    res.json(studentIds);
  } catch (e) {
    next(e);
  }
}

// Obtener padres de un estudiante
export async function getStudentParents(req: Request, res: Response, next: NextFunction) {
  try {
    const studentId = parseInt(req.params.studentId);
    const parents = await repository.getParentsByStudent(studentId);
    res.json(parents);
  } catch (e) {
    next(e);
  }
}
