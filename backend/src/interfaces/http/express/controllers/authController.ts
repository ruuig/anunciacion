import { Request, Response, NextFunction } from "express";
import { AuthenticateUser } from "../../../../application/use-cases/AuthenticateUser";
import { PostgresUserRepository } from "../../../../infrastructure/repositories/PostgresUserRepository";

const authUseCase = new AuthenticateUser(new PostgresUserRepository());

export async function login(req: Request, res: Response, next: NextFunction) {
  try {
    const { username, password } = req.body;
    const user = await authUseCase.execute({ username, password });

    res.json({
      id: user.id,
      name: user.name,
      username: user.username,
      phone: user.phone,
      roleId: user.roleId,
      status: user.status,
      avatarUrl: user.avatarUrl,
      lastAccess: user.lastAccess
    });
  } catch (error) {
    next(error);
  }
}
