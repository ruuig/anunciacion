import { Request, Response, NextFunction } from "express";

export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  console.error("❌ Error:", err);
  console.error("Stack:", err?.stack);

  if (err?.message === "INVALID_CREDENTIALS") {
    return res.status(401).json({ error: "Usuario o contraseña incorrectos" });
  }

  // En desarrollo, mostrar el error completo
  if (process.env.NODE_ENV === "development") {
    return res.status(500).json({ 
      error: "Internal server error",
      message: err?.message,
      details: err?.toString()
    });
  }

  return res.status(500).json({ error: "Internal server error" });
}
