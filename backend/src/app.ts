import express from "express";
import { registerRoutes } from "./interfaces/http/express/routes";
import { errorHandler } from "./interfaces/http/express/middlewares/errorHandler";

export function createApp() {
  const app = express();

  app.use(express.json());

  app.get("/", (_req, res) => {
    res.json({ ok: true, name: "school-backend", docs: "/api" });
  });

  registerRoutes(app);

  app.use(errorHandler);

  return app;
}
