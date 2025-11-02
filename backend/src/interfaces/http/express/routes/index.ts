import { Express } from "express";
import authRoutes from "./authRoutes";
import catalogsRoutes from "./catalogsRoutes";
import estudiantesRoutes from "./estudiantesRoutes";
import parentsRoutes from "./parentsRoutes";
import usersRoutes from "./usersRoutes";
import subjectsRoutes from "./subjectsRoutes";

export function registerRoutes(app: Express) {
  app.use("/api/auth", authRoutes);
  app.use("/api/catalogos", catalogsRoutes);
  app.use("/api/estudiantes", estudiantesRoutes);
  app.use("/api/padres", parentsRoutes);
  app.use("/users", usersRoutes);
  app.use("/api/materias", subjectsRoutes);
}
