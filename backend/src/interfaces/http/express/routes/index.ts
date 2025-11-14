import { Express } from "express";
import authRoutes from "./authRoutes";
import catalogsRoutes from "./catalogsRoutes";
import estudiantesRoutes from "./estudiantesRoutes";
import parentsRoutes from "./parentsRoutes";
import usersRoutes from "./usersRoutes";
import subjectsRoutes from "./subjectsRoutes";
import gradeRoutes from "./gradeRoutes";
import studentRoutes from "./studentRoutes";
import activitiesRoutes from "./activitiesRoutes";
import attendanceRoutes from "./attendanceRoutes";
import paymentRoutes from "./paymentRoutes";
import busServiceRoutes from "./busServiceRoutes";

export function registerRoutes(app: Express) {
  app.use("/api/auth", authRoutes);
  app.use("/api/catalogos", catalogsRoutes);
  app.use("/api/estudiantes", estudiantesRoutes);
  app.use("/api/padres", parentsRoutes);
  app.use("/users", usersRoutes);
  app.use("/api/materias", subjectsRoutes);
  app.use("/grades", gradeRoutes);
  app.use("/students", studentRoutes);
  app.use("/api/activities", activitiesRoutes);
  app.use("/api/attendance", attendanceRoutes);
  app.use("/api/pagos", paymentRoutes);
  app.use("/api/bus", busServiceRoutes);
}
