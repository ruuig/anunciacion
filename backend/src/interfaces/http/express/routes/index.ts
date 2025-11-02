import { Express } from "express";
import authRoutes from "./authRoutes";
import catalogsRoutes from "./catalogsRoutes";
import estudiantesRoutes from "./estudiantesRoutes";
import usersRoutes from "./usersRoutes";

export function registerRoutes(app: Express) {
  app.use("/api/auth", authRoutes);
  app.use("/api/catalogos", catalogsRoutes);
  app.use("/api/estudiantes", estudiantesRoutes);
  app.use("/users", usersRoutes);
}
