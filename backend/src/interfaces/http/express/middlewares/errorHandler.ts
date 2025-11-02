import { Request, Response, NextFunction } from "express";

export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  console.error(err);

  if (err?.message === "INVALID_CREDENTIALS") {
    return res.status(401).json({ error: "Usuario o contraseña incorrectos" });
  }

  return res.status(500).json({ error: "Internal server error" });
}
