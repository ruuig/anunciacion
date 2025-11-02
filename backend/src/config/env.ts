import dotenv from "dotenv";

export function loadEnv() {
  dotenv.config();

  return {
    NODE_ENV: process.env.NODE_ENV ?? "development",
    PORT: process.env.PORT ? Number(process.env.PORT) : 3000,
    DATABASE_URL: process.env.DATABASE_URL,
    PGHOST: process.env.PGHOST,
    PGPORT: process.env.PGPORT ? Number(process.env.PGPORT) : 5432,
    PGUSER: process.env.PGUSER,
    PGPASSWORD: process.env.PGPASSWORD,
    PGDATABASE: process.env.PGDATABASE,
    PGSSLMODE: process.env.PGSSLMODE ?? "disable"
  };
}
